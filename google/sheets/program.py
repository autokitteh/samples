"""This program demonstrates AutoKitteh's 2-way Google Sheets integration.

This program implements an entry-point function that is triggered by incoming
Slack events, as defined in the "autokitteh-python.yaml" manifest file.
This function executes various read and write Google Sheets API calls.

Google Sheets API documentation:
- REST API reference: https://developers.google.com/sheets/api/reference/rest
- Python client API: https://developers.google.com/resources/api-libraries/documentation/sheets/v4/python/latest/sheets_v4.spreadsheets.html

Python code samples:
https://github.com/googleworkspace/python-samples/tree/main/sheets
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
from slack_sdk.web.client import WebClient


AK_SHEETS_CONNECTION = "my_sheets"
AK_SLACK_CONNECTION = "my_slack"


def on_slack_slash_command(event):
    """https://api.slack.com/interactivity/slash-commands

    See also: https://api.slack.com/interactivity/handling#message_responses

    In this sample, we expect the slash command's text to be either:
    - A Google Spreadsheet ID (https://developers.google.com/sheets/api/guides/concepts)
    - A full Google Spreadsheet URL (which we parse with a regular expression)

    Args:
        event: Slack event data.
    """
    # Extract the Google Spreadsheet ID from the user's input.
    # TODO(ENG-1056): Remove this workaround when fixed.
    # match = re.match(r"(.*/d/)?([\w-]{20,})", event.data.text)
    match = _spreadsheet_id(event.data.text)
    if not match:
        slack = slack_client(AK_SLACK_CONNECTION)
        msg = f"Invalid Google Spreadsheet URL/ID: `{event.data.text}`"
        slack.chat_postMessage(channel=event.data.user_id, text=msg)
        return

    spreadsheet_id = match  # .group(2)  # TODO(ENG-1056): Uncomment.
    _write_values(spreadsheet_id, event.data.user_id)
    _read_values(spreadsheet_id, event.data.user_id)
    _read_formula(spreadsheet_id, event.data.user_id)


# TODO(ENG-1056): Delete this entire function.
@autokitteh.activity
def _spreadsheet_id(user_input):
    match = re.match(r"(.*/d/)?([\w-]{20,})", user_input)
    return match.group(2) if match else None


@autokitteh.activity
def _write_values(spreadsheet_id, slack_target):
    """Write multiple cell values, with different data types."""
    sheets = google_sheets_client(AK_SHEETS_CONNECTION).spreadsheets().values()
    resp = AttrDict(
        sheets.update(
            spreadsheetId=spreadsheet_id,
            # Explanation of the A1 notation for cell ranges:
            # https://developers.google.com/sheets/api/guides/concepts#expandable-1
            range="Sheet1!A1:B7",
            # Value input options:
            # https://developers.google.com/sheets/api/reference/rest/v4/ValueInputOption
            valueInputOption="USER_ENTERED",
            body={
                "values": [
                    ["String", "Hello, world!"],
                    ["Number", -123.45],
                    ["Also number", "-123.45"],
                    ["Percent", "10.12%"],
                    ["Boolean", True],
                    ["Date", "2022-12-31"],
                    ["Formula", "=B2*B3"],
                ]
            },
        ).execute()
    )

    slack = slack_client(AK_SLACK_CONNECTION)
    text = f"Updated: range `{resp.updatedRange!r}`, `{resp.updatedRows}` rows, "
    text += f"`{resp.updatedColumns}` columns, `{resp.updatedCells}` cells"
    slack.chat_postMessage(channel=slack_target, text=text)


@autokitteh.activity
def _read_values(id, slack_target):
    """Read multiple cell values from a Google Spreadsheet.

    Value render options:
    https://developers.google.com/sheets/api/reference/rest/v4/ValueRenderOption
    """
    sheets = google_sheets_client(AK_SHEETS_CONNECTION).spreadsheets().values()
    slack = slack_client(AK_SLACK_CONNECTION)

    # Default value render option: "FORMATTED_VALUE".
    resp = sheets.get(spreadsheetId=id, range="A1:B6").execute()
    formatted_values = resp.get("values")

    if not formatted_values:
        slack.chat_postMessage(channel=slack_target, text="Error: no data found!")
        return

    ufv = "UNFORMATTED_VALUE"
    resp = sheets.get(spreadsheetId=id, range="A1:B6", valueRenderOption=ufv).execute()
    unformatted_values = resp.get("values")

    for i, row in enumerate(formatted_values):
        what, formatted = row
        unformatted = unformatted_values[i][1]
        text = f"Row {i+1}: {what} = `{formatted!r}` (unformatted: `{unformatted!r}`)"
        slack.chat_postMessage(channel=slack_target, text=text)


@autokitteh.activity
def _read_formula(id, slack_target):
    """Read a single cell value with a formula, and its evaluated result.

    Value render options:
    https://developers.google.com/sheets/api/reference/rest/v4/ValueRenderOption
    """
    sheets = google_sheets_client(AK_SHEETS_CONNECTION).spreadsheets().values()
    slack = slack_client(AK_SLACK_CONNECTION)
    range = "B7"

    f = "FORMULA"
    resp = sheets.get(spreadsheetId=id, range=range, valueRenderOption=f).execute()
    values = resp.get("values")

    if not values:
        slack.chat_postMessage(channel=slack_target, text="Error: no data found!")
        return

    slack.chat_postMessage(channel=slack_target, text=f"Formula: `{values[0][0]!r}`")

    # Default value render option: "FORMATTED_VALUE".
    resp = sheets.get(spreadsheetId=id, range=range).execute()
    value = resp["values"][0][0]
    slack.chat_postMessage(channel=slack_target, text=f"Formatted: `{value!r}`")

    ufv = "UNFORMATTED_VALUE"
    resp = sheets.get(spreadsheetId=id, range=range, valueRenderOption=ufv).execute()
    value = resp["values"][0][0]
    slack.chat_postMessage(channel=slack_target, text=f"Unformatted: `{value!r}`")


# TODO: Remove all code below this line, after merging
# https://github.com/autokitteh/autokitteh/pull/384


class AttrDict(dict):
    """Allow attribute access to dictionary keys.

    >>> config = AttrDict({'server': {'port': 8080}, 'debug': True})
    >>> config.server.port
    8080
    >>> config.debug
    True
    """

    def __getattr__(self, name: str):
        try:
            value = self[name]
            if isinstance(value, dict):
                value = AttrDict(value)
            return value
        except KeyError:
            raise AttributeError(name)

    def __setattr__(self, name: str, value):
        # The default __getattr__ doesn't fail but also don't change values.
        cls = self.__class__.__name__
        raise NotImplementedError(f"{cls} does not support setting attributes")


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

    Raises:
        ValueError: AutoKitteh connection name is invalid.
        ConnectionInitError: AutoKitteh connection was not initialized yet.
        EnvVarError: Required environment variable is missing or invalid.
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

    Raises:
        ValueError: AutoKitteh connection name is invalid.
        ConnectionInitError: AutoKitteh connection was not initialized yet.
        EnvVarError: Required environment variable is missing or invalid.
    """
    check_connection_name(connection)

    json_key = os.getenv(connection + "__JSON")  # Service Account (JSON key)
    if json_key:
        info = json.loads(json_key)
        # https://google-auth.readthedocs.io/en/stable/reference/google.oauth2.service_account.html#google.oauth2.service_account.Credentials.from_service_account_info
        return service_account.Credentials.from_service_account_info(
            info, scopes=scopes, **kwargs
        )

    refresh_token = os.getenv(connection + "__oauth_RefreshToken")  # User (OAuth 2.0)
    if refresh_token:
        return __google_creds_oauth2(connection, refresh_token, scopes)

    raise ConnectionInitError(connection)


def __google_creds_oauth2(connection: str, refresh_token: str, scopes: list[str]):
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

    Raises:
        ConnectionInitError: AutoKitteh connection was not initialized yet.
        EnvVarError: Required environment variable is missing or invalid.
    """
    expiry = os.getenv(connection + "__oauth_Expiry")
    if not expiry:
        raise ConnectionInitError(connection)

    # Convert Go's time string (e.g. "2024-06-20 19:18:17 +0700 PDT") to
    # an ISO-8601 string that Python can parse with timezone awareness.
    timestamp = re.sub(r"[ A-Z]+.*", "", expiry)
    dt = datetime.fromisoformat(timestamp).astimezone(UTC)

    client_id = os.getenv("GOOGLE_CLIENT_ID")
    if not client_id:
        raise EnvVarError("GOOGLE_CLIENT_ID", "missing")

    client_secret = os.getenv("GOOGLE_CLIENT_SECRET")
    if not client_id:
        raise EnvVarError("GOOGLE_CLIENT_SECRET", "missing")

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


def slack_client(connection: str, **kwargs) -> WebClient:
    """Initialize a Slack client, based on an AutoKitteh connection.

    API reference:
    https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html

    This function doesn't initialize a Socket Mode client because the
    AutoKitteh connection already has one to receive incoming events.

    Args:
        connection: AutoKitteh connection name.

    Returns:
        Slack SDK client.

    Raises:
        ValueError: AutoKitteh connection name is invalid.
        ConnectionInitError: AutoKitteh connection was not initialized yet.
        SlackApiError: Connection attempt failed, or connection is unauthorized.
    """
    check_connection_name(connection)

    bot_token = os.getenv(connection + "__oauth_AccessToken")  # OAuth v2
    if not bot_token:
        bot_token = os.getenv(connection + "__BotToken")  # Socket Mode
    if not bot_token:
        raise ConnectionInitError(connection)

    client = WebClient(bot_token, **kwargs)
    client.auth_test().validate()
    return client
