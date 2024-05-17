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

    # Remember the Slack thread timestamp (message ID) of the GitHub comment we created.
    # Usage: syncing edits and deletes of review comments from GitHub to Slack.
    # See: https://redis.io/commands/set/
    redis_resp = redis.set(resp.htmlurl, thread_ts, REDIS_TTL)
    if redis_resp != "OK":
        debug('Redis "set %s %s" failed: %s' % (resp.htmlurl, thread_ts, redis_resp))

    # Also remember the GitHub comment ID, so we can reply to it later from Slack
    # (in create_review_comment_reply() below).
    # See: https://redis.io/commands/set/
    channel_ts = "review_comment:%s:%s" % (channel_id, thread_ts)
    redis_resp = redis.set(channel_ts, resp.id, REDIS_TTL)
    if redis_resp != "OK":
        debug('Redis "set %s %s" failed: %s' % (channel_ts, resp.htmlurl, redis_resp))

def create_review_comment_reply(owner, repo, pr, body, channel_id, thread_ts):
    """https://docs.github.com/en/rest/pulls/comments#create-a-reply-for-a-review-comment

    Create a review comment which is a reply to an existing review comment.
    If the replied-to Slack message isn't a review comment, create a PR comment.

    Args:
        owner: Owner of the GitHub repository.
        repo: GitHub repository name.
        pr: GitHub pull request number.
        body: Body of the comment, possibly with markdown.
        channel_id: ID of the Slack channel where the comment originated.
        thread_ts: ID (timestamp) of the Slack thread where the comment originated.
    """
    pr = int(pr)

    # Create a review comment which is a reply to an existing review comment.
    # This mapping is created by _on_pr_review_comment_created() in github_review_comment.star.
    # See: https://redis.io/commands/get/
    gh_review_comment = redis.get("review_comment:%s:%s" % (channel_id, thread_ts))
    if gh_review_comment:
        github.create_review_comment_reply(owner, repo, pr, int(gh_review_comment), body)
        return

    # If the Slack reply is to a different type of Slack message, create a PR comment.
    gh_issue_comment = redis.get("issue_comment:%s:%s" % (channel_id, thread_ts))
    gh_review = redis.get("review:%s:%s" % (channel_id, thread_ts))
    link = "to [this PR %s](%s) via"
    if gh_issue_comment:
        body = body.replace("via", link % ("comment", gh_issue_comment), 1)
    elif gh_review:
        body = body.replace("via", link % ("review", gh_review), 1)
    else:
        # Otherwise, this is a Slack reply to an unknown review comment.
        debug("Couldn't find GitHub comment ID to sync Slack reply")
        return

    # See: https://docs.github.com/en/rest/issues/comments#create-an-issue-comment
    github.create_issue_comment(owner, repo, pr, body)
