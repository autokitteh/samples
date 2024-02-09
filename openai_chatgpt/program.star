"""This program demonstrates autokitteh's OpenAI ChatGPT integration.

This program implements a single entry-point function, which is mapped in
the "autokitteh.yaml" file as the receiver of "slack_slash_command" events.

It sends a couple of requests to the ChatGPT API, and sends the responses
back to the user over Slack, as well as ChatGPT token usage stats.

API details:
- OpenAI developer platform: https://platform.openai.com/
- Go client API: https://pkg.go.dev/github.com/sashabaranov/go-openai

When the project has an active deployment, and autokitteh receives
trigger events from its connections, it starts runtime sessions
which execute the mapped entry-point function.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load("@chatgpt", "chatgpt")
load("@slack", "slack")

MODEL = "gpt-3.5-turbo"

def on_slack_slash_command(data):
    """https://api.slack.com/interactivity/slash-commands

    Args:
        data: Slack event data.
    """

    # Example 1: trivial interaction with ChatGPT.
    resp = chatgpt.create_chat_completion(message = "Hello!")

    # For educational and debugging purposes, print ChatGPT's response
    # in the autokitteh session's log.
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
    resp = chatgpt.create_chat_completion(model = MODEL, messages = msgs)
    if resp.error:
        slack.chat_post_message(data.user_id, "Error: `%s`" % resp.error)
    else:
        for choice in resp.choices:
            slack.chat_post_message(data.user_id, choice.message.content)
        slack.chat_post_message(data.user_id, "Usage: `%s`" % str(resp.usage))
