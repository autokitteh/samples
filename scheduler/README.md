# Scheduler (Cron) Sample Project

This sample project demonstrates AutoKitteh's integration with a cron-like
scheduler.

The file [`program.star`](./program.star) implements a single entry-point
function, which is configured in the [`autokitteh.yaml`](./autokitteh.yaml)
manifest file as the receiver of `"cron_trigger"` events.

It also demonstrates using constant values which are set for each AutoKitteh
environment in the [`autokitteh.yaml`](./autokitteh.yaml) manifest file.

## Instructions

1. Set the `SLACK_CHANNEL` environment value

2. Create AutoKitteh connection tokens

   1. Open a browser, and go to the AutoKitteh server's URL
   2. Create Scheduler (Cron) and Slack connections, and copy the resulting
      tokens
   3. Replace the `TODO` lines in the [`autokitteh.yaml`](./autokitteh.yaml)
      manifest file

3. Via the `ak` CLI tool, or the AutoKitteh VS Code extension, deploy the
   `autokitteh.yaml` manifest file

## Connection Notes

Information about cron schedules:

- [Cron expression format ("\* \* \* \* \*")](https://pkg.go.dev/github.com/robfig/cron#hdr-CRON_Expression_Format)
- [Predefined schedules and intervals ("@" format)](https://pkg.go.dev/github.com/robfig/cron#hdr-Predefined_schedules)
- [Crontab.guru - cron schedule expression editor](https://crontab.guru/)

The optional memo text field can be used in programs that receive cron events,
to identify the connection, or explain the schedule's meaning or purpose.
