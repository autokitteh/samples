"""This program demonstrates autokitteh's Slack integration.

This program implements multiple entry-point functions that are mapped
to various Slack webhook events in the "autokitteh.yaml" manifest file.
It also executes various Slack API calls.

API details:
- Web API reference: https://api.slack.com/methods
- Events API reference: https://api.slack.com/events?filter=Events

It also demonstrates using a custom builtin function (sleep) to sleep
for a specified number of seconds.

When the project has an active deployment, and autokitteh receives
trigger events from its connections, it starts runtime sessions
which execute the mapped entry-point functions.

This program isn't meant to cover all available functions and events.
It merely showcases various illustrative, annotated, reusable examples.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load("@slack", "slack")

def on_slack_app_mention(data):
    """https://api.slack.com/events/app_mention

    Args:
        data: Slack event data.
    """

    # Send messages in response to the event:
    # - A DM to the user who triggered the event
    # - Two messages to the channel "#slack-test"
    # See: https://api.slack.com/methods/chat.postMessage
    user = "<@" + data.user + ">"
    channel = "<#" + data.channel + ">"
    text = "You mentioned me in %s and wrote: `%s`" % (channel, data.text)
    slack.chat_post_message(channel = data.user, text = text)
    slack.chat_post_message("#slack-test", text.replace("You", user))
    text = "Before update :crying_cat_face:"
    resp = slack.chat_post_message("#slack-test", text)

    # Encountered an error? Print debugging information
    # in the autokitteh session's log, and finish.
    if not resp.ok:
        print(resp.error)
        return

    # Update the last sent message, after a few seconds.
    # See: https://api.slack.com/methods/chat.update
    sleep(10)
    text = "After update :smiley_cat:"
    resp = slack.chat_update(channel = resp.channel, ts = resp.ts, text = text)

    # Reply to the message's thread, after a few seconds.
    sleep(5)
    text = "Reply before update :crying_cat_face:"
    resp = slack.chat_post_message(resp.channel, resp.ts, text)

    # Update the threaded reply message, after a few seconds.
    sleep(5)
    text = "Reply after update :smiley_cat:"
    slack.chat_update(resp.channel, resp.ts, text)

    # Add a reaction to the threaded reply message.
    # See: https://api.slack.com/methods/reactions.add
    slack.reactions_add(channel = resp.channel, name = "blob-clap", timestamp = resp.ts)

    # Retrieve all the replies.
    # See: https://api.slack.com/methods/conversations.replies
    resp = slack.conversations_replies(channel = resp.channel, ts = resp.ts)

    # For educational purposes, print all the reply objects
    # in the autokitteh session's log.
    if resp.ok:
        for msg in resp.messages:
            print(msg)

def on_slack_message(data):
    """https://api.slack.com/events/message

    Args:
        data: Slack event data.
    """
    user = "<@" + data.user + ">" if data.user else "A bot"
    if data.subtype == "":
        if data.thread_ts == "":
            _on_slack_new_message(data, user)
        else:
            # https://api.slack.com/events/message/message_replied
            _on_slack_reply_message(data, user)
    elif data.subtype == "message_changed":
        _on_slack_message_changed(data, user)

def _on_slack_new_message(data, user):
    """Someone wrote a new message."""
    msg = ":point_up: %s wrote: `%s`" % (user, data.text)
    slack.chat_post_message(data.channel, msg)

def _on_slack_reply_message(data, user):
    """Someone wrote a reply in a thread."""
    msg = ":point_up: %s wrote a reply to <@%s>: `%s`"
    msg %= (user, data.parent_user_id, data.text)
    slack.chat_post_message(data.channel, data.thread_ts, msg)

def _on_slack_message_changed(data, user):
    """Someone edited a message."""
    msg = ":point_up: %s edited a message from `%s` to `%s`"
    msg %= (user, data.previous_message.text, data.message.text)

    # Thread TS may or may not be empty, depending on the edited message.
    slack.chat_post_message(data.channel, data.thread_ts, msg)

def on_slack_reaction_added(data):
    """https://api.slack.com/events/reaction_added"""

    # For educational purposes, print the fields of the event object
    # in the autokitteh session's log.
    print(data.user)
    print(data.reaction)
    print(data.item)

def on_slack_slash_command(data):
    """https://api.slack.com/interactivity/slash-commands

    See also: https://api.slack.com/interactivity/handling#message_responses

    Args:
        data: Slack event data.
    """

    # Retrieve the profile information of the user who triggered this event.
    # See: https://api.slack.com/methods/users.info
    user_info = slack.users_info(data.user_id)

    # Encountered an error? Print debugging information
    # in the autokitteh session's log, and finish.
    if not resp.ok:
        print(resp.error)
        return

    profile = user_info.user.profile
    text = "Slack mention: <@%s>" % data.user_id
    slack.chat_post_message(data.user_id, text)
    text = "Full name: " + profile.real_name
    slack.chat_post_message(data.user_id, text)
    text = "Email: " + profile.email
    slack.chat_post_message(data.user_id, text)

    # Treat the text of the user's slash command as a message target (channel
    # ID/name or user ID), and send an interactive message to that target.
    title = "Question From %s" % data.user_id
    msg = "Please select one of these options... :smiley_cat:"
    slack.send_approval_message(
        target = data.text,
        header = title,
        message = msg,
    )

def on_slack_interaction(data):
    """https://api.slack.com/reference/interaction-payloads/block-actions

    Args:
        data: Slack event data.
    """

    # The Slack ID of the user who sent the question.
    title_prefix = "Question From "
    respond_to = data.message.text[len(title_prefix):]

    # Result = button label.
    button = data.actions[0].text.text
    msg = "<@%s> clicked the `%s` button" % (data.user.id, button)
    if data.actions[0].style == "primary":  # Green button.
        msg += " :+1:"
    elif data.actions[0].style == "danger":  # Red button.
        msg += " :-1:"
    slack.chat_post_message(channel = respond_to, text = msg)
