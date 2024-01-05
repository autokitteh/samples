"""This program demonstrates autokitteh's GitHub integration.

API details:
- GitHub REST API: https://docs.github.com/en/rest
- Go client library: https://pkg.go.dev/github.com/google/go-github/v57/github

This program implements various entry-point functions that are mapped to
trigger events from autokitteh connections in the file "autokitteh.yaml".

When the project has an active deployment, and autokitteh receives trigger
events from its connections, it starts runtime sessions which execute the
mapped entry-point functions.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load(
    "github",
    # https://docs.github.com/en/rest/reactions/reactions#create-reaction-for-an-issue-comment
    "create_reaction_for_issue_comment",
)
load(
    "rand",
    # https://pkg.go.dev/math/rand#Rand.Intn
    "intn",
)

REACTIONS = ["+1", "-1", "laugh", "confused", "heart", "hooray", "rocket", "eyes"]

def on_github_issue_comment(data):
    """https://docs.github.com/en/rest/overview/github-event-types#issuecommentevent

    Args:
        data: GitHub event data.
    """
    if data.action == "created":
        # Add to each new issue comment a random reaction.
        reaction = REACTIONS[intn(len(REACTIONS))]
        create_reaction_for_issue_comment(
            owner = data.organization.login,
            repo = data.repo.name,
            id = data.comment.id,
            content = reaction,
        )
