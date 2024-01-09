"""This program demonstrates autokitteh's Google Sheets integration.

API details:
- Google Sheets REST API:
  https://developers.google.com/sheets/api/reference/rest
- Go client library documentation:
  https://pkg.go.dev/google.golang.org/api/sheets/v4

This program implements various entry-point functions that are mapped to
trigger events from autokitteh connections in the file "autokitteh.yaml".

When the project has an active deployment, and autokitteh receives trigger
events from its connections, it starts runtime sessions which execute the
mapped entry-point functions.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load(
    "google",
    # https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets.values/get
    "sheets_read_cell",
    "sheets_read_range",
    # https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets/cells#CellFormat
    "sheets_set_background_color",
    "sheets_set_text_format",
    # https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets.values/update
    "sheets_write_cell",
    "sheets_write_range",
)
load(
    "slack",
    # https://api.slack.com/methods/chat.postMessage
    "chat_post_message",
)

def on_slack_app_mention(data):
    """https://api.slack.com/events/app_mention"""

    # Convert data.text from "<@UserID> message" to "message".
    text = data.text.split(" ")[-1]
    read_and_write_google_sheet(text, data.channel)

def on_slack_slash_command(data):
    """https://api.slack.com/interactivity/slash-commands"""
    read_and_write_google_sheet(data.text, data.user_id)

def read_and_write_google_sheet(spreadsheet_id, slack_channel):
    """Read and write in a Google Sheet, based on the ID from its URL.

    Args:
        spreadsheet_id: Google Sheet ID, from its URL.
        slack_channel: Slack channel ID/name to post messages to.
    """
    sheets_write_cell(spreadsheet_id, row_index = 0, col_index = 0, value = "s")
    value = sheets_read_cell(spreadsheet_id, row_index = 0, col_index = 0)
    chat_post_message(slack_channel, "Value at cell A1: `%s`" % value)

    sheets_write_cell(spreadsheet_id, row_index = 0, col_index = 1, value = 1)
    value = sheets_read_cell(spreadsheet_id, row_index = 0, col_index = 1)
    chat_post_message(slack_channel, "Value at cell B1: `%s`" % value)

    # Explanation of the A1 notation for cell ranges:
    # https://developers.google.com/sheets/api/guides/concepts#expandable-1
    a1_range = "A1:B3"

    url = "https://static.wixstatic.com/media/1f200a_499442969cc34457a76b3d40755279e6~mv2.jpg"
    data = [
        ["number", 123],
        ["string", "foo"],
        ["image", '=IMAGE("%s")' % url],
    ]
    sheets_write_range(spreadsheet_id, a1_range, data)

    data = sheets_read_range(spreadsheet_id, a1_range)
    for i, row in enumerate(data):
        if row[1] == "":
            row[1] = sheets_read_cell(
                spreadsheet_id,
                row_index = i,
                col_index = 1,
                value_render_option = "FORMULA",
            )
        msg = "Row %d: `%s` = `%s`" % (i + 1, row[0], row[1])
        chat_post_message(slack_channel, msg)

    # https://spreadsheet.dev/how-to-get-the-hexadecimal-codes-of-colors-in-google-sheets
    sheets_set_background_color(spreadsheet_id, "A1:B1", 0xea4335)
    sheets_set_background_color(spreadsheet_id, "A2:B2", 0x34a853)
    sheets_set_background_color(spreadsheet_id, "A3:B3", 0x4285f4)

    sheets_set_text_format(spreadsheet_id, "A1:B3", color = 0xffffff)
