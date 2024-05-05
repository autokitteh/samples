"""This program demonstrates AutoKitteh's scheduler (cron) integration.

This program implements a single entry-point function, which is configured
in the "autokitteh.yaml" file as the receiver of "cron_trigger" events.

It also demonstrates using constant values which are set for each
AutoKitteh environment in the "autokitteh.yaml" manifest file.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load("@slack", "my_slack")
load("env", "SLACK_CHANNEL")  # Set in "autokitteh.yaml".

def on_cron_trigger(data):
    """An AutoKitteh cron schedule was triggered.

    Args:
        data: Cron even data, see below for details.
    """

    # Trigger (AutoKitteh connection) settings.
    msg = "Schedule: `%s`\n" % data.schedule
    msg += "Cron TZ: `%s`\n" % data.timezone  # "Local" or "UTC".
    msg += "Memo: `%s`\n\n" % data.memo

    # Event instance (timestamp).
    msg += "Timestamp: `%s`\n" % data.timestamp
    msg += "Seconds since epoch: `%d`\n" % data.since_epoch
    msg += "Timestamp Location: `%s`\n\n" % data.location

    msg += "Year: `%d`\n" % data.year
    msg += "Month: `%d`\n" % data.month  # January = 1, December = 12.
    msg += "Day: `%d`\n" % data.day
    msg += "Weekday: `%d`\n\n" % data.weekday  # Sunday = 0, Saturday = 6.

    msg += "Hour: `%d`\n" % data.hour
    msg += "Minute: `%d`\n" % data.minute
    msg += "Second: `%d`" % data.second

    my_slack.chat_post_message(SLACK_CHANNEL, msg)
