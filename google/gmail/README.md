# Gmail Sample Project

This sample project demonstrates AutoKitteh's 2-way integration with
[Gmail](https://www.google.com/gmail/about/).

It has two versions which are independent but equivalent: Python, and Starlark
(which is a dialect of Python - see https://bazel.build/rules/language).

The code files ([`program.py`](./program.py) or [`program.star`](./program.star))
implement an entry-point function that is triggered by incoming Slack events,
as defined in the [`autokitteh-python.yaml`](./autokitteh-python.yaml) or
[`autokitteh-starlark.yaml`](./autokitteh-starlark.yaml) manifest files.

When triggered by a Slack slash command, the entry-point function calls a
Gmail API function, depending on the input, and posts the results back to the
Slack user:

- `gmail get profile`
- `gmail drafts list [optional query]`
- `gmail drafts get <draft ID>`
- `gmail messages list [optional query]`
- `gmail messages get <message ID>`
- `gmail messages send <short message to yourself>`

API documentation:

- [API overview](https://developers.google.com/gmail/api/guides)
- [REST API reference](https://developers.google.com/gmail/api/reference/rest)
- [Go client API](https://pkg.go.dev/google.golang.org/api/gmail/v1)
- [Python client API](https://developers.google.com/resources/api-libraries/documentation/gmail/v1/python/latest/gmail_v1.users.html)

Python code samples:

- https://github.com/googleworkspace/python-samples/tree/main/gmail

This project isn't meant to cover all available functions and events. It
merely showcases a few illustrative, annotated, reusable examples.

## Instructions

See [here](https://github.com/autokitteh/samples/tree/main/google#instructions).

## Connection Notes

See [here](https://github.com/autokitteh/samples/tree/main/google#connection-notes).
