"""This program demonstrates AutoKitteh's 2-way Atlassian Jira integration.

This program implements multiple entry-point functions that are triggered
by incoming Jira events, as defined in the "autokitteh-python.yaml"
manifest file. These functions also execute various Jira API calls.

Jira API documentation:
- REST: https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/
- "Atlassian Python API" Python library: https://atlassian-python-api.readthedocs.io/
- "Jira" Python library: https://jira.readthedocs.io/

Python code samples:
- Atlassian Python API: https://github.com/atlassian-api/atlassian-python-api/tree/master/examples/jira
- Jira: https://github.com/pycontribs/jira/tree/main/examples

This program isn't meant to cover all available functions and events.
It merely showcases a few illustrative, annotated, reusable examples.
"""

from autokitteh.atlassian import atlassian_jira_client


AK_JIRA_CONNECTION = "my_jira"


def on_jira_issue_created(event):
    issue_key = event.data.issue.key
    user_name = event.data.user.displayName

    jira = atlassian_jira_client(AK_JIRA_CONNECTION)
    jira.issue_add_comment(issue_key, "This issue was created by " + user_name)


def on_jira_comment_created(event):
    issue_key = event.data.issue.key
    comment = event.data.comment

    jira = atlassian_jira_client(AK_JIRA_CONNECTION)
    suffix = "\n\nThis comment was added by " + comment.author.displayName
    jira.issue_edit_comment(issue_key, comment.id, comment.body + suffix)
