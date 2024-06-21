# Slack Sample Project

This sample project demonstrates AutoKitteh's 2-way integration with
[Slack](https://slack.com).

It has two versions which are independent but equivalent: Python, and Starlark
(which is a dialect of Python - see https://bazel.build/rules/language).

The code files ([`program.py`](./program.py) or [`program.star`](./program.star))
implement multiple entry-point functions that are triggered by incoming Slack
events, as defined in the [`autokitteh-python.yaml`](./autokitteh-python.yaml)
or [`autokitteh-starlark.yaml`](./autokitteh-starlark.yaml) manifest files.
These functions also execute various Slack API calls.

API documentation:

- [Web API reference](https://api.slack.com/methods)
- [Events API reference](https://api.slack.com/events?filter=Events)
- [Python client API](https://slack.dev/python-slack-sdk/api-docs/slack_sdk/)

This project isn't meant to cover all available functions and events. It
merely showcases a few illustrative, annotated, reusable examples.

## Instructions

1. Choose one of the implementation options of this project: Python or
   Starlark

2. Deploy the manifest file which corresponds to your choice:

   ```shell
   ak deploy --manifest samples/slack/autokitteh-python.yaml
   ```

   or

   ```shell
   ak deploy --manifest samples/slack/autokitteh-starlark.yaml
   ```

3. Follow the instructions in the `ak` CLI tool's output:

   ```
   Connection created, but requires initialization.
   Please run this to complete:

   ak connection init <connection ID>
   ```

4. Events that this sample project responds to:

   - Mentions of the Slack app in messages (e.g. `Hi @autokitteh`)
   - Slash commands registered by the Slack app
     (`/autokitteh <channel name or ID>`)
   - In all channels that the Slack app was added to:
     - New and edited messages and replies
     - New emoji reactions

## Connection Notes

AutoKitteh supports 2 connection modes with Slack:

- Slack app that uses
  [OAuth v2](https://docs.autokitteh.com/config/integrations/slack)

- Slack app that uses
  [Socket Mode](https://docs.autokitteh.com/tutorials/new_connections/slack)

In both cases, the user authorizes the Slack app in step 3 above.
