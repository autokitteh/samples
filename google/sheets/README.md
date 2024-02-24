# Google Sheets Sample Project

This sample project demonstrates autokitteh's integration with
[Google Sheets](https://www.google.com/sheets/about/).

The file [`program.star`](./program.star) implements single entry-point
function, which is configured in the [`autokitteh.yaml`](./autokitteh.yaml)
manifest file as the receiver of `"slack_slash_command"` events. Once
triggered by a Slack user, it reads and writes in a Google Spreadsheet.

API details:

- [REST API reference](https://developers.google.com/sheets/api/reference/rest)
- [Go client API](https://pkg.go.dev/google.golang.org/api/sheets/v4)

In this sample, we expect the slash command's text to be either:

- A Google Spreadsheet ID
  (see definition [here](https://developers.google.com/sheets/api/guides/concepts))
- A full Google Spreadsheet URL
  (which we parse with a regular expression)

It also demonstrates using a custom builtin module (`re`) to extract the
Google Spreadsheet ID from a URL with a
[regular expression](https://qri.io/docs/reference/starlark-packages/re).

## Instructions

See [here](https://github.com/autokitteh/samples/tree/main/google#instructions).

## Connection Notes

See [here](https://github.com/autokitteh/samples/tree/main/google#connection-notes).
