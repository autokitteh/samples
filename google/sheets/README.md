# Google Sheets Sample Project

This sample project demonstrates AutoKitteh's 2-way integration with
[Google Sheets](https://www.google.com/sheets/about/).

It has two versions which are independent but equivalent: Python, and Starlark
(which is a dialect of Python - see https://bazel.build/rules/language).

The code files ([`program.py`](./program.py) or [`program.star`](./program.star))
implement an entry-point function that is triggered by incoming Slack events,
as defined in the [`autokitteh-python.yaml`](./autokitteh-python.yaml) or
[`autokitteh-starlark.yaml`](./autokitteh-starlark.yaml) manifest files.

In this sample, we expect a Slack slash command where the text is either:

- A Google Spreadsheet ID
  (see definition [here](https://developers.google.com/sheets/api/guides/concepts))
- A full Google Spreadsheet URL
  (which we parse with a regular expression)

When triggered by such a Slack slash command, the entry-point function calls
various read and write functions in the specified Google Spreadsheet.

API documentation:

- [REST API reference](https://developers.google.com/sheets/api/reference/rest)
- [Go client API](https://pkg.go.dev/google.golang.org/api/sheets/v4)
- [Python client API](https://developers.google.com/resources/api-libraries/documentation/sheets/v4/python/latest/sheets_v4.spreadsheets.html)

Python code samples:

- https://github.com/googleworkspace/python-samples/tree/main/sheets

## Instructions

See [here](https://github.com/autokitteh/samples/tree/main/google#instructions).

## Connection Notes

See [here](https://github.com/autokitteh/samples/tree/main/google#connection-notes).
