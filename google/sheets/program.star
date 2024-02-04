"""This program demonstrates autokitteh's Google Sheets integration.

This program implements a single entry-point function, which is
configured in the "autokitteh.yaml" manifest file as the receiver
of "slack_slash_command" events. Once triggered by a Slack user,
it reads and writes in a Google Sheet.

API details:
- Google Sheets REST API:
  https://developers.google.com/sheets/api/reference/rest
- Go client library:
  https://pkg.go.dev/google.golang.org/api/sheets/v4

In this sample, we expect the slash command's text to be either:
- A Google Spreadsheet ID
  (https://developers.google.com/sheets/api/guides/concepts)
- A full Google Spreadsheet URL
  (which we parse with a regular expression)

It also demonstrates using a custom builtin module
(re) to extract the Google Spreadsheet ID from a URL with a
regular expression (https://qri.io/docs/reference/starlark-packages/re).

When the project has an active deployment, and autokitteh receives
trigger events from its Slack connections, it starts runtime
sessions which execute these mapped entry-point functions.

This program isn't meant to cover all available functions and events,
it merely showcases a few illustrative and annotated examples.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load("@google", "google")
load("@slack", "slack")

def on_slack_slash_command(data):
    """https://api.slack.com/interactivity/slash-commands

    In this sample, we expect the slash command's text to be either:
    - A Google Spreadsheet ID
      (https://developers.google.com/sheets/api/guides/concepts)
    - A full Google Spreadsheet URL
      (which we parse with a regular expression)

    Args:
        data: Slack event data.
    """

    # FYI - Qri's "re" documentation:
    # https://qri.io/docs/reference/starlark-packages/re
    match = re.match(r"(.*/d/)?([^/]*)", data.text)
    if not match:
        msg = "Invalid Google Spreadsheet URL/ID: `%s`" % data.text
        slack.chat_post_message(data.user_id, msg)
        return

    # First match, second group.
    spreadsheet_id = match[0][2]
    _write_and_read_single_cell(spreadsheet_id, data.user_id)
    _write_and_read_cell_range(spreadsheet_id, data.user_id)
    _set_cell_range_formatting(spreadsheet_id)

def _write_and_read_single_cell(id, slack_channel):
    """Write and read a single cell in a Google Spreadsheet.

    This isn't a common use-case, but it's very simple, and
    especially suited for loop-based single-cell iterations
    because the functions accept 0-based indices.

    Also note that both read and write functions preserve
    the value type (e.g. strings, numbers).

    Args:
        id: Google Sheet ID, from its URL.
        slack_channel: Slack channel name/ID to post debug messages to.
    """

    # API documentation for writing data:
    # https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets.values/update
    google.sheets_write_cell(id, row_index = 0, col_index = 0, value = "s")
    value = google.sheets_read_cell(id, row_index = 0, col_index = 0)
    slack.chat_post_message(slack_channel, "Value at cell A1: `%s`" % value)

    # API documentation for reading data:
    # https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets.values/get
    google.sheets_write_cell(id, row_index = 0, col_index = 1, value = 1)
    value = google.sheets_read_cell(id, row_index = 0, col_index = 1)
    slack.chat_post_message(slack_channel, "Value at cell B1: `%s`" % value)

def _write_and_read_cell_range(id, slack_channel):
    """Write and read a range of cells in a Google Spreadsheet.

    Args:
        id: Google Sheet ID, from its URL.
        slack_channel: Slack channel name/ID to post debug messages to.
    """

    # FYI - explanation of the A1 notation for cell ranges:
    # https://developers.google.com/sheets/api/guides/concepts#expandable-1
    a1_range = "A1:B3"

    # Random kitteh image.
    url = "https://placekitten.com/500/100"

    data = [
        ["number", 123],  # Number
        ["string", "foo"],  # String
        ["image", '=IMAGE("%s")' % url],  # Formula
    ]

    # API documentation for writing data:
    # https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets.values/update
    google.sheets_write_range(id, a1_range, data)

    # API documentation for reading data:
    # https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets.values/get
    data = google.sheets_read_range(id, a1_range)
    for i, row in enumerate(data):
        if row[1] == "":
            # Workaround to read formulas.
            row[1] = google.sheets_read_cell(
                id,
                row_index = i,
                col_index = 1,
                value_render_option = "FORMULA",
            )
        msg = "Row %d: `%s` = `%s`" % (i + 1, row[0], row[1])
        slack.chat_post_message(slack_channel, msg)

def _set_cell_range_formatting(id):
    """Set formatting for a range of cells in a Google Spreadsheet.

    Args:
        id: Google Sheet ID, from its URL.
    """

    # API documentation for cell formatting:
    # https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets/cells#CellFormat

    # FYI - reference for color codes:
    # https://spreadsheet.dev/how-to-get-the-hexadecimal-codes-of-colors-in-google-sheets

    google.sheets_set_background_color(id, "A1:B1", 0xea4335)
    google.sheets_set_background_color(id, "A2:B2", 0x34a853)
    google.sheets_set_background_color(id, "A3:B3", 0x4285f4)

    google.sheets_set_text_format(id, "A1:B3", color = 0xffffff)
