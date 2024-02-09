"""This program demonstrates autokitteh's Twilio integration.

This program implements two entry-point functions that are mapped
to trigger events in the "autokitteh.yaml" manifest file. One is
a Slack trigger to initiate sending Twilio messages, and the
other is a webhook receiving status reports from Twilio.

API details:
- Messaging API overview: https://www.twilio.com/docs/messaging/api
- Voice API overview: https://www.twilio.com/docs/voice/api

In this sample, we expect the slash command's text to be a valid
phone number to send messages to.

It also demonstrates using constant values which are set for each
autokitteh environment in the "autokitteh.yaml" manifest file.

When the project has an active deployment, and autokitteh receives
trigger events from its connections, it starts runtime sessions
which execute these mapped entry-point functions.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load("@twilio", "twilio")
load("env", "FROM_NUMBER")  # Set in "autokitteh.yaml".

def on_slack_slash_command(data):
    """https://api.slack.com/interactivity/slash-commands

    Args:
        data: Slack event data.
    """

    # Send SMS text via Twilio to the given phone number ("+12345556789").
    resp = twilio.create_message(
        from_number = FROM_NUMBER,
        to = data.text,
        body = "This is an autokitteh demo message, meow!",
    )

    # For education and debugging purposes, print Twilio's response
    # in the autokitteh session's log.
    print(resp)

    # Also send a Whatsapp message to the same number.
    resp = twilio.create_message(
        from_number = "whatsapp:" + FROM_NUMBER,
        to = "whatsapp:" + data.text,
        body = "This is an autokitteh demo message, meow!",
    )
    print(resp)
