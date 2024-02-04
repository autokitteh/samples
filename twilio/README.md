# Twilio Sample Project

This project demonstrates autokitteh's integration with
[Twilio](https://www.twilio.com).

The file [`program.star`](./program.star) implements two entry-point functions
that are mapped to trigger events in the [`autokitteh.yaml`](./autokitteh.yaml)
manifest file. One is a Slack trigger to initiate sending Twilio messages, and
the other is a webhook receiving status reports from Twilio.

API details:

- [Messaging API overview](https://www.twilio.com/docs/messaging/api)

It also demonstrates using constant values which are set for each autokitteh
environment in the [`autokitteh.yaml`](./autokitteh.yaml) manifest file.

## Instructions

1. Open a browser, and go to the autokitteh server's URL
2. Go to the integrations page, and choose Twilio and Slack
3. Create connections for them, and copy the resulting tokens
4. Paste them in the designated `TODO` lines in the
   [`autokitteh.yaml`](./autokitteh.yaml) manifest file
5. Set the `FROM_NUMBER` environment value

Then, via the `ak` CLI tool, or the autokitteh VSCode extension:

1. Apply the `autokitteh.yaml` manifest file
2. Build and deploy [`program.star`](./program.star)

## Connection Notes

autokitteh supports connecting to Twilio using either an auth token or an
[API key](https://www.twilio.com/docs/glossary/what-is-an-api-key), which are
configured in step 3 above.
