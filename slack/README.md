# Slack Sample Project

This project demonstrates autokitteh's integration with
[Slack](https://slack.com).

API details:

- [Slack Events API](https://api.slack.com/apis/connections/events-api)
- [Slack Web API](https://api.slack.com/web)

It also demonstrates using a helper module to sleep for a specified number of
seconds, or a specified duration (`"12h34m56s"``).

## Instructions

1. Open a browser, and go to the autokitteh server's URL
2. Go to the integrations page, and choose Slack
3. Create a connection, and copy the resulting token
4. Paste it in the designated line in the
   [`autokitteh.yaml`](./autokitteh.yaml) manifest file
5. Apply the `autokitteh.yaml` file - via the `ak` CLI, or VSCode extension
6. Build and deploy [`program.star`](./program.star)

## Connection Notes

autokitteh connects to Slack via an OAuth-based Slack app, which is installed
and authorized in a Slack workspace in step 3 above.
