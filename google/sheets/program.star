"""This program demonstrates AutoKitteh's 2-way Google Sheets integration.

This program implements an entry-point function that is triggered by incoming
Slack events, as defined in the "autokitteh-starlark.yaml" manifest file.
This function executes various read and write Google Sheets API calls.

Google Sheets API documentation:
- REST API reference: https://developers.google.com/sheets/api/reference/rest
- Go client API: https://pkg.go.dev/google.golang.org/api/sheets/v4

This program also demonstrates using a custom built-in module (re) to
extract the Google Spreadsheet ID from a URL with a regular expression
(https://github.com/qri-io/starlib/tree/master/re).

Starlark is a dialect of Python (see https://bazel.build/rules/language).
Comapre this file with "program.py" - same logic, but using Python.
"""

load("@googlesheets", "my_sheets")
load("@slack", "my_slack")

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

    # FYI - Qri's "re" implementation: https://github.com/qri-io/starlib/tree/master/re
    match = re.match(r"(.*/d/)?([\w-]{20,})", data.text)
    if not match:
        msg = "Invalid Google Spreadsheet URL/ID: `%s`" % data.text
        my_slack.chat_post_message(data.user_id, msg)
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
    my_sheets.write_cell(id, row_index = 0, col_index = 0, value = "s")
    value = my_sheets.read_cell(id, row_index = 0, col_index = 0)
    my_slack.chat_post_message(slack_channel, "Value at cell A1: `%s`" % value)

    # API documentation for reading data:
    # https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets.values/get
    my_sheets.write_cell(id, row_index = 0, col_index = 1, value = 1)
    value = my_sheets.read_cell(id, row_index = 0, col_index = 1)
    my_slack.chat_post_message(slack_channel, "Value at cell B1: `%s`" % value)

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
    my_sheets.write_range(id, a1_range, data)

    # API documentation for reading data:
    # https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets.values/get
    data = my_sheets.read_range(id, a1_range)
    for i, row in enumerate(data):
        if row[1] == "":
            # Workaround to read formulas.
            row[1] = my_sheets.read_cell(
                id,
                row_index = i,
                col_index = 1,
                value_render_option = "FORMULA",
            )
        msg = "Row %d: `%s` = `%s`" % (i + 1, row[0], row[1])
        my_slack.chat_post_message(slack_channel, msg)

def _set_cell_range_formatting(id):
    """Set formatting for a range of cells in a Google Spreadsheet.

    Args:
        id: Google Sheet ID, from its URL.
    """

    # API documentation for cell formatting:
    # https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets/cells#CellFormat

    # FYI - reference for color codes:
    # https://spreadsheet.dev/how-to-get-the-hexadecimal-codes-of-colors-in-google-sheets

    my_sheets.set_background_color(id, "A1:B1", 0xea4335)
    my_sheets.set_background_color(id, "A2:B2", 0x34a853)
    my_sheets.set_background_color(id, "A3:B3", 0x4285f4)

    my_sheets.set_text_format(id, "A1:B3", color = 0xffffff)
