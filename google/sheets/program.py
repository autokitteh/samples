"""This program demonstrates AutoKitteh's 2-way Google Sheets integration.

TODO: More details.

https://developers.google.com/sheets/api/quickstart/python
https://developers.google.com/resources/api-libraries/documentation/sheets/v4/python/latest/index.html
https://github.com/googleworkspace/python-samples/tree/main/sheets/snippets

"""

from datetime import UTC, datetime
import json
import os
import re
import traceback

import autokitteh
from google.auth.transport.requests import Request
import google.oauth2.credentials as credentials
import google.oauth2.service_account as service_account
from googleapiclient.discovery import build
import slack_sdk


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
        msg = f"Invalid Google Spreadsheet URL/ID: `{event.data.text}`"
        _slack_client().chat_postMessage(channel=event.data.user_id, text=msg)
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

    result = _sheets_client().values().get(spreadsheetId=id, range=a1_range).execute()
    values = result.get("values", [])
    if not values:
        print("No data found")

    print(values)


def _slack_client():
    ak_connection_name = "my_slack"
    token = os.getenv(ak_connection_name + "__oauth_AccessToken")
    if not token:
        raise RuntimeError('Connection "{ak_connection_name}" not initialized')

    # TODO: Also support Socket Mode as an optional configuration
    # (https://slack.dev/python-slack-sdk/api-docs/slack_sdk/socket_mode/).
    client = slack_sdk.WebClient(token)

    client.auth_test().validate()
    return client


def _sheets_client():
    """Initialize a Google Sheets API client.

    This function requires the name of an initialized AutoKitteh connection.
    It supports both connection modes: users (with OAuth v2),
    and GCP service accounts (with a JSON key).
    """
    ak_connection_name = "my_sheets"
    scopes = ["https://www.googleapis.com/auth/spreadsheets"]

    json_key = os.getenv(ak_connection_name + "__JSON")
    if json_key:
        return _sheets_client_with_json_key(json_key, scopes)

    refresh_token = os.getenv(ak_connection_name + "__oauth_RefreshToken")
    if refresh_token:
        return _sheets_client_with_oauth(ak_connection_name, refresh_token, scopes)

    raise RuntimeError(f'Connection "{ak_connection_name}" not initialized')


def _sheets_client_with_json_key(json_key, scopes):
    info = json.loads(json_key)
    return service_account.Credentials.from_service_account_info(info, scopes=scopes)


def _sheets_client_with_oauth(ak_connection_name, refresh_token, scopes):
    # Normalize the expiry timestamp to a format that Credentials can parse.
    expiry = os.getenv(ak_connection_name + "__oauth_Expiry").split(" ")
    dt = datetime.fromisoformat(f"{expiry[0]}T{expiry[1]}{expiry[2]}")
    expiry = dt.astimezone(UTC).replace(tzinfo=None).isoformat()

    creds = credentials.Credentials.from_authorized_user_info(
        {
            "token": os.getenv(ak_connection_name + "__oauth_AccessToken"),
            "refresh_token": refresh_token,
            "expiry": expiry,
            "client_id": os.getenv("GOOGLE_CLIENT_ID"),
            "client_secret": os.getenv("GOOGLE_CLIENT_SECRET"),
            "scopes": scopes,
        }
    )
    if creds.expired:
        creds.refresh(Request())

    return build("sheets", "v4", credentials=creds).spreadsheets()
