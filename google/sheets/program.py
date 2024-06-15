"""This program demonstrates AutoKitteh's 2-way Google Sheets integration.

TODO: More details.
"""

from datetime import UTC, datetime
import json
import os
import re

import autokitteh
from google.auth.transport.requests import Request
import google.oauth2.credentials as credentials
import google.oauth2.service_account as service_account
from googleapiclient.discovery import build
import slack_sdk


AK_SHEETS_CONNECTION = "my_sheets"
AK_SLACK_CONNECTION = "my_slack"


def on_slack_slash_command(event):
    """https://api.slack.com/interactivity/slash-commands

    See also: https://api.slack.com/interactivity/handling#message_responses

    In this sample, we expect the slash command's text to be either:
    - A Google Spreadsheet ID
      (https://developers.google.com/sheets/api/guides/concepts)
    - A full Google Spreadsheet URL
      (which we parse with a regular expression)

    Args:
        event: Slack event data.
    """
    spreadsheet_id = _spreadsheet_id(event.data.text)
    if not spreadsheet_id:
        slack = slack_client(AK_SLACK_CONNECTION)
        msg = f"Invalid Google Spreadsheet URL/ID: `{event.data.text}`"
        slack.chat_postMessage(channel=event.data.user_id, text=msg)
        return

    # TODO(ENG-981): spreadsheet_id = match.group(2)

    _write_cells(spreadsheet_id)
    _read_cells(spreadsheet_id)

    # TODO: Align with Starark features?


# TODO(ENG-981): Remove this workaround.
@autokitteh.activity
def _spreadsheet_id(user_input):
    match = re.match(r"(.*/d/)?([\w-]{20,})", user_input)
    return match.group(2) if match else ""


@autokitteh.activity
def _write_cells(id):
    pass  # TODO: Implement this function.


@autokitteh.activity
def _read_cells(id):
    a1_range = "Sheet1!A1:B3"
    sheets = google_sheets_client(AK_SHEETS_CONNECTION)
    result = sheets.values().get(spreadsheetId=id, range=a1_range).execute()
    values = result.get("values", [])
    if not values:
        print("No data found")

    print(values)


# TODO: Remove all code below this line, after merging
# https://github.com/autokitteh/autokitteh/pull/384


def google_sheets_client(connection: str, **kwargs):
    """Initialize a Google Sheets client, based on an AutoKitteh connection.

    API reference:
    https://developers.google.com/resources/api-libraries/documentation/sheets/v4/python/latest/sheets_v4.spreadsheets.html

    Code samples:
    https://github.com/googleworkspace/python-samples/tree/main/sheets

    Args:
        connection: AutoKitteh connection name.

    Returns:
        Google Sheets client.
    """
    # https://developers.google.com/sheets/api/scopes
    default_scopes = ["https://www.googleapis.com/auth/spreadsheets"]
    creds = google_creds(connection, default_scopes, **kwargs)
    return build("sheets", "v4", credentials=creds, **kwargs)


def google_creds(connection: str, scopes: list[str], **kwargs):
    """Initialize credentials for a Google APIs client, for service discovery.

    This function supports both AutoKitteh connection modes:
    users (with OAuth 2.0), and GCP service accounts (with a JSON key).

    Code samples:
    https://github.com/googleworkspace/python-samples

    For subsequent usage details, see:
    https://googleapis.github.io/google-api-python-client/docs/epy/googleapiclient.discovery-module.html#build

    Args:
        connection: AutoKitteh connection name.
        scopes: List of OAuth permission scopes.

    Returns:
        Google API credentials, ready for usage
        in "googleapiclient.discovery.build()".
    """
    if not re.fullmatch(r"[A-Za-z_]\w*", connection):
        raise ValueError(f'Invalid AutoKitteh connection name: "{connection}"')

    json_key = os.getenv(connection + "__JSON")  # Service Account (JSON key)
    if json_key:
        info = json.loads(json_key)
        # https://google-auth.readthedocs.io/en/stable/reference/google.oauth2.service_account.html#google.oauth2.service_account.Credentials.from_service_account_info
        return service_account.Credentials.from_service_account_info(
            info, scopes=scopes, **kwargs
        )

    refresh_token = os.getenv(connection + "__oauth_RefreshToken")  # User (OAuth 2.0)
    if refresh_token:
        return _google_creds_oauth2(connection, refresh_token, scopes)

    raise RuntimeError(f'AutoKitteh connection "{connection}" not initialized')


def _google_creds_oauth2(connection: str, refresh_token: str, scopes: list[str]):
    """Initialize user credentials for Google APIs using OAuth 2.0.

    For more details, see:
    https://google-auth.readthedocs.io/en/stable/reference/google.oauth2.credentials.html#google.oauth2.credentials.Credentials.from_authorized_user_info

    Args:
        connection: AutoKitteh connection name.
        refresh_token: OAuth 2.0 refresh token.
        scopes: List of OAuth permission scopes.

    Returns:
        Google API credentials, ready for usage
        in "googleapiclient.discovery.build()".
    """
    expiry = os.getenv(connection + "__oauth_Expiry")
    iso8601 = re.sub(r"[ A-Z]+$", "", expiry)  # Convert from Go's time string.
    dt = datetime.fromisoformat(iso8601).astimezone(UTC)

    client_id = os.getenv("GOOGLE_CLIENT_ID")
    if not client_id:
        raise RuntimeError('Environment variable "GOOGLE_CLIENT_ID" not set')

    client_secret = os.getenv("GOOGLE_CLIENT_SECRET")
    if not client_id:
        raise RuntimeError('Environment variable "GOOGLE_CLIENT_SECRET" not set')

    creds = credentials.Credentials.from_authorized_user_info(
        {
            "token": os.getenv(connection + "__oauth_AccessToken"),
            "refresh_token": refresh_token,
            "expiry": dt.replace(tzinfo=None).isoformat(),
            "client_id": client_id,
            "client_secret": client_secret,
            "scopes": scopes,
        }
    )
    if creds.expired:
        creds.refresh(Request())

    return creds


def slack_client(connection: str, **kwargs):
    """Initialize a Slack client, based on an AutoKitteh connection.

    API reference:
    https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html

    This function doesn't initialize a Socket Mode client because the
    AutoKitteh connection already has one to receive incoming events.

    Args:
        connection: AutoKitteh connection name.

    Returns:
        Slack SDK client.
    """
    if not re.fullmatch(r"[A-Za-z_]\w*", connection):
        raise ValueError(f'Invalid AutoKitteh connection name: "{connection}"')

    bot_token = os.getenv(connection + "__oauth_AccessToken")  # OAuth v2
    if not bot_token:
        bot_token = os.getenv(connection + "__BotToken")  # Socket Mode
    if not bot_token:
        raise RuntimeError(f'AutoKitteh connection "{connection}" not initialized')

    client = slack_sdk.web.client.WebClient(bot_token, **kwargs)
    client.auth_test().validate()
    return client
