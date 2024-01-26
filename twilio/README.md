# Twilio Sample Project

This project demonstrates autokitteh's integration with
[Twilio](https://www.twilio.com).

API details:

- [Messaging API Overview](https://www.twilio.com/docs/messaging/api)

It also demonstrates using constant values which are set for each autokitteh
environment in the [`autokitteh.yaml`](./autokitteh.yaml) manifest file.

This project isn't meant to cover all available functions and events, it
merely showcases a few illustrative and annotated examples.

## Instructions

1. Open a browser, and go to the autokitteh server's URL
2. Go to the integrations page, and choose Twilio and Slack
3. Create connections for them, and copy the resulting tokens
4. Paste them in the designated lines in the
   [`autokitteh.yaml`](./autokitteh.yaml) manifest file
5. Set the `FROM_NUMBER` environment value

Then, via the `ak` CLI tool, or the autokitteh VSCode extension:

1. Apply the `autokitteh.yaml` manifest file
2. Build and deploy [`program.star`](./program.star)

## Connection Notes

autokitteh supports connecting to Twilio using either an auth token or an
[API key](https://www.twilio.com/docs/glossary/what-is-an-api-key), which are
configured in step 3 above.
