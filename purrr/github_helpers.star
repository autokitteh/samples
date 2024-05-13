"""GitHub API helper functions."""

load("@github", "github")

def create_review_comment(owner, repo, pr, body):
    """https://docs.github.com/en/rest/pulls/comments#create-a-review-comment-for-a-pull-request

    Create a review comment on a pull request. The caller
    doesn't need to specify the commit ID or the file path,
    this function selects them automatically.

    Args:
        owner: The owner of the repository.
        repo: The repository name.
        pr: The pull request number.
        body: The body of the comment.

    Returns:
        The response from the API.
    """
    pr = int(pr)
    resp = github.get_pull_request(owner, repo, pr)
    commit_id = resp.head.sha

    resp = github.list_pull_request_files(owner, repo, pr)
    # TODO: does this field contain the relative path, as required below?
    path = resp[0].filename  # TODO: Consider file's "sha" and/or "status" fields?
    print(resp)  # TODO: REMOVE THIS LINE

    return github.create_review_comment(owner, repo, pr, body, commit_id, path, subject_type = "file")
