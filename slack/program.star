"""This program demonstrates AutoKitteh's 2-way Slack integration.

This program implements multiple entry-point functions that
are triggered by incoming Slack events, which are defined in
the "autokitteh-starlark.yaml" manifest file. These functions
also execute various Slack API calls.

API details:
- Web API reference: https://api.slack.com/methods
- Events API reference: https://api.slack.com/events?filter=Events

This program also demonstrates using a custom builtin function (sleep)
to sleep for a specified number of seconds.

This program isn't meant to cover all available functions and events.
It merely showcases various illustrative, annotated, reusable examples.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
Comapre this file with "program.py" that uses Python code.
"""

load("@slack", "my_slack")
load("message.json", "blocks")

def on_slack_app_mention(data):
    """https://api.slack.com/events/app_mention

    Args:
        data: Slack event data.
    """

    # Send messages in response to the event:
    # - DM to the user who triggered the event (channel ID = user ID)
    # - Two messages to the channel "#slack-test"
    # See: https://api.slack.com/methods/chat.postMessage
    text = "You mentioned me in <#%s> and wrote: `%s`" % (data.channel, data.text)
    my_slack.chat_post_message(channel = data.user, text = text)

    text = text.replace("You", "<@%s>" % data.user)
    my_slack.chat_post_message("#slack-test", text)

    text = "Before update :crying_cat_face:"
    resp = my_slack.chat_post_message("#slack-test", text)

    # Encountered an error? Print debugging information
    # in the AutoKitteh session's log, and finish.
    if not resp.ok:
        print(resp.error)
        return

    # Update the last sent message, after a few seconds.
    # See: https://api.slack.com/methods/chat.update
    sleep(10)
    text = "After update :smiley_cat:"
    resp = my_slack.chat_update(channel = resp.channel, ts = resp.ts, text = text)

    # Reply to the message's thread, after a few seconds.
    sleep(5)
    text = "Reply before update :crying_cat_face:"
    resp = my_slack.chat_post_message(resp.channel, text, thread_ts = resp.ts)

    # Update the threaded reply message, after a few seconds.
    sleep(5)
    text = "Reply after update :smiley_cat:"
    my_slack.chat_update(resp.channel, resp.ts, text)

    # Add a reaction to the threaded reply message.
    # See: https://api.slack.com/methods/reactions.add
    my_slack.reactions_add(channel = resp.channel, name = "blob-clap", timestamp = resp.ts)

    # Retrieve all the replies.
    # See: https://api.slack.com/methods/conversations.replies
    resp = my_slack.conversations_replies(channel = resp.channel, ts = resp.ts)

    # For educational purposes, print all the replies in the AutoKitteh session's log.
    if resp.ok:
        for msg in resp.messages:
            print(msg)

def on_slack_message(data):
    """https://api.slack.com/events/message

    Args:
        data: Slack event data.
    """
    if not data.subtype:
        user = "<@%s>" % data.user
        if not data.thread_ts:
            _on_slack_new_message(data, user)
        else:
            # https://api.slack.com/events/message/message_replied
            _on_slack_reply_message(data, user)
    elif data.subtype == "message_changed":
        user = "<@%s>" % data.message.user  # Not the same as above!
        _on_slack_message_changed(data, user)

def _on_slack_new_message(data, user):
    """Someone wrote a new message."""
    text = ":point_up: %s wrote: `%s`" % (user, data.text)
    my_slack.chat_post_message(data.channel, text)

def _on_slack_reply_message(data, user):
    """Someone wrote a reply in a thread."""
    text = ":point_up: %s wrote a reply to <@%s>: `%s`"
    text %= (user, data.parent_user_id, data.text)
    my_slack.chat_post_message(data.channel, text, thread_ts = data.thread_ts)

def _on_slack_message_changed(data, user):
    """Someone edited a message."""
    text = ":point_up: %s edited a message from `%s` to `%s`"
    text %= (user, data.previous_message.text, data.message.text)

    # Thread TS may or may not be empty, depending on the edited message.
    my_slack.chat_post_message(data.channel, text, thread_ts = data.thread_ts)

def on_slack_reaction_added(data):
    """https://api.slack.com/events/reaction_added

    Args:
        data: Slack event data.
    """

    # For educational purposes, print the event data in the AutoKitteh session's log.
    print(data.user)
    print(data.reaction)
    print(data.item)

def on_slack_slash_command(data):
    """https://api.slack.com/interactivity/slash-commands

    See also: https://api.slack.com/interactivity/handling#message_responses

    The text after the slash command is expected to be a valid target for a
    Slack message (https://api.slack.com/methods/chat.postMessage#channels):
    Slack user ID ("U"), user DM ID ("D"), multi-person/group DM ID ("G"),
    channel ID ("C"), or channel name (with or without the "#" prefix).

    Note that all targets except "U", "D" and public channels require
    the Slack app to be added in advance.

    Args:
        data: Slack event data.
    """

    # Retrieve the profile information of the user who triggered this event.
    # See: https://api.slack.com/methods/users.info
    user_info = my_slack.users_info(data.user_id)

    # Encountered an error? Print debugging information
    # in the AutoKitteh session's log, and finish.
    if not user_info.ok:
        print(user_info.error)
        return

    profile = user_info.user.profile
    text = "Slack mention: <@%s>" % data.user_id
    my_slack.chat_post_message(data.user_id, text)
    text = "Full name: " + profile.real_name
    my_slack.chat_post_message(data.user_id, text)
    text = "Email: " + profile.email
    my_slack.chat_post_message(data.user_id, text)

    # Treat the text of the user's slash command as a message target (e.g.
    # channel or user), and send an interactive message to that target.
    title = "Question From %s" % data.user_id
    msg = "Please select one of these options... :smiley_cat:"
    my_slack.send_approval_message(
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
    my_slack.chat_post_message(channel = respond_to, text = msg)

def post_message_with_blocks(target):
    # "blocks" is loaded from a JSON file - see the relevant load() above.
    my_slack.chat_post_message(target, blocks = blocks)
