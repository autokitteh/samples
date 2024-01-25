"""This program demonstrates autokitteh's Twilio integration.

API details:
- Messaging API Overview: https://www.twilio.com/docs/messaging/api

This program implements various entry-point functions that are mapped to
trigger events from autokitteh connections in the file "autokitteh.yaml".

When the project has an active deployment, and autokitteh receives trigger
events from its connections, it starts runtime sessions which execute the
mapped entry-point functions.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load(
    "env",
    # See the value in the "autokitteh.yaml" manifest file.
    "FROM_NUMBER",
)
load("@twilio", "twilio")

def on_slack_app_mention(data):
    """https://api.slack.com/events/app_mention"""

    # Convert data.text from "<@UserID> message" to "message".
    text = data.text.split(" ")[-1]
    twilio.send_twilio_message_to_given_phone(text)

def on_slack_slash_command(data):
    """https://api.slack.com/interactivity/slash-commands"""
    send_twilio_message_to_given_phone(data.text)

def send_twilio_message_to_given_phone(target_phone_number):
    """Send an SMS text via Twilio to a phone number ("+12345556789")."""
    resp = twilio.create_message(
        from_number = FROM_NUMBER,
        to = target_phone_number,
        body = "Meow!",
    )
    print(resp)
