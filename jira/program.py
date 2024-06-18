"""TODO.."""

from datetime import UTC, datetime
import json
import os
import re

from atlassian import Jira
import autokitteh


AK_JIRA_CONNECTION = "my_jira"


def on_jira_comment_created(event):
    """TODO..."""
    data = json.loads(event.data.json)
    update_comment(data)


@autokitteh.activity
def update_comment(data):
    """TODO..."""
    jira = atlassian_jira_client(AK_JIRA_CONNECTION)
    issue_key = data["issue"]["key"]
    comment = data["comment"]
    update = f"{comment['body']} - added by {comment['author']['displayName']}"
    jira.issue_edit_comment(issue_key, comment["id"], update)


# TODO: Remove all code below this line, after merging
# https://github.com/autokitteh/autokitteh/pull/384


def atlassian_jira_client(connection: str, **kwargs):
    """Initialize a Jira client, based on an AutoKitteh connection.

    API reference:
    https://atlassian-python-api.readthedocs.io/jira.html

    Code samples:
    https://github.com/atlassian-api/atlassian-python-api/tree/master/examples/jira

    Args:
        connection: AutoKitteh connection name.

    Returns:
        Atlassian-Python-API Jira client.
    """
    if not re.fullmatch(r"[A-Za-z_]\w*", connection):
        raise ValueError(f'Invalid AutoKitteh connection name: "{connection}"')

    if os.getenv(connection + "__oauth_AccessToken"):
        return _atlassian_jira_client_cloud_oauth2(connection, **kwargs)

    base_url = os.getenv(connection + "__BaseURL")
    secret = os.getenv(connection + "__APIKeyOrPAT")
    if secret:
        email = os.getenv(connection + "__Email")
        if not email:
            return Jira(url=base_url, token=secret, **kwargs)
        return Jira(
            url=base_url,
            username=email,
            password=secret,
            cloud=True,
            **kwargs,
        )

    raise RuntimeError(f'AutoKitteh connection "{connection}" not initialized')


def _atlassian_jira_client_cloud_oauth2(connection: str, **kwargs):
    """Initialize a Jira client for Atlassian Cloud using OAuth 2.0."""
    expiry = os.getenv(connection + "__oauth_Expiry")
    if not expiry:
        raise RuntimeError(f'AutoKitteh connection "{connection}" not initialized')

    iso8601 = re.sub(r"[ A-Z]+$", "", expiry)  # Convert from Go's time string.
    if datetime.fromisoformat(iso8601) < datetime.now(UTC):
        raise RuntimeError("OAuth 2.0 access token expired on: " + expiry)

    cloud_id = os.getenv(connection + "__access_id")
    if not cloud_id:
        raise RuntimeError(f'AutoKitteh connection "{connection}" not initialized')

    client_id = os.getenv("JIRA_CLIENT_ID")
    if not client_id:
        raise RuntimeError('Environment variable "JIRA_CLIENT_ID" not set')

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
