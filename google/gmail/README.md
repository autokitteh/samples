# Gmail Sample Project

This sample project demonstrates AutoKitteh's integration with
[Gmail](https://www.google.com/gmail/about/).

The file [`program.star`](./program.star) implements a single entry-point
function, which is configured in the [`autokitteh.yaml`](./autokitteh.yaml)
manifest file as the receiver of `slash_command` events.

When triggered by a Slack slash command, it calls a Gmail API function,
depending on the input, and posts the results back to the Slack user:

- `gmail get profile`
- `gmail drafts list [optional query]`
- `gmail drafts get <draft ID>`
- `gmail messages list [optional query]`
- `gmail messages get <message ID>`
- `gmail messages send <short message to yourself>`

API details:

- [API overview](https://developers.google.com/gmail/api/guides)
- [REST API reference](https://developers.google.com/gmail/api/reference/rest)
- [Go client API](https://pkg.go.dev/google.golang.org/api/gmail/v1)

This project isn't meant to cover all available functions and events. It
merely showcases various illustrative, annotated, reusable examples.

## Instructions

See [here](https://github.com/autokitteh/samples/tree/main/google#instructions).

## Connection Notes

See [here](https://github.com/autokitteh/samples/tree/main/google#connection-notes).
