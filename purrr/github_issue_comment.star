"""Handler for GitHub "issue_comment" events."""

load("debug.star", "debug")

def on_github_issue_comment(data):
    """https://docs.github.com/webhooks/webhook-events-and-payloads#issue_comment

    This event occurs when there is activity relating to a comment on an issue
    or pull request.

    Args:
        data: GitHub event data.
    """

    # Ignore this event if it was triggered by a bot.
    if data.sender.type == "Bot":
        return

    action_handlers = {
        "created": _on_issue_comment_created,
        "edited": _on_issue_comment_edited,
        "deleted": _on_issue_comment_deleted,
    }
    if data.action in action_handlers:
        action_handlers[data.action](data)
    else:
        debug("Unrecognized GitHub issue comment action: `%s`" % data.action)

def _on_issue_comment_created(data):
    """A comment on an issue or pull request was created.

    TODO: Implement this.

    Args:
        data: GitHub event data.
    """
    print(data.issue)
    print(data.comment)
    print(data.sender)

def _on_issue_comment_edited(data):
    """A comment on an issue or pull request was edited.

    TODO: Implement this.

    Args:
        data: GitHub event data.
    """
    print(data.changes)
    print(data.issue)
    print(data.comment)
    print(data.sender)

def _on_issue_comment_deleted(data):
    """A comment on an issue or pull request was deleted.

    TODO: Implement this.

    Args:
        data: GitHub event data.
    """
    print(data.issue)
    print(data.comment)
    print(data.sender)
