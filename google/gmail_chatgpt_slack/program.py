"""
This program demonstrates a real-life workflow that integrates Gmail, ChatGPT, and Slack.

Workflow:
1. Trigger: Detect a new email in Gmail.
2. Categorize: Use ChatGPT to read and categorize the email (e.g., technical work, marketing, sales).
3. Notify: Send a message to the corresponding Slack channel based on the category.
4. Label: Add a label to the email in Gmail.
"""

import base64
from datetime import UTC, datetime
import os.path
import time

import autokitteh
from autokitteh import google, slack
from openai import OpenAI

SLACK_CHANNELS = ["demos", "engineering", "ui"]


def on_http_get(data):
    total_messages = None
    while True:
        total_messages = _poll_inbox(total_messages)
        time.sleep(10)


@autokitteh.activity
def _poll_inbox(prev_total_messages: int):
    gmail = google.gmail_client("my_gmail").users()
    # TODO: fix: If user deletes emails before the next poll then new email messages will be missed.
    curr_total_messages = _get_message_count(gmail)
    if prev_total_messages and curr_total_messages > prev_total_messages:
        new_email_count = curr_total_messages - prev_total_messages
        message_ids = _get_latest_message_ids(gmail, new_email_count)
        for message_id in message_ids:
            _process_email(gmail, message_id)

    return curr_total_messages


def _process_email(gmail, message_id: str):
    message = gmail.messages().get(userId="me", id=message_id).execute()
    email_content = _parse_email(message)
    if email_content:
        channel_name = _categorize_email(email_content, SLACK_CHANNELS)
        print(f"Email categorized to channel: {channel_name}")
        # TODO: Add verification of slack-channel?
        _send_slack_message(channel_name)

        # Add label to email
        label_id = _get_label_id(gmail, channel_name)
        if not label_id:
            created_label = _create_label(gmail, channel_name)
            label_id = created_label["id"]
        gmail.messages().modify(
            userId="me", id=message_id, body={"addLabelIds": [label_id]}
        ).execute()


def _get_latest_message_ids(gmail, new_email_count: int):
    """Get the latest email message_id from the user's inbox.

    Args:
        gmail: An authorized Gmail API service instance.
        new_email_count: The number of new email messages to retrieve.
    Returns: A list of email message_id strings.
    """
    results = gmail.messages().list(userId="me", maxResults=new_email_count).execute()

    return [msg["id"] for msg in results.get("messages", [])]


def _parse_email(message: dict):
    """Parse provided email.

    Args:
        message: The email message to parse

    Returns: The email body as a string.
    """
    payload = message["payload"]
    for part in payload.get("parts", []):
        if part["mimeType"] == "text/plain":
            return base64.urlsafe_b64decode(part["body"]["data"]).decode("utf-8")


def _create_label(gmail, label_name: str) -> dict:
    """Create a new label in the user's gmail account.

    Args:
        gmail: An authorized Gmail API service instance.
        label_name: The name of the label to be created.

    Returns: The created label as a dictionary.
    https://developers.google.com/gmail/api/reference/rest/v1/users.labels#Label
    """
    label = {
        "labelListVisibility": "labelShow",
        "messageListVisibility": "show",
        "name": label_name,
    }
    created_label = gmail.labels().create(userId="me", body=label).execute()
    print(f"Label created: {created_label['name']}")
    return created_label


def _get_label_id(gmail, label_name: str) -> str:
    """Get the label_id for a label with the provided name if it exists.
    Args:
        gmail: An authorized Gmail API service instance.
        label_name: The name of the label to retrieve the id for.
    """
    labels_response = gmail.labels().list(userId="me").execute()
    labels = labels_response.get("labels", [])
    for label in labels:
        if label["name"] == label_name:
            return label["id"]
    return None


def _get_message_count(gmail) -> int:
    """Returns The total number of messages in the user's inbox."""
    profile = gmail.getProfile(userId="me").execute()
    return profile["messagesTotal"]


@autokitteh.activity
def _categorize_email(email_content: str, channels: list[str]) -> str:
    """Prompt ChatGPT to categorize an email based on its content.

    Args:
        email_content: The content of the email as a string.
        channels: A list of channel names as strings.

    Returns: The name of the Slasck channel to send a message to as a string.
    """
    client = _openai_client()
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {
                "role": "user",
                "content": f"""Categorize the following email based on its
                topic and suggest a channel to post it in from the 
                provided list. The output should be one of the provided 
                channels and nothing else.
                Email Content: {email_content} Channels: {channels}
                Output example: ui""",
            },
        ],
    )
    response_content = response.choices[0].message.content
    # TODO: Validate the response_content to ensure it's one of the provided channels.
    return response_content


def _send_slack_message(channel_name: str):
    client = slack.client("my_slack")
    # TODO: Replace generic 'Hello world' message with a more meaningful message.
    response = client.chat_postMessage(channel=channel_name, text="Hello world")
    response.validate()


def _openai_client() -> OpenAI:
    ak_connection_name = "my_chatgpt"
    api_key = os.getenv(ak_connection_name + "__api_key")
    if not api_key:
        raise RuntimeError('Env variable "OPENAI_API_KEY" not set')

    client = OpenAI(api_key=api_key)
    return client
