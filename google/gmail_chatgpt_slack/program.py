"""
This program demonstrates a real-life workflow that integrates Gmail, ChatGPT, and Slack.

Workflow:
1. Trigger: Detect a new email in Gmail.
2. Categorize: Use ChatGPT to read and categorize the email (e.g., technical work, marketing, sales).
3. Notify: Send a message to the corresponding Slack channel based on the category.
4. Label: Add a label to the email in Gmail.

API References:
- Slack API: https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html
- ChatGPT API: https://platform.openai.com/docs/api-reference/chat
- Gmail API: https://developers.google.com/gmail/api/reference/rest
"""

import base64
import os.path
import time

import autokitteh
from datetime import UTC, datetime
import google.auth
from google.auth.transport.requests import Request
import google.oauth2.credentials as credentials
import google.oauth2.service_account as service_account
from googleapiclient.discovery import build
from openai import OpenAI
import slack_sdk


def on_http_get(data):
    _poll_inbox()


@autokitteh.activity
def _poll_inbox():
    try:
        service = _gmail_client()
    except Exception as e:
        print(f"Error in _gmail_client: {e}")
    total_messages = _get_message_count(service)
    while True:
        # TODO: fix: If user deletes emails before the next poll then new email messages will be missed.
        new_total_messages = _get_message_count(service)
        if new_total_messages > total_messages:
            message_id = _get_latest_message_id(service)
            message = (
                service.users().messages().get(userId="me", id=message_id).execute()
            )
            email_content = _parse_email(message)
            channel_name = _categorize_email(
                email_content, channels=["engineering", "demos", "ui"]
            )
            # TODO: Add verification of slack-channel?
            _send_slack_message(channel_name)

            # Add label to email
            label_id = _get_label_id(service, channel_name)
            if not label_id:
                created_label = _create_label(service, channel_name)
                label_id = created_label["id"]
            _add_label_to_message(label_id, message_id, service)

        total_messages = new_total_messages
        time.sleep(10)


def _get_latest_message_id(service):
    """Get the latest email message_id from the user's inbox.

    Args:
        service: An authorized Gmail API service instance.
    Returns: The email message_id a string.
    """
    results = service.users().messages().list(userId="me", maxResults=1).execute()
    messages = results.get("messages", [])

    if not messages:
        print("No new messages.")
        return None

    message_id = messages[0]["id"]
    return message_id


def _parse_email(message: dict):
    """Parse provided email.

    Args:
        message: The email message to parse

    Returns: The email body as a string.
    """
    payload = message["payload"]
    body = ""
    if "parts" in payload:
        parts = payload["parts"]
        for part in parts:
            if part["mimeType"] == "text/plain":
                body = base64.urlsafe_b64decode(part["body"]["data"]).decode("utf-8")
                break
    else:
        print("No parts in payload.", flush=True)
        body = base64.urlsafe_b64decode(payload["body"]["data"]).decode("utf-8")
    return body


def _add_label_to_message(label_id: str, message_id: str, service):
    """Add a label to a message in the user's inbox.

    Args:
        service: An authorized Gmail API service instance.
        message_id: The email message_id as a string.
        label_id: The label_id as a string.
    """
    try:
        modified_message = (
            service.users()
            .messages()
            .modify(userId="me", id=message_id, body={"addLabelIds": [label_id]})
            .execute()
        )

        print("Message modified successfully:", modified_message)
    except Exception as e:
        print("An error occurred:", e)


def _create_label(service, label_name: str) -> dict:
    """Create a new label in the user's gmail account.

    Args:
        service: An authorized Gmail API service instance.
        label_name: The name of the label to be created.

    Returns: The created label as a dictionary.
    https://developers.google.com/gmail/api/reference/rest/v1/users.labels#Label
    """
    label = {
        "labelListVisibility": "labelShow",
        "messageListVisibility": "show",
        "name": label_name,
    }

    try:
        created_label = (
            service.users().labels().create(userId="me", body=label).execute()
        )
        print(f"Label created: {created_label['name']}")
        return created_label
    except Exception as e:
        print(f"An error occurred: {e}")
        return None


def _get_label_id(service, label_name: str) -> str:
    """Get the label_id for a label with the provided name if it exists.
    Args:
        service: An authorized Gmail API service instance.
        label_name: The name of the label to retrieve the id for.
    """
    try:
        labels_response = service.users().labels().list(userId="me").execute()
        labels = labels_response.get("labels", [])
        for label in labels:
            if label["name"] == label_name:
                return label["id"]
        print(f'Label "{label_name}" does not exist.')
        return None
    except Exception as e:
        print("An error occurred while retrieving labels:", e)
        return None


def _get_message_count(service) -> int:
    """Get the total number of messages in the user's inbox.

    Args:
        service: An authorized Gmail API service instance.

    Returns: The total number of messages as an integer.
    """
    try:
        profile = service.users().getProfile(userId="me").execute()
        return profile["messagesTotal"]
    except Exception as e:
        print(f"Error fetching message count: {e}")
        return 0


@autokitteh.activity
def _categorize_email(email_content: str, channels: list[str]) -> str:
    """Prompt ChatGPT to categorize an email based on its content.

    Args:
        email_content: The content of the email as a string.
        channels: A list of channel names as strings.

    Returns: The name of the Slasck channel to send a message to as a string.
    """
    try:
        api_key = os.getenv("OPENAI_API_KEY")
        client = OpenAI(
            api_key=api_key,
            organization="org-rAdQQpXI14g0xdoXiLk6btKc",
        )
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
                    Output example: 'ui'""",
                },
            ],
        )
        response_content = response.choices[0].message.content
        return response_content
    except Exception as e:
        print(f"Error in _categorize_email: {e}")
        return None


def _send_slack_message(channel_name: str):
    try:
        client = _slack_client()
        # TODO: Replace generic 'Hello world' message with a more meaningful message.
        response = client.chat_postMessage(channel=channel_name, text="Hello world")
        response.validate()

    except Exception as e:
        print(f"Error in send_slack_message: {e}")


def _gmail_client():
    """Initialize a Google Gmail API client.

    This function requires the name of an initialized AutoKitteh connection.
    It supports both connection modes: users (with OAuth v2),
    and GCP service accounts (with a JSON key).
    """
    ak_connection_name = "my_gmail"
    scopes = [
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.settings.basic",
    ]
    # TODO: Add support for service account credentials.

    refresh_token = os.getenv(ak_connection_name + "__oauth_RefreshToken")
    if refresh_token:
        return _gmail_client_with_oauth(ak_connection_name, refresh_token, scopes)

    raise RuntimeError(f'Connection "{ak_connection_name}" not initialized')


def _gmail_client_with_oauth(
    ak_connection_name: str, refresh_token: str, scopes: list[str]
):
    # Normalize the expiry timestamp to a format that Credentials can parse.
    expiry = os.getenv(ak_connection_name + "__oauth_Expiry").split(" ")
    dt = datetime.fromisoformat(f"{expiry[0]}T{expiry[1]}{expiry[2]}")
    expiry = dt.astimezone(UTC).replace(tzinfo=None).isoformat()
    creds = credentials.Credentials.from_authorized_user_info(
        {
            "token": os.getenv(ak_connection_name + "__oauth_AccessToken"),
            "refresh_token": refresh_token,
            "expiry": expiry,
            "client_id": os.getenv("GOOGLE_CLIENT_ID"),
            "client_secret": os.getenv("GOOGLE_CLIENT_SECRET"),
            "scopes": scopes,
        }
    )
    if creds.expired:
        creds.refresh(Request())
    return build("gmail", "v1", credentials=creds)


def _slack_client() -> slack_sdk.WebClient:
    token = os.getenv("SLACK_BOT_TOKEN")
    if not token:
        raise RuntimeError('Env variable "SLACK_BOT_TOKEN" not set')

    # TODO: Also support Socket Mode as an optional configuration
    # (https://slack.dev/python-slack-sdk/api-docs/slack_sdk/socket_mode/).
    client = slack_sdk.WebClient(token)

    client.auth_test().validate()
    return client
