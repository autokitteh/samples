"""This program demonstrates autokitteh's scheduler abilities.

This program implements a single entry-point function, which is configured
in the "autokitteh.yaml" file as the receiver of "scheduler" events.

It also demonstrates using constant values which are set for each
AutoKitteh environment in the "autokitteh.yaml" manifest file.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load("@slack", "my_slack")
load("env", "SLACK_CHANNEL")  # Set in "autokitteh.yaml".

def on_cron_trigger(data):
    """An autokitteh cron schedule was triggered."""
    my_slack.chat_post_message(SLACK_CHANNEL, "daily reminder about open PRs")
