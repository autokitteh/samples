# Slack Sample Project

This sample project demonstrates autokitteh's integration with
[Slack](https://slack.com).

The file [`program.star`](./program.star) implements multiple entry-point
functions that are triggered by various Slack webhook events, which are
defined in the [`autokitteh.yaml`](./autokitteh.yaml) manifest file. It also
executes various Slack API calls.

API details:

- [Web API reference](https://api.slack.com/methods)
- [Events API reference](https://api.slack.com/events?filter=Events)

It also demonstrates using a custom builtin function (`sleep`) to sleep for a
specified number of seconds.

This project isn't meant to cover all available functions and events. it
merely showcases a few illustrative, annotated, reusable examples.

## Instructions

1. Create an AutoKitteh connection token

   1. Open a browser, and go to the AutoKitteh server's URL
   2. Create a Slack connection, and copy the resulting token
   3. Replace the `TODO` line in the [`autokitteh.yaml`](./autokitteh.yaml)
      manifest file

3. Via the `ak` CLI tool, or the AutoKitteh VS Code extension, deploy the
   `autokitteh.yaml` manifest file

## Connection Notes

autokitteh connects to Slack via an
[OAuth-based Slack app](https://api.slack.com/authentication/oauth-v2), which
is installed and authorized in a Slack workspace in step 3 above.
