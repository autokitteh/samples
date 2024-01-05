# Twilio Sample Project

This project demonstrates autokitteh's integration with
[Twilio](https://www.twilio.com).

API details:

- [Messaging API Overview](https://www.twilio.com/docs/messaging/api)

It also demonstrates using constant values which are set for each autokitteh
environment in the [`autokitteh.yaml`](./autokitteh.yaml) manifest file.

## Instructions

1. Open a browser, and go to the autokitteh server's URL
2. Go to the integrations page, and choose Twilio and Slack
3. Create connections for them, and copy the resulting tokens
4. Paste them in the designated lines in the
   [`autokitteh.yaml`](./autokitteh.yaml) manifest file
5. Apply the `autokitteh.yaml` file - via the `ak` CLI, or VSCode extension
6. Build and deploy [`program.star`](./program.star)

## Connection Notes

autokitteh supports connecting to Twilio using either an auth token or an
[API key](https://www.twilio.com/docs/glossary/what-is-an-api-key), which are
configured in step 3 above.
