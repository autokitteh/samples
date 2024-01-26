# Scheduler (Cron) Sample Project

This project demonstrates autokitteh's integration with a cron-like scheduler.

It also demonstrates using constant values which are set for each autokitteh
environment in the [`autokitteh.yaml`](./autokitteh.yaml) manifest file.

This project isn't meant to cover all available functions and events, it
merely showcases a few illustrative and annotated examples.

## Instructions

1. Open a browser, and go to the autokitteh server's URL
2. Go to the integrations page, and choose Scheduler (Cron) and Slack
3. Create connections for them, and copy the resulting tokens
4. Paste them in the designated `TODO` lines in the
   [`autokitteh.yaml`](./autokitteh.yaml) manifest file
5. Set the `SLACK_CHANNEL` environment value

Then, via the `ak` CLI tool, or the autokitteh VSCode extension:

1. Apply the `autokitteh.yaml` manifest file
2. Build and deploy [`program.star`](./program.star)

## Connection Notes

Information about cron schedules:

- [Cron expression format ("\* \* \* \* \*")](https://pkg.go.dev/github.com/robfig/cron#hdr-CRON_Expression_Format)
- [Predefined schedules and intervals ("@" format)](https://pkg.go.dev/github.com/robfig/cron#hdr-Predefined_schedules)
- [Crontab.guru - cron schedule expression editor](https://crontab.guru/)

The optional memo text field can be used in programs that receive cron events,
to identify the connection, or explain the schedule's meaning or purpose.
