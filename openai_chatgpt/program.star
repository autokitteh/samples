"""This program demonstrates AutoKitteh's OpenAI ChatGPT integration.

This program implements a single entry-point function, which is
configured in the "autokitteh.yaml" manifest file as the receiver
of Slack "slash_command" events.

It sends a couple of requests to the ChatGPT API, and sends the responses
back to the user over Slack, as well as ChatGPT token usage stats.

API details:
- OpenAI developer platform: https://platform.openai.com/
- Go client API: https://pkg.go.dev/github.com/sashabaranov/go-openai

This program isn't meant to cover all available functions and events.
It merely showcases various illustrative, annotated, reusable examples.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load("@chatgpt", "my_chatgpt")
load("@slack", "my_slack")

MODEL = "gpt-3.5-turbo"

def on_slack_slash_command(data):
    """https://api.slack.com/interactivity/slash-commands

    Args:
        data: Slack event data.
    """

    # Example 1: trivial interaction with ChatGPT.
    resp = my_chatgpt.create_chat_completion(message = "Hello!")

    # For educational and debugging purposes, print ChatGPT's response
    # in the AutoKitteh session's log.
    print(resp)

    # Example 2: more verbose interaction with ChatGPT,
    # including the user's text as part of the conversation.
    contents = [
        "You are a poetic assistant, skilled in explaining complex engineering concepts.",
        "Compose a Shakespearean sonnet about the importance of reliability, scalability, and durability, in distributed workflows.",
    ]
    msgs = [
        struct(role = "system", content = contents[0]),
        struct(role = "user", content = contents[1]),
        struct(role = "user", content = data.text),
    ]

    # Note that this time we specify the model, and use "messages"
    # (an array of structs) instead of "message" (a string).
    resp = my_chatgpt.create_chat_completion(model = MODEL, messages = msgs)
    if resp.error:
        my_slack.chat_post_message(data.user_id, "Error: `%s`" % resp.error)
    else:
        for choice in resp.choices:
            my_slack.chat_post_message(data.user_id, choice.message.content)
        my_slack.chat_post_message(data.user_id, "Usage: `%s`" % str(resp.usage))
