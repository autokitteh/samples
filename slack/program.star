"""This program demonstrates autokitteh's Slack integration.

API details:
- Slack Events API: https://api.slack.com/apis/connections/events-api
- Slack Web API: https://api.slack.com/web

This program implements various entry-point functions that are mapped to
trigger events from autokitteh connections in the file "autokitteh.yaml".

When the project has an active deployment, and autokitteh receives trigger
events from its connections, it starts runtime sessions which execute the
mapped entry-point functions.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load(
    "slack",
    # https://api.slack.com/methods/chat.postMessage
    "chat_post_message",
    # https://api.slack.com/methods/chat.update
    "chat_update",
    # https://api.slack.com/methods/conversations.replies
    "conversations_replies",
    # https://api.slack.com/methods/reactions.add
    "reactions_add",
    # Convenience wrapper for "chat.postMessage"
    "send_approval_message",
    # https://api.slack.com/methods/users.info
    "users_info",
)
load("time", "sleep")

def on_slack_app_mention(data):
    """https://api.slack.com/events/app_mention

    Args:
        data: Slack event data.
    """

    # Send 3 messages in response to the event.
    user = "<@" + data.user + ">"
    channel = "<#" + data.channel + ">"
    text = "You mentioned me in %s and wrote: `%s`" % (channel, data.text)
    chat_post_message(channel = data.user, text = text)
    chat_post_message("#slack-test", text.replace("You", user))
    text = "Before update :crying_cat_face:"
    resp = chat_post_message("#slack-test", text)

    # Update the last sent message.
    sleep(seconds = 10)
    text = "After update :smiley_cat:"
    resp = chat_update(channel = resp.channel, ts = resp.ts, text = text)

    # Reply to the message's thread.
    sleep(seconds = 5)
    text = "Reply before update :crying_cat_face:"
    resp = chat_post_message(resp.channel, resp.ts, text)

    # Update the threaded reply message.
    sleep(seconds = 5)
    text = "Reply after update :smiley_cat:"
    chat_update(resp.channel, resp.ts, text)

    # Add a reaction to the threaded reply message.
    reactions_add(channel = resp.channel, name = "blob-clap", timestamp = resp.ts)

    # Retrieve all the replies.
    resp = conversations_replies(channel = resp.channel, ts = resp.ts)
    print(resp)

def on_slack_message(data):
    """https://api.slack.com/events/message

    Args:
        data: Slack event data.
    """
    user = "<@" + data.user + ">" if data.user else "A bot"
    if data.subtype == "":
        if data.thread_ts == "":
            on_slack_new_message(data, user)
        else:
            # https://api.slack.com/events/message/message_replied
            on_slack_reply_message(data, user)
    elif data.subtype == "message_changed":
        on_slack_message_changed(data, user)

def on_slack_new_message(data, user):
    """Someone wrote a new message."""
    msg = ":point_up: %s wrote: `%s`" % (user, data.text)
    chat_post_message(data.channel, msg)

def on_slack_reply_message(data, user):
    """Someone wrote a reply in a thread."""
    msg = ":point_up: %s wrote a reply to <@%s>: `%s`"
    msg %= (user, data.parent_user_id, data.text)
    chat_post_message(data.channel, data.thread_ts, msg)

def on_slack_message_changed(data, user):
    """Someone edited a message."""
    msg = ":point_up: %s edited a message from `%s` to `%s`"
    msg %= (user, data.previous_message.text, data.message.text)

    # Thread TS may or may not be empty, depending on the edited message.
    chat_post_message(data.channel, data.thread_ts, msg)

def on_slack_reaction_added(data):
    """https://api.slack.com/events/reaction_added"""
    print(data.user)
    print(data.reaction)
    print(data.item)

def on_slack_slash_command(data):
    """https://api.slack.com/interactivity/slash-commands

    See also: https://api.slack.com/interactivity/handling#message_responses

    Args:
        data: Slack event data.
    """
    user_info = users_info(user = data.user_id)
    if user_info.ok:
        profile = user_info.user.profile
        text = "Slack mention: <@" + data.user_id + ">"
        chat_post_message(channel = data.user_id, text = text)
        text = "Full name: " + profile.real_name
        chat_post_message(channel = data.user_id, text = text)
        text = "Email: " + profile.email
        chat_post_message(channel = data.user_id, text = text)

    # Treat the text of the user's slash command as a message target (channel
    # ID/name or user ID), and send an interactive message to that target.
    title = "Question From %s" % data.user_id
    msg = "Please select one of these options... :smiley_cat:"
    send_approval_message(target = data.text, header = title, message = msg)

def on_slack_interaction(data):
    """https://api.slack.com/reference/interaction-payloads/block-actions

    Args:
        data: Slack event data.
    """
    respond_to = data.message.text[14:]  # Who's interested in the result?
    button = data.actions[0].text.text  # What is the result (button label)?
    msg = "<@%s> clicked the `%s` button" % (data.user.id, button)
    if data.actions[0].style == "primary":  # Green button.
        msg += " :+1:"
    elif data.actions[0].style == "danger":  # Red button.
        msg += " :-1:"
    chat_post_message(channel = respond_to, text = msg)
