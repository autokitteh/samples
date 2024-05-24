"""This program demonstrates AutoKitteh's 2-way Slack integration.

This program implements multiple entry-point functions that
are triggered by incoming Slack events, which are defined in
the "autokitteh-python.yaml" manifest file. These functions
also execute various Slack API calls.

API details:
- Web API reference: https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html
- Events API reference: https://api.slack.com/events?filter=Events

This program isn't meant to cover all available functions and events.
It merely showcases various illustrative, annotated, reusable examples.
"""

import os
import time

import munch
import slack_sdk


def _structify(event: dict, key: str = "") -> munch.Munch:
    if key:
        event = event[key]
    return munch.Munch.fromDict(event)


def _slack_client() -> slack_sdk.WebClient:
    token = os.getenv("SLACK_TOKEN")
    if not token:
        raise RuntimeError(f'Env variable "SLACK_TOKEN" not set')

    # TODO: Also support Socket Mode as an optional configuration
    # (https://slack.dev/python-slack-sdk/api-docs/slack_sdk/socket_mode/).
    client = slack_sdk.WebClient(token)

    client.auth_test().validate()
    return client


def on_slack_app_mention(event: dict) -> None:
    """https://api.slack.com/events/app_mention

    Args:
        event: Slack event data.
    """
    data = _structify(event, "data")
    user = f"<@{data.user}>"
    channel = f"<#{data.channel}>"
    slack = _slack_client()

    # Send messages in response to the event:
    # - A DM to the user who triggered the event
    # - Two messages to the channel "#slack-test"
    # See: https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html#slack_sdk.web.client.WebClient.chat_postMessage
    text = f"You mentioned me in {channel} and wrote: `{data.text}`"
    slack.chat_postMessage(channel=data.user, text=text)

    text = text.replace("You", user)
    slack.chat_postMessage(channel="#slack-test", text=text)

    text = "Before update :crying_cat_face:"
    resp = slack.chat_postMessage(channel="#slack-test", text=text)

    # Encountered an error? Print debugging information
    # in the AutoKitteh session's log, and finish.
    resp.validate()

    # Update the last sent message, after a few seconds.
    # See: https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html#slack_sdk.web.client.WebClient.chat_update
    time.sleep(10)
    resp = _structify(resp.data)
    text = "After update :smiley_cat:"
    resp = slack.chat_update(channel=resp.channel, ts=resp.ts, text=text)
    resp = _structify(resp.data)

    # Reply to the message's thread, after a few seconds.
    time.sleep(5)
    text = "Reply before update :crying_cat_face:"
    resp = slack.chat_postMessage(channel=resp.channel, text=text, thread_ts=resp.ts)
    resp = _structify(resp.data)

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

    # For educational purposes, print all the reply objects
    # in the AutoKitteh session's log.
    resp.validate()
    for text in resp.get("messages"):
        print(text)


def on_slack_message(event: dict) -> None:
    """https://api.slack.com/events/message

    Args:
        event: Slack event data.
    """
    data = _structify(event, "data")
    if not data.subtype:
        user = f"<@{data.user}>"
        if not data.thread_ts:
            _on_slack_new_message(data, user)
        else:
            # https://api.slack.com/events/message/message_replied
            _on_slack_reply_message(data, user)
    elif data.subtype == "message_changed":
        user = f"<@{data.message.user}>"
        _on_slack_message_changed(data, user)


def _on_slack_new_message(data: munch.Munch, user: str) -> None:
    """Someone wrote a new message."""
    text = f":point_up: {user} wrote: `{data.text}`"
    _slack_client().chat_postMessage(channel=data.channel, text=text)


def _on_slack_reply_message(data: munch.Munch, user: str) -> None:
    """Someone wrote a reply in a thread."""
    text = ":point_up: %s wrote a reply to <@%s>: `%s`"
    text %= (user, data.parent_user_id, data.text)
    _slack_client().chat_postMessage(
        channel=data.channel, text=text, thread_ts=data.thread_ts
    )


def _on_slack_message_changed(data: munch.Munch, user: str) -> None:
    """Someone edited a message."""
    text = ":point_up: %s edited a message from `%s` to `%s`"
    text %= (user, data.previous_message.text, data.message.text)

    # Thread TS may or may not be empty, depending on the edited message.
    _slack_client().chat_postMessage(
        channel=data.channel, text=text, thread_ts=data.message.thread_ts
    )


def on_slack_reaction_added(event: dict) -> None:
    """https://api.slack.com/events/reaction_added"""
    data = _structify(event, "data")

    # For educational purposes, print the fields of the event object
    # in the AutoKitteh session's log.
    print(data.user)
    print(data.reaction)
    print(data.item)


def on_slack_slash_command(event: dict) -> None:
    """https://api.slack.com/interactivity/slash-commands

    See also: https://api.slack.com/interactivity/handling#message_responses

    Args:
        event: Slack event data.
    """
    data = _structify(event, "data")
    slack = _slack_client()

    # Retrieve the profile information of the user who triggered this event.
    # See: https://slack.dev/python-slack-sdk/api-docs/slack_sdk/web/client.html#slack_sdk.web.client.WebClient.users_info
    user_info = slack.users_info(user=data.user_id)

    # Encountered an error? Print debugging information
    # in the AutoKitteh session's log, and finish.
    user_info.validate()

    profile = _structify(user_info.data).user.profile
    text = f"Slack mention: <@{data.user_id}>"
    slack.chat_postMessage(channel=data.user_id, text=text)
    text = "Full name: " + profile.real_name
    slack.chat_postMessage(channel=data.user_id, text=text)
    text = "Email: " + profile.email
    slack.chat_postMessage(channel=data.user_id, text=text)

    # TODO(ENG-802): Fix regression, use builtin store, and test.
    # Treat the text of the user's slash command as a message target (channel
    # ID/name or user ID), and send an interactive message to that target.


def on_slack_interaction(event: dict) -> None:
    """https://api.slack.com/reference/interaction-payloads/block-actions

    Args:
        event: Slack event data.
    """
    pass  # TODO(ENG-802): Fix regression, use builtin store, and test.
