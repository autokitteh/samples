"""GitHub API helper functions."""

load("@github", "github")
load("@redis", "redis")
load("debug.star", "debug")

def create_review_comment_reply(owner, repo, pr, body, channel_id, thread_ts):
    """https://docs.github.com/en/rest/pulls/comments#create-a-review-comment-for-a-pull-request

    Create a review comment, replying to an existing one.

    Args:
        owner: Owner of the GitHub repository.
        repo: GitHub repository name.
        pr: GitHub pull request number.
        body: Body of the comment, possibly with markdown.
        channel_id: ID of the Slack channel where the comment originated.
        thread_ts: ID (timestamp) of the Slack thread where the comment originated.

    Returns:
        The response from the API.
    """
    pr = int(pr)

    # See: https://redis.io/commands/get/
    gh_comment_id = redis.get("%s:%s" % (channel_id, thread_ts))
    if not gh_comment_id:
        debug("Couldn't find GitHub parent comment ID for Slack reply")
        return None

    return github.create_review_comment_reply(owner, repo, pr, int(gh_comment_id), body)
