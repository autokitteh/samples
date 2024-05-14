"""Handler for GitHub "pull_request_review" events."""

load("@redis", "redis")
load("debug.star", "debug")
load("env", "REDIS_TTL")  # Set in "autokitteh.yaml".
load("markdown.star", "github_markdown_to_slack")
load("slack_helpers.star", "lookup_pr_channel", "mention_user_in_message")

def on_github_pull_request_review(data):
    """https://docs.github.com/webhooks/webhook-events-and-payloads#pull_request_review

    A pull request review is a group of pull request review
    comments in addition to a body comment and a state.

    For more information, see "About pull request reviews":
    https://docs.github.com/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews

    Args:
        data: GitHub event data.
    """

    # Ignore this event if it was triggered by a bot.
    if data.sender.type == "Bot":
        return

    action_handlers = {
        "submitted": _on_pr_review_submitted,
        "edited": _on_pr_review_edited,
        "dismissed": _on_pr_review_dismissed,
    }
    if data.action in action_handlers:
        action_handlers[data.action](data)
    else:
        debug("Unrecognized GitHub PR review action: `%s`" % data.action)

def _on_pr_review_submitted(data):
    """A review on a pull request was submitted.

    This is usually not interesting in itself, unless the review
    state is "approved", and/or the review body isn't empty.

    Args:
        data: GitHub event data.
    """
    pr_url = data.pull_request.htmlurl
    org = data.organization.login
    channel_id = lookup_pr_channel(pr_url, data.pull_request.state)
    if not channel_id:
        debug("Can't announce this PR review: " + data.review.htmlurl)
        return

    if data.review.state == "approved":
        msg = "%%s approved this PR :+1:"
        if data.review.body:
            msg += "\n\n" + github_markdown_to_slack(data.review.body, pr_url, org)
    elif data.review.body:
        msg = "%%s submitted a <%s|PR review>:\n\n" % data.review.htmlurl
        msg += github_markdown_to_slack(data.review.body, pr_url, org)
    else:
        return

    thread_ts = mention_user_in_message(channel_id, data.sender, msg, org)

    # Remember the thread timestamp (message ID) of the message we posted.
    if thread_ts:
        # See: https://redis.io/commands/set/
        resp = redis.set(data.review.htmlurl, thread_ts, REDIS_TTL)
        if resp != "OK":
            debug('Redis "set %s %s" failed: %s' % (data.review.htmlurl, thread_ts, resp))

def _on_pr_review_edited(data):
    """The body comment on a pull request review was edited.

    TODO: Implement this.

    Args:
        data: GitHub event data.
    """
    if not getattr(data, "changes", None):
        return

    print(data.changes)
    print(data.review)
    print(data.sender)
    print(data.pull_request)

def _on_pr_review_dismissed(data):
    """A review on a pull request was dismissed.

    TODO: Implement this.

    Args:
        data: GitHub event data.
    """
    print(data.review)
    print(data.sender)
    print(data.pull_request)
