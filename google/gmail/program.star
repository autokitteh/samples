"""This program demonstrates AutoKitteh's Gmail integration.

This program implements a single entry-point function, which is
configured in the "autokitteh.yaml" manifest file as the receiver
of Slack "slash_command" events.

When triggered by a Slack user, it executes various Gmail API calls
depending on the user's input, and posts the results back to the user.

API details:
- API overview: https://developers.google.com/gmail/api/guides
- REST API reference: https://developers.google.com/gmail/api/reference/rest
- Go client API: https://pkg.go.dev/google.golang.org/api/gmail/v1

This program isn't meant to cover all available functions and events.
It merely showcases various illustrative, annotated, reusable examples.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load("@gmail", "my_gmail")
load("@slack", "my_slack")

def on_slack_slash_command(data):
    """https://api.slack.com/interactivity/slash-commands

    In this sample, we expect the slash command's text to be:
    - "gmail get profile"
    - "gmail drafts list [optional query]"
    - "gmail drafts get <draft ID>"
    - "gmail messages list [optional query]"
    - "gmail messages get <message ID>"
    - "gmail messages send <short message to yourself>"

    Args:
        data: Slack event data.
    """
    for cmd, handler in COMMANDS.items():
        if data.text.startswith(cmd):
            handler(data.user_id, data.text[len(cmd) + 1:])
            return

def _get_profile(slack_channel, _):
    """https://developers.google.com/gmail/api/reference/rest/v1/users/getProfile

    Args:
        slack_channel: Slack channel name/ID to post debug messages to.
        _: Unused suffix of the user's Slack command, if any.
    """
    resp = my_gmail.get_profile()
    if resp.error:
        my_slack.chat_post_message(slack_channel, "Error: " + resp.error)
        return
    if resp.http_status_code != 200:
        msg = "Error: HTTP response code %d" % resp.http_status_code
        my_slack.chat_post_message(slack_channel, msg)
        my_slack.chat_post_message(slack_channel, str(resp))
        return

    my_slack.chat_post_message(slack_channel, resp.email_address)
    msg = "Messages total: `%d`" % resp.messages_total
    my_slack.chat_post_message(slack_channel, msg)
    msg = "Threads total: `%d`" % resp.threads_total
    my_slack.chat_post_message(slack_channel, msg)
    msg = "Current History ID: `%s`" % resp.history_id
    my_slack.chat_post_message(slack_channel, msg)

def _drafts_get(slack_channel, id):
    """https://developers.google.com/gmail/api/reference/rest/v1/users.drafts/get

    Args:
        slack_channel: Slack channel name/ID to post debug messages to.
        id: Required ID of the draft to retrieve.
    """
    resp = my_gmail.drafts_get(id)
    if resp.error:
        my_slack.chat_post_message(slack_channel, "Error: " + resp.error)
        return
    if resp.http_status_code != 200:
        msg = "Error: HTTP response code %d" % resp.http_status_code
        my_slack.chat_post_message(slack_channel, msg)
        my_slack.chat_post_message(slack_channel, str(resp))
        return

    my_slack.chat_post_message(slack_channel, 'Draft ID: `"%s"`' % resp.id)
    msg = 'Draft message ID: `"%s"`' % resp.message.id
    my_slack.chat_post_message(slack_channel, msg)
    msg = 'Draft message thread ID: `"%s"`' % resp.message.thread_id
    my_slack.chat_post_message(slack_channel, msg)
    msg = 'Draft message history ID: `"%s"`' % resp.message.history_id
    my_slack.chat_post_message(slack_channel, msg)
    for id in resp.message.label_ids:
        msg = 'Draft message label ID: `"%s"`' % id
        my_slack.chat_post_message(slack_channel, msg)

    msg = "Draft message internal date: `%d`" % resp.message.internal_date
    my_slack.chat_post_message(slack_channel, msg)
    msg = "Draft message size estimate: `%d`" % resp.message.size_estimate
    my_slack.chat_post_message(slack_channel, msg)

    msg = "Draft message (snippet):\n`%s`" % resp.message.snippet
    my_slack.chat_post_message(slack_channel, msg)
    msg = "Draft message (raw):\n`%s`" % resp.message.raw
    my_slack.chat_post_message(slack_channel, msg)
    msg = "Draft message (payload):\n`%s`" % str(resp.message.payload)
    my_slack.chat_post_message(slack_channel, msg)

def _drafts_list(slack_channel, query):
    """https://developers.google.com/gmail/api/reference/rest/v1/users.drafts/list

    Args:
        slack_channel: Slack channel name/ID to post debug messages to.
        query: Optional query, e.g. "is:unread".
    """
    resp = my_gmail.drafts_list(max_results = 10, q = query)
    if resp.error:
        my_slack.chat_post_message(slack_channel, "Error: " + resp.error)
        return
    if resp.http_status_code != 200:
        msg = "Error: HTTP response code %d" % resp.http_status_code
        my_slack.chat_post_message(slack_channel, msg)
        my_slack.chat_post_message(slack_channel, str(resp))
        return

    msg = "Result size estimate: `%d`" % resp.result_size_estimate
    my_slack.chat_post_message(slack_channel, msg)

    for i, d in enumerate(resp.drafts, 1):
        msg = 'Draft %d: ID `"%s"`, message ID `"%s"`, message thread ID `"%s"`'
        msg %= (i, d.id, d.message.id, d.message.thread_id)
        my_slack.chat_post_message(slack_channel, msg)

    if resp.next_page_token:
        msg = "Next page token: `%s`" % resp.next_page_token
        my_slack.chat_post_message(slack_channel, msg)

def _messages_get(slack_channel, id):
    """https://developers.google.com/gmail/api/reference/rest/v1/users.messages/get

    Args:
        slack_channel: Slack channel name/ID to post debug messages to.
        id: Required ID of the message to retrieve.
    """
    resp = my_gmail.messages_get(id)
    if resp.error:
        my_slack.chat_post_message(slack_channel, "Error: " + resp.error)
        return
    if resp.http_status_code != 200:
        msg = "Error: HTTP response code %d" % resp.http_status_code
        my_slack.chat_post_message(slack_channel, msg)
        my_slack.chat_post_message(slack_channel, str(resp))
        return

    msg = 'Message ID: `"%s"`' % resp.id
    my_slack.chat_post_message(slack_channel, msg)
    msg = 'Message thread ID: `"%s"`' % resp.thread_id
    my_slack.chat_post_message(slack_channel, msg)
    msg = 'Message history ID: `"%s"`' % resp.history_id
    my_slack.chat_post_message(slack_channel, msg)
    for id in resp.label_ids:
        msg = 'Message label ID: `"%s"`' % id
        my_slack.chat_post_message(slack_channel, msg)

    msg = "Message internal date: `%d`" % resp.internal_date
    my_slack.chat_post_message(slack_channel, msg)
    msg = "Message size estimate: `%d`" % resp.size_estimate
    my_slack.chat_post_message(slack_channel, msg)

    msg = "Message (snippet):\n`%s`" % resp.snippet
    my_slack.chat_post_message(slack_channel, msg)
    msg = "Message (raw):\n`%s`" % resp.raw
    my_slack.chat_post_message(slack_channel, msg)
    msg = "Message (payload):\n`%s`" % str(resp.payload)
    my_slack.chat_post_message(slack_channel, msg)

def _messages_list(slack_channel, query):
    """https://developers.google.com/gmail/api/reference/rest/v1/users.messages/list

    Args:
        slack_channel: Slack channel name/ID to post debug messages to.
        query: Optional query, e.g. "is:unread".
    """
    resp = my_gmail.messages_list(max_results = 10, q = query)
    if resp.error:
        my_slack.chat_post_message(slack_channel, "Error: " + resp.error)
        return
    if resp.http_status_code != 200:
        msg = "Error: HTTP response code %d" % resp.http_status_code
        my_slack.chat_post_message(slack_channel, msg)
        my_slack.chat_post_message(slack_channel, str(resp))
        return

    msg = "Result size estimate: `%d`" % resp.result_size_estimate
    my_slack.chat_post_message(slack_channel, msg)

    for i, m in enumerate(resp.messages, 1):
        msg = 'Message %d: ID `"%s"`, thread ID `"%s"`'
        my_slack.chat_post_message(slack_channel, msg % (i, m.id, m.thread_id))

    if resp.next_page_token:
        msg = "Next page token: `%s`" % resp.next_page_token
        my_slack.chat_post_message(slack_channel, msg)

def _messages_send(slack_channel, text):
    """https://developers.google.com/gmail/api/reference/rest/v1/users.messages/send

    See also: https://developers.google.com/gmail/api/guides/sending

    Args:
        slack_channel: Slack channel name/ID to post debug messages to.
        text: Short message to send to yourself.
    """
    resp = my_gmail.get_profile()
    if resp.error:
        my_slack.chat_post_message(slack_channel, "Error: " + resp.error)
        return
    if resp.http_status_code != 200:
        msg = "Error: HTTP response code %d" % resp.http_status_code
        my_slack.chat_post_message(slack_channel, msg)
        my_slack.chat_post_message(slack_channel, str(resp))
        return

    # Raw text compliant with https://datatracker.ietf.org/doc/html/rfc5322.
    # Using join() because we need "\r\n" as the line separator, but
    # Starlark's multi-line strings use "\n" as the line separator.
    resp = my_gmail.messages_send("\r\n".join([
        "From: " + resp.email_address,
        "To: " + resp.email_address,
        "Subject: Test from AutoKitteh",
        "",
        text,
    ]))
    if resp.error:
        my_slack.chat_post_message(slack_channel, "Error: " + resp.error)
        return
    if resp.http_status_code != 200:
        msg = "Error: HTTP response code %d" % resp.http_status_code
        my_slack.chat_post_message(slack_channel, msg)
        my_slack.chat_post_message(slack_channel, str(resp))
        return

    my_slack.chat_post_message(slack_channel, "Sent!")

COMMANDS = {
    "gmail get profile": _get_profile,
    "gmail drafts get": _drafts_get,
    "gmail drafts list": _drafts_list,
    "gmail messages get": _messages_get,
    "gmail messages list": _messages_list,
    "gmail messages send": _messages_send,
}
