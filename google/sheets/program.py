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

import re

import autokitteh
from autokitteh.google import google_sheets_client
from autokitteh.slack import slack_client


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
    resp = autokitteh.AttrDict(
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
