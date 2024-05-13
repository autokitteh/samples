"""Handler for GitHub "pull_request_review_comment" events."""

load("debug.star", "debug")
load("markdown.star", "github_markdown_to_slack")
load("slack_helpers.star", "lookup_pr_channel", "mention_user_in_reply")

def on_github_pull_request_review_comment(data):
    """https://docs.github.com/webhooks/webhook-events-and-payloads#pull_request_review_comment

    A pull request review comment is a comment on a pull request's diff.

    For more information, see "Commenting on a pull request":
    https://docs.github.com/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/commenting-on-a-pull-request#adding-line-comments-to-a-pull-request

    Args:
        data: GitHub event data.
    """

    # Ignore this event if it was triggered by a bot.
    if data.sender.type == "Bot":
        return

    action_handlers = {
        "created": _on_pr_review_comment_created,
        "edited": _on_pr_review_comment_edited,
        "deleted": _on_pr_review_comment_deleted,
    }
    if data.action in action_handlers:
        action_handlers[data.action](data)
    else:
        debug("Unrecognized GitHub PR review comment action: `%s`" % data.action)

def _on_pr_review_comment_created(data):
    """A comment on a pull request diff was created.

    Args:
        data: GitHub event data.
    """
    pr_url = data.pull_request.htmlurl
    channel_id = lookup_pr_channel(pr_url, data.pull_request.state)
    if not channel_id:
        debug("Can't announce this review comment: " + data.comment.htmlurl)

    # TODO: Use "comment.created_at" to enforce chronological order?
    comment = data.comment
    review_id = comment.pull_request_review_id
    review_url = "%s#pullrequestreview-%d" % (pr_url, review_id)
    msg = "%%s created a <%s|%s comment> in the file `%s`:\n\n"
    msg %= (comment.htmlurl, comment.subject_type, comment.path)
    msg += github_markdown_to_slack(data.comment.body, pr_url)
    mention_user_in_reply(channel_id, review_url, data.sender, msg)

def _on_pr_review_comment_edited(data):
    """The content of a comment on a pull request diff was changed.

    TODO: Implement this.

    Args:
        data: GitHub event data.
    """
    print(data.changes)
    print(data.comment)
    print(data.sender)
    print(data.pull_request)

def _on_pr_review_comment_deleted(data):
    """A comment on a pull request diff was deleted.

    TODO: Implement this.

    Args:
        data: GitHub event data.
    """
    print(data.comment)
    print(data.sender)
    print(data.pull_request)
