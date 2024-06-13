"""TODO.."""

from datetime import UTC, datetime
import json
import os
import re

from atlassian import Jira
import autokitteh


def on_jira_comment_created(event):
    """TODO..."""
    data = json.loads(event.data.json)
    update_comment("my_jira", data)


@autokitteh.activity
def update_comment(ak_connection_name, data):
    """TODO..."""
    jira = _jira_client_cloud_oauth2(ak_connection_name)
    issue_key = data["issue"]["key"]
    comment = data["comment"]
    update = f"{comment['body']} - added by {comment['author']['displayName']}"
    jira.issue_edit_comment(issue_key, comment["id"], update)


def _jira_client_cloud_oauth2(ak_connection_name):
    """TODO."""
    if not re.fullmatch(r"[A-Za-z_]\w*", ak_connection_name):
        raise ValueError("Invalid AutoKitteh connection name: " + ak_connection_name)

    expiry = os.getenv(ak_connection_name + "__oauth_Expiry")
    iso8601 = re.sub(r"[ A-Z]+$", "", expiry)  # Convert from Go's time string.
    if datetime.fromisoformat(iso8601) < datetime.now(UTC):
        raise RuntimeError("OAuth 2.0 access token expired on: " + expiry)

    cloud_id = os.getenv(ak_connection_name + "__access_id")
    url = "https://api.atlassian.com/ex/jira/" + cloud_id
    return Jira(
        url=url,
        oauth2={
            "client_id": os.getenv("JIRA_CLIENT_ID"),
            "token": {
                "access_token": os.getenv(ak_connection_name + "__oauth_AccessToken"),
                "token_type": os.getenv(ak_connection_name + "__oauth_TokenType"),
            },
        },
    )
