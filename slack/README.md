# Slack Sample Project

This sample project demonstrates AutoKitteh's 2-way integration with
[Slack](https://slack.com).

It has two versions which are independent but equivalent: Python, and Starlark
(which is a dialect of Python - see https://bazel.build/rules/language).

The code files ([`program.py`](./program.py) or [`program.star`](./program.star))
implement multiple entry-point functions that are triggered by incoming Slack
events, which are defined in the [`autokitteh-python.yaml`](./autokitteh-python.yaml)
or [`autokitteh-starlark.yaml`](./autokitteh-starlark.yaml) manifest files.
These functions also execute various Slack API calls.

API details:

- [Web API reference](https://api.slack.com/methods)
- [Python web API reference](https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html)
- [Events API reference](https://api.slack.com/events?filter=Events)

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

   ak connection init <Slack connection ID>
   ```

> [!TIP]
> Additional information about Slack in AutoKitteh:
>
> - [Configuring the Slack Integration](https://docs.autokitteh.com/config/integrations/slack)
> - [Creating a Socket-Mode Slack Connection](https://docs.autokitteh.com/tutorials/new_connections/slack)
