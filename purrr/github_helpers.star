"""GitHub API helper functions."""

load("@github", "github")
load("@redis", "redis")
load("debug.star", "debug")
load("env", "REDIS_TTL")  # Set in "autokitteh.yaml".

def create_review_comment(owner, repo, pr, review, comment, channel_id, thread_ts):
    """Create a review on a pull request, with a single comment.

    No need to specify the commit ID or file path - we set them automatically.

    Args:
        owner: Owner of the GitHub repository.
        repo: GitHub repository name.
        pr: GitHub pull request number.
        review: Body of the PR review, possibly with markdown.
        comment: Body of the review comment, possibly with markdown.
        channel_id: ID of the Slack channel where the comment originated.
        thread_ts: ID (timestamp) of the Slack thread where the comment originated.

    Returns:
        The response from the API.
    """
    pr = int(pr)

    # See: https://docs.github.com/en/rest/pulls/reviews?#create-a-review-for-a-pull-request
    github.create_review(owner, repo, pr, body = review, event = "COMMENT")

    # See: https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request
    resp = github.get_pull_request(owner, repo, pr)
    commit_id = resp.head.sha

    # See: https://docs.github.com/en/rest/pulls/pulls#list-pull-requests-files
    # TODO: Select a file based on its "sha" and/or "status" fields, instead of [0]?
    resp = github.list_pull_request_files(owner, repo, pr)
    path = resp[0].filename

    # See: https://docs.github.com/en/rest/pulls/comments#create-a-review-comment-for-a-pull-request
    resp = github.create_review_comment(owner, repo, pr, comment, commit_id, path, subject_type = "file")

    # Remember the Slack thread timestamp (message ID) of the message we posted.
    # See: https://redis.io/commands/set/
    redis_resp = redis.set(resp.htmlurl, thread_ts, REDIS_TTL)
    if redis_resp != "OK":
        debug('Redis "set %s %s" failed: %s' % (resp.htmlurl, thread_ts, resp))

    # Also remember the GitHub comment ID, so we can reply to it later from Slack.
    # See: https://redis.io/commands/set/
    channel_ts = "%s:%s" % (channel_id, thread_ts)
    redis_resp = redis.set(channel_ts, resp.id, REDIS_TTL)
    if redis_resp != "OK":
        debug('Redis "set %s %s" failed: %s' % (channel_ts, resp.id, resp))

    return resp

def create_review_comment_reply(owner, repo, pr, body, channel_id, thread_ts):
    """https://docs.github.com/en/rest/pulls/comments#create-a-reply-for-a-review-comment

    Create a review comment which is a reply to an existing review comment.

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
        debug("Couldn't find GitHub comment ID to sync Slack reply")
        return None

    return github.create_review_comment_reply(owner, repo, pr, int(gh_comment_id), body)
