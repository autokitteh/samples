# Slack Sample Project

This sample project demonstrates autokitteh's integration with
[Slack](https://slack.com).

The file [`program.star`](./program.star) implements multiple entry-point
functions that are mapped to various Slack webhook events in the
[`autokitteh.yaml`](./autokitteh.yaml) manifest file. It also executes various
Slack API calls.

API details:

- [Web API reference](https://api.slack.com/methods)
- [Events API reference](https://api.slack.com/events?filter=Events)

It also demonstrates using a custom builtin function (`sleep`) to sleep for a
specified number of seconds.

This project isn't meant to cover all available functions and events. it
merely showcases a few illustrative, annotated, reusable examples.

## Instructions

1. Open a browser, and go to the autokitteh server's URL
2. Go to the integrations page, and choose Slack
3. Create a connection, and copy the resulting token
4. Replace the `TODO` line in the [`autokitteh.yaml`](./autokitteh.yaml)
   manifest file

Then, via the `ak` CLI tool, or the autokitteh VSCode extension:

1. Apply the `autokitteh.yaml` manifest file
2. Build and deploy [`program.star`](./program.star)

## Connection Notes

autokitteh connects to Slack via an
[OAuth-based Slack app](https://api.slack.com/authentication/oauth-v2), which
is installed and authorized in a Slack workspace in step 3 above.
