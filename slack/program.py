"""This program demonstrates AutoKitteh's 2-way Slack integration.

This program implements multiple entry-point functions that
are triggered by incoming Slack events, which are defined in
the "autokitteh-python.yaml" manifest file. These functions
also execute various Slack API calls.

API details:
- Python client API: https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html
- Events API reference: https://api.slack.com/events?filter=Events

This program isn't meant to cover all available functions and events.
It merely showcases various illustrative, annotated, reusable examples.
"""

import os
import time
import types

import slack_sdk


def _slack_client(ak_connection_name):
    token = os.getenv(ak_connection_name + "__oauth_AccessToken")
    if not token:
        raise RuntimeError(f'Connection "{ak_connection_name}" not initialized')

    # TODO: Also support Socket Mode as an optional configuration
    # (https://slack.dev/python-slack-sdk/api-docs/slack_sdk/socket_mode/).
    client = slack_sdk.WebClient(token)

    client.auth_test().validate()
    return client


def on_slack_app_mention(event):
    """https://api.slack.com/events/app_mention

    Args:
        event: Slack event data.
    """
    slack = _slack_client()

    # Send messages in response to the event:
    # - DM to the user who triggered the event (channel ID = user ID)
    # - Two messages to the channel "#slack-test"
    # See: https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html#slack_sdk.web.client.WebClient.chat_postMessage
    text = f"You mentioned me in <#{event.data.channel}> and wrote: `{event.data.text}`"
    slack.chat_postMessage(channel=event.data.user, text=text)

    text = text.replace("You", f"<@{event.data.user}>")
    slack.chat_postMessage(channel="#slack-test", text=text)

    text = "Before update :crying_cat_face:"
    resp = slack.chat_postMessage(channel="#slack-test", text=text)

    # Encountered an error? Print debugging information
    # in the AutoKitteh session's log, and finish.
    resp.validate()

    # Update the last sent message, after a few seconds.
    # See: https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html#slack_sdk.web.client.WebClient.chat_update
    time.sleep(10)
    resp = _data(resp)
    text = "After update :smiley_cat:"
    resp = _data(slack.chat_update(channel=resp.channel, ts=resp.ts, text=text))

    # Reply to the message's thread, after a few seconds.
    time.sleep(5)
    text = "Reply before update :crying_cat_face:"
    resp = _data(
        slack.chat_postMessage(channel=resp.channel, text=text, thread_ts=resp.ts)
    )

    # Update the threaded reply message, after a few seconds.
    time.sleep(5)
    text = "Reply after update :smiley_cat:"
    slack.chat_update(channel=resp.channel, ts=resp.ts, text=text)

    # Add a reaction to the threaded reply message.
    # See: https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html#slack_sdk.web.client.WebClient.reactions_add
    slack.reactions_add(channel=resp.channel, name="blob-clap", timestamp=resp.ts)

    # Retrieve all the replies.
    # See: https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html#slack_sdk.web.client.WebClient.conversations_replies
    resp = slack.conversations_replies(channel=resp.channel, ts=resp.ts)

    # For educational purposes, print all the replies in the AutoKitteh session's log.
    resp.validate()
    for text in resp.get("messages", default=[]):
        print(text)


def on_slack_message(event):
    """https://api.slack.com/events/message

    Args:
        event: Slack event data.
    """
    if not event.data.subtype:
        user = f"<@{event.data.user}>"
        if not event.data.thread_ts:
            _on_slack_new_message(event.data, user)
        else:
            # https://api.slack.com/events/message/message_replied
            _on_slack_reply_message(event.data, user)
    elif event.data.subtype == "message_changed":
        user = f"<@{event.data.message.user}>"  # Not the same as above!
        _on_slack_message_changed(event.data, user)


def _on_slack_new_message(data, user):
    """Someone wrote a new message."""
    text = f":point_up: {user} wrote: `{data.text}`"
    _slack_client().chat_postMessage(channel=data.channel, text=text)


def _on_slack_reply_message(data, user):
    """Someone wrote a reply in a thread."""
    text = f":point_up: {user} wrote a reply to <@{data.parent_user_id}>: `{data.text}`"
    ts = data.thread_ts
    _slack_client().chat_postMessage(channel=data.channel, text=text, thread_ts=ts)


def _on_slack_message_changed(data, user):
    """Someone edited a message."""
    old, new = data.previous_message.text, data.message.text
    text = f":point_up: {user} edited a message from `{old}` to `{new}`"
    ts = data.message.ts

    # Thread TS may or may not be empty, depending on the edited message.
    _slack_client().chat_postMessage(channel=data.channel, text=text, thread_ts=ts)


def on_slack_reaction_added(event):
    """https://api.slack.com/events/reaction_added

    Args:
        event: Slack event data.
    """

    # For educational purposes, print the event data in the AutoKitteh session's log.
    print(event.data.user)
    print(event.data.reaction)
    print(event.data.item)


def on_slack_slash_command(event):
    """https://api.slack.com/interactivity/slash-commands

    See also: https://api.slack.com/interactivity/handling#message_responses

    The text after the slash command is expected to be a valid target for a
    Slack message (https://api.slack.com/methods/chat.postMessage#channels):
    Slack user ID ("U"), user DM ID ("D"), multi-person/group DM ID ("G"),
    channel ID ("C"), or channel name (with or without the "#" prefix).

    Note that all targets except "U", "D" and public channels require
    the Slack app to be added in advance.

    Args:
        event: Slack event data.
    """
    slack = _slack_client()

    # Retrieve the profile information of the user who triggered this event.
    # See: https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html#slack_sdk.web.client.WebClient.users_info
    user_info = slack.users_info(user=event.data.user_id)

    # Encountered an error? Print debugging information in the AutoKitteh session's log, and finish.
    user_info.validate()

    profile = _data(user_info).user.profile
    text = f"Slack mention: <@{event.data.user_id}>"
    slack.chat_postMessage(channel=event.data.user_id, text=text)
    text = "Full name: " + profile.real_name
    slack.chat_postMessage(channel=event.data.user_id, text=text)
    text = "Email: " + profile.email
    slack.chat_postMessage(channel=event.data.user_id, text=text)

    # TODO(ENG-802): Fix regression, use builtin store, and test.
    # Treat the text of the user's slash command as a message target (e.g.
    # channel or user), and send an interactive message to that target.


def on_slack_interaction(event):
    """https://api.slack.com/reference/interaction-payloads/block-actions

    Args:
        event: Slack event data.
    """
    pass  # TODO(ENG-802): Fix regression, use builtin store, and test.


def _data(resp):
    """Convert a Slack response's data dictionary to an object with attributes."""
    return types.SimpleNamespace(**resp.data)
