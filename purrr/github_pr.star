"""Handler for GitHub "pull_request" events."""

# TODO: Refactor all handlers to mention even if PR channel not found
# (to print to log channel at least - mention functions already implement this correctly).

load("@slack", "slack")
load("debug.star", "debug")
load("env", "REDIS_TTL")  # Set in "autokitteh.yaml".
load("markdown.star", "github_markdown_to_slack")
load(
    "slack_helpers.star",
    "add_users_to_channel",
    "archive_channel",
    "create_private_channel",
    "lookup_pr_channel",
    "mention_user_in_message",
    "normalize_channel_name",
    "rename_channel",
    "unarchive_channel",
)
load(
    "user_helpers.star",
    "github_pr_participants",
    "github_username_to_slack_user_id",
    "resolve_github_user",
)

_PR_CLOSE_DELAY = 5  # Seconds.

def on_github_pull_request(data):
    """https://docs.github.com/webhooks/webhook-events-and-payloads#pull_request

    For more information, see "About pull requests":
    https://docs.github.com/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests

    Args:
        data: GitHub event data.
    """
    action_handlers = {
        # A new pull request was created.
        "opened": _on_pr_opened,
        # A pull request was closed.
        "closed": _on_pr_closed,
        # A previously closed pull request was reopened.
        "reopened": _on_pr_reopened,

        # A pull request was converted to a draft.
        "converted_to_draft": _on_pr_converted_to_draft,
        # A draft pull request was marked as ready for review.
        "ready_for_review": _on_pr_ready_for_review,

        # Review by a person or team was requested for a pull request.
        "review_requested": _on_pr_review_requested,
        # A request for review by a person or team was removed from a pull request.
        "review_request_removed": _on_pr_review_request_removed,

        # A pull request was assigned to a user.
        "assigned": _on_pr_assigned,
        # A user was unassigned from a pull request.
        "unassigned": _on_pr_unassigned,

        # TODO: locked, unlocked

        # The title or body of a pull request was edited,
        # or the base branch of a pull request was changed.
        "edited": _on_pr_edited,
        # A pull request's head branch was updated.
        "synchronize": _on_pr_synchronized,
    }
    if data.action in action_handlers:
        action_handlers[data.action](data)

def _on_pr_opened(data):
    """A new pull request was created.

    Args:
        data: GitHub event data.
    """
    pr = data.pull_request

    # Create a dedicated private Slack channel for the PR.
    name = "%d_%s" % (pr.number, normalize_channel_name(pr.title))
    channel_id = create_private_channel(data, name)
    if not channel_id:
        user_id = github_username_to_slack_user_id(data.sender.login)
        msg = "Failed to create a Slack channel for %s" % pr.htmlurl
        slack.chat_post_message(user_id, msg)
        debug(msg)
        return

    # Post an introduction message to it, describing the PR (updated
    # later based on "pull_request" events with the "edited" action).
    msg = "%%s opened %s: `%s`" % (pr.htmlurl, pr.title)
    if pr.body:
        msg += "\n\n" + github_markdown_to_slack(pr.body, pr.htmlurl)
    mention_user_in_message(channel_id, data.sender, msg)

    # TODO: Also post a message summarizing check states (updated
    # later based on "worklfow_job" and "workflow_run" events).

    # Create channel bookmarks corresponding to important PR links
    # (titles should be updated based on relevant GitHub events).
    slack.bookmarks_add(channel_id, "Conversation (0)", pr.htmlurl)
    title = "Commits (%d)" % pr.commits
    slack.bookmarks_add(channel_id, title, pr.htmlurl + "/commits")
    slack.bookmarks_add(channel_id, "Checks (0)", pr.htmlurl + "/checks")
    title = "Files changed (%d)" % pr.changed_files
    slack.bookmarks_add(channel_id, title, pr.htmlurl + "/files")
    title = "Diffs (+%d -%d)" % (pr.additions, pr.deletions)
    slack.bookmarks_add(channel_id, title, pr.htmlurl + ".diff")

    # Remember the ID of the channel we just created, for other events.
    # See: https://redis.io/commands/set/
    resp = store.set(pr.htmlurl, channel_id, REDIS_TTL)
    if resp != "OK":
        debug('Redis "set %s %s" failed: %s' % (pr.htmlurl, channel_id, resp))

    # In case this is a replacement Slack channel, say so.
    msg = "Note: this is not a new PR, %%s %s now"
    if data.action == "reopened":
        msg %= "reopened it"
        mention_user_in_message(channel_id, data.sender, msg)
    elif data.action == "ready_for_review":
        msg %= "marked it as ready for review"
        mention_user_in_message(channel_id, data.sender, msg)

    # Finally, add all the participants in the PR to this channel.
    slack_user_ids = []
    for username in github_pr_participants(pr):
        user_id = github_username_to_slack_user_id(username)
        if user_id:
            slack_user_ids.append(user_id)
    add_users_to_channel(channel_id, ",".join(slack_user_ids))

def _on_pr_closed(data):
    """A pull request (possibly a draft) was closed.

    If "merged" is false in the webhook payload, the pull request was
    closed with unmerged commits. If "merged" is true in the webhook
    payload, the pull request was merged.

    Args:
        data: GitHub event data.
    """

    # Ignore drafts - they don't have an active Slack channel anyway.
    if data.pull_request.draft:
        return

    channel_id = lookup_pr_channel(data.pull_request.htmlurl, data.action)
    if not channel_id:
        return  # Unrecoverable error.

    # Wait for a few seconds to handle other asynchronous events
    # (e.g. a PR closure comment) before archiving the channel.
    sleep(_PR_CLOSE_DELAY)

    msg = "%s closed this PR"
    if data.pull_request.merged:
        msg = msg.replace("closed", "merged")
    mention_user_in_message(channel_id, data.sender, msg)

    archive_channel(channel_id, data)

def _on_pr_reopened(data):
    """A previously closed pull request (possibly a draft) was reopened.

    Args:
        data: GitHub event data.
    """

    # Ignore drafts - they don't have an active Slack channel anyway.
    if data.pull_request.draft:
        return

    channel_id = lookup_pr_channel(data.pull_request.htmlurl, data.action)
    if not channel_id:
        _on_pr_opened(data)  # Workaround: treat this as a new PR.
        return

    if not unarchive_channel(channel_id, data):
        _on_pr_opened(data)  # Workaround: treat this as a new PR.
        return

    # TODO: Update channel metadata, info messages, add missing participants.

    msg = "%s reopened this PR"
    mention_user_in_message(channel_id, data.sender, msg)

def _on_pr_converted_to_draft(data):
    """A pull request was converted to a draft.

    For more information, see "Changing the stage of a pull request":
    https://docs.github.com/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/changing-the-stage-of-a-pull-request

    Args:
        data: GitHub event data.
    """
    channel_id = lookup_pr_channel(data.pull_request.htmlurl, data.action)
    if not channel_id:
        return  # Unrecoverable error.

    msg = "%s converted this PR to a draft"
    mention_user_in_message(channel_id, data.sender, msg)

    archive_channel(channel_id, data)

def _on_pr_ready_for_review(data):
    """A draft pull request was marked as ready for review.

    For more information, see "Changing the stage of a pull request":
    https://docs.github.com/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/changing-the-stage-of-a-pull-request

    Args:
        data: GitHub event data.
    """
    channel_id = lookup_pr_channel(data.pull_request.htmlurl, data.action)
    if not channel_id:
        _on_pr_opened(data)  # Workaround: treat this as a new PR.
        return

    if not unarchive_channel(channel_id, data):
        _on_pr_opened(data)  # Workaround: treat this as a new PR.
        return

    # TODO: Update channel metadata, info messages, add missing participants.

    msg = "%s marked this PR as ready for review"
    mention_user_in_message(channel_id, data.sender, msg)

def _on_pr_review_requested(data):
    """Review by a person or team was requested for a pull request.

    For more information, see "Requesting a pull request review":
    https://docs.github.com/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/requesting-a-pull-request-review

    Args:
        data: GitHub event data.
    """

    # Don't do anything if there isn't an active Slack channel anyway.
    if data.pull_request.draft or data.pull_request.state != "open":
        return

    url = data.pull_request.htmlurl
    channel_id = lookup_pr_channel(url, data.action, wait = True)
    if not channel_id:
        return  # Unrecoverable error.

    if data.requested_reviewer:
        _on_pr_review_requested_person(data, channel_id)
    if data.requested_team:
        _on_pr_review_requested_team(data, channel_id)

def _on_pr_review_requested_person(data, channel_id):
    """Review by a person was requested for a pull request.

    Args:
        data: GitHub event data.
        channel_id: PR's Slack channel ID.
    """
    reviewer = resolve_github_user(data.requested_reviewer)
    msg = "%s requested a review from " + reviewer
    mention_user_in_message(channel_id, data.sender, msg)

    if not reviewer.startswith("<@"):
        return

    reviewer = reviewer[2:-1]  # Remove "<@" and ">" from Slack user ID.
    add_users_to_channel(channel_id, reviewer)

    # DM the reviewer with a reference to the Slack channel.
    msg = "%%s has requested you to review a PR - see <#%s>"
    mention_user_in_message(reviewer, data.sender, msg % channel_id)

def _on_pr_review_requested_team(data, channel_id):
    """Review by a team was requested for a pull request.

    Args:
        data: GitHub event data.
        channel_id: PR's Slack channel ID.
    """
    msg = "%%s requested a review from the <%s|%s> team"
    msg %= (data.requested_team.htmlurl, data.requested_team.name)
    mention_user_in_message(channel_id, data.sender, msg)

def _on_pr_review_request_removed(data):
    """A request for review by a person or team was removed from a pull request.

    Args:
        data: GitHub event data.
    """

    # Don't do anything if there isn't an active Slack channel anyway.
    if data.pull_request.draft or data.pull_request.state != "open":
        return

    channel_id = lookup_pr_channel(data.pull_request.htmlurl, data.action)
    if not channel_id:
        return  # Unrecoverable error.

    if data.requested_reviewer:
        _on_pr_review_request_removed_person(data, channel_id)
    if data.requested_team:
        _on_pr_review_request_removed_team(data, channel_id)

def _on_pr_review_request_removed_person(data, channel_id):
    """A request for review by a person was removed from a pull request.

    Args:
        data: GitHub event data.
        channel_id: PR's Slack channel ID.
    """
    reviewer = resolve_github_user(data.requested_reviewer)
    msg = "%s removed the request for review from " + reviewer
    mention_user_in_message(channel_id, data.sender, msg)

    if not reviewer.startswith("<@"):
        return

    # TODO: Remove the review request DM.
    reviewer = reviewer[2:-1]  # Remove "<@" and ">" from Slack user ID.
    # channel_id = find_dm_channel(user_id, "")
    # if channel_id == "":
    #     print('No Slack DM channel with GitHub user "%s"' % assignee.login)
    #     return
    # delete_messages_containing(channel_id, pr.htmlurl, "")
    # ("...has requested you to review a PR - see <#channel_id>")

def _on_pr_review_request_removed_team(data, channel_id):
    """A request for review by a team was removed from a pull request.

    Args:
        data: GitHub event data.
        channel_id: PR's Slack channel ID.
    """
    msg = "%%s removed the request for review from the <%s|%s> team"
    msg %= (data.requested_team.htmlurl, data.requested_team.name)
    mention_user_in_message(channel_id, data.sender, msg)

def _on_pr_assigned(data):
    """A pull request was assigned to a user.

    Args:
        data: GitHub event data.
    """

    # Don't do anything if there isn't an active Slack channel anyway.
    if data.pull_request.draft or data.pull_request.state != "open":
        return

    url = data.pull_request.htmlurl
    channel_id = lookup_pr_channel(url, data.action, wait = True)
    if not channel_id:
        return  # Unrecoverable error.

    assignee = resolve_github_user(data.assignee)
    self_assigned = assignee == resolve_github_user(data.sender)
    if self_assigned:
        msg = "%s assigned themselves to this PR"
    else:
        msg = "%%s assigned %s to this PR" % assignee
    mention_user_in_message(channel_id, data.sender, msg)

    if not assignee.startswith("<@"):
        return

    assignee = assignee[2:-1]  # Remove "<@" and ">" from Slack user ID.
    add_users_to_channel(channel_id, assignee)

    if self_assigned:
        return

    # DM the reviewer with a reference to the Slack channel.
    msg = "%%s has assigned you to a PR - see <#%s>"
    mention_user_in_message(assignee, data.sender, msg % channel_id)

def _on_pr_unassigned(data):
    """A user was unassigned from a pull request.

    Args:
        data: GitHub event data.
    """

    # Don't do anything if there isn't an active Slack channel anyway.
    if data.pull_request.draft or data.pull_request.state != "open":
        return

    channel_id = lookup_pr_channel(data.pull_request.htmlurl, data.action)
    if not channel_id:
        return  # Unrecoverable error.

    assignee = resolve_github_user(data.assignee)
    self_unassigned = assignee == resolve_github_user(data.sender)
    if self_unassigned:
        msg = "%s unassigned themselves from this PR"
    else:
        msg = "%%s unassigned %s from this PR" % assignee
    mention_user_in_message(channel_id, data.sender, msg)

    if not assignee.startswith("<@") or self_unassigned:
        return

    # TODO: Remove the assignment DM.
    assignee = assignee[2:-1]  # Remove "<@" and ">" from Slack user ID.
    # channel_id = find_dm_channel(user_id, "")
    # if channel_id == "":
    #     print('No Slack DM channel with GitHub user "%s"' % assignee.login)
    #     return
    # delete_messages_containing(channel_id, pr.htmlurl, "")
    # ("...has assigned you to a PR - see <#channel_id>")

def _on_pr_edited(data):
    """The title or body of a pull request was edited.

    Or the base branch of a pull request was changed.

    Args:
        data: GitHub event data.
    """

    # Don't do anything if there isn't an active Slack channel anyway.
    if data.pull_request.draft or data.pull_request.state != "open":
        return

    channel_id = lookup_pr_channel(data.pull_request.htmlurl, data.action)
    if not channel_id:
        return  # Unrecoverable error.

    # Update the first message if the PR description was changed.
    if data.changes.body:
        if data.pull_request.body:
            pass  # TODO: Update the first message.
        else:
            pass  # TODO: Same, but without a body.
        msg = "%s edited the PR description"
        mention_user_in_message(channel_id, data.sender, msg)

    # Rename the channel if the PR was renamed.
    if data.changes.title:
        pr = data.pull_request
        msg = "%%s edited the PR title to `%s`" % pr.title
        mention_user_in_message(channel_id, data.sender, msg)

        name = "%d_%s" % (pr.number, normalize_channel_name(pr.title))
        rename_channel(channel_id, name)

def _on_pr_synchronized(data):
    """A pull request's head branch was updated.

    For example, the head branch was updated from the base
    branch or new commits were pushed to the head branch.

    Args:
        data: GitHub event data.
    """

    # Don't do anything if there isn't an active Slack channel anyway.
    if data.pull_request.draft or data.pull_request.state != "open":
        return

    channel_id = lookup_pr_channel(data.pull_request.htmlurl, data.action)
    if not channel_id:
        return  # Unrecoverable error.

    msg = "%s updated the PR's head branch"
    mention_user_in_message(channel_id, data.sender, msg)

    # TODO: Update channel bookmark titles.
    pr = data.pull_request

    bookmark_id = "TODO"
    title = "Conversation (%d)" % (pr.comments + pr.review_comments)
    slack.bookmarks_edit(bookmark_id, channel_id, title = title)

    bookmark_id = "TODO"
    title = "Commits (%d)" % pr.commits
    slack.bookmarks_edit(bookmark_id, channel_id, title = title)

    bookmark_id = "TODO"
    title = "Files changed (%d)" % pr.changed_files
    slack.bookmarks_edit(bookmark_id, channel_id, title = title)

    bookmark_id = "TODO"
    title = "Diffs (+%d -%d)" % (pr.additions, pr.deletions)
    slack.bookmarks_edit(bookmark_id, channel_id, title = title)
