# Twilio Sample Project

This sample project demonstrates AutoKitteh's integration with
[Twilio](https://www.twilio.com).

The file [`program.star`](./program.star) implements two entry-point functions
that are triggered by events which are defined in the
[`autokitteh.yaml`](./autokitteh.yaml) manifest file. One is a Slack trigger
to initiate sending Twilio messages, and the other is a webhook receiving
status reports from Twilio.

API details:

- [Messaging API overview](https://www.twilio.com/docs/messaging/api)
- [Voice API overview](https://www.twilio.com/docs/voice/api)

It also demonstrates using constant values which are set for each AutoKitteh
environment in the [`autokitteh.yaml`](./autokitteh.yaml) manifest file.

## Instructions

1. Set the `FROM_NUMBER` environment value

2. Create AutoKitteh connection tokens

   1. Open a browser, and go to the AutoKitteh server's URL
   2. Create Slack and Twilio connections, and copy the resulting tokens
   3. Replace the `TODO` lines in the [`autokitteh.yaml`](./autokitteh.yaml)
      manifest file

3. Via the `ak` CLI tool, or the AutoKitteh VS Code extension, deploy the
   `autokitteh.yaml` manifest file

## Connection Notes

AutoKitteh supports connecting to Twilio using either an auth token or an
[API key](https://www.twilio.com/docs/glossary/what-is-an-api-key), which are
configured in step 3 above.
