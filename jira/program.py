"""This program demonstrates AutoKitteh's 2-way Jira integration.

This program implements multiple entry-point functions that
are triggered by incoming Jira events, as defined in the
"autokitteh-python.yaml" manifest file. These functions
also execute various Jira API calls.

API documentation:
- REST: https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/
- "Atlassian Python API" Python library: https://atlassian-python-api.readthedocs.io/
- "Jira" Python library: https://jira.readthedocs.io/

Python code samples:
- Atlassian Python API: https://github.com/atlassian-api/atlassian-python-api/tree/master/examples/jira
- Jira: https://github.com/pycontribs/jira/tree/main/examples

This program isn't meant to cover all available functions and events.
It merely showcases a few illustrative, annotated, reusable examples.
"""

from datetime import UTC, datetime
import os
import re

from atlassian import Jira


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


# TODO: Remove all code below this line, after merging
# https://github.com/autokitteh/autokitteh/pull/384


class ConnectionInitError(Exception):
    """A required AutoKitteh connection was not initialized yet."""

    def __init__(self, connection: str):
        super().__init__(f'AutoKitteh connection "{connection}" not initialized')


class EnvVarError(Exception):
    """A required environment variable is missing or invalid."""

    def __init__(self, env_var: str, desc: str):
        super().__init__(f'Environment variable "{env_var}" is {desc}')


def check_connection_name(connection: str) -> None:
    """Check that the given AutoKitteh connection name is valid.

    Args:
        connection: AutoKitteh connection name.

    Raises:
        ValueError: The connection name is invalid.
    """
    if not re.fullmatch(r"[A-Za-z_]\w*", connection):
        raise ValueError(f'Invalid AutoKitteh connection name: "{connection}"')


def atlassian_jira_client(connection: str, **kwargs):
    """Initialize an Atlassian Jira client, based on an AutoKitteh connection.

    API reference:
    https://atlassian-python-api.readthedocs.io/jira.html

    Code samples:
    https://github.com/atlassian-api/atlassian-python-api/tree/master/examples/jira

    Args:
        connection: AutoKitteh connection name.

    Returns:
        Atlassian-Python-API Jira client.

    Raises:
        ValueError: AutoKitteh connection name is invalid.
        RuntimeError: OAuth 2.0 access token expired.
        ConnectionInitError: AutoKitteh connection was not initialized yet.
        EnvVarError: Required environment variable is missing or invalid.
    """
    check_connection_name(connection)

    if os.getenv(connection + "__oauth_AccessToken"):
        return _atlassian_jira_client_cloud_oauth2(connection, **kwargs)

    base_url = os.getenv(connection + "__BaseURL")
    token = os.getenv(connection + "__Token")
    if token:
        email = os.getenv(connection + "__Email")
        if not email:
            return Jira(url=base_url, token=token, **kwargs)
        return Jira(
            url=base_url,
            username=email,
            password=token,
            cloud=True,
            **kwargs,
        )

    raise ConnectionInitError(connection)


def _atlassian_jira_client_cloud_oauth2(connection: str, **kwargs):
    """Initialize a Jira client for Atlassian Cloud using OAuth 2.0."""
    expiry = os.getenv(connection + "__oauth_Expiry")
    if not expiry:
        raise ConnectionInitError(connection)

    # Convert Go's time string (e.g. "2024-06-20 19:18:17 +0700 PDT") to
    # an ISO-8601 string that Python can parse with timezone awareness.
    timestamp = re.sub(r"[ A-Z]+.*", "", expiry)
    if datetime.fromisoformat(timestamp) < datetime.now(UTC):
        raise RuntimeError("OAuth 2.0 access token expired on: " + expiry)

    cloud_id = os.getenv(connection + "__access_id")
    if not cloud_id:
        raise ConnectionInitError(connection)

    client_id = os.getenv("JIRA_CLIENT_ID")
    if not client_id:
        raise EnvVarError("JIRA_CLIENT_ID", "missing")

    return Jira(
        url="https://api.atlassian.com/ex/jira/" + cloud_id,
        oauth2={
            "client_id": client_id,
            "token": {
                "access_token": os.getenv(connection + "__oauth_AccessToken"),
                "token_type": os.getenv(connection + "__oauth_TokenType"),
            },
        },
        **kwargs,
    )
