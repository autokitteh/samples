# OpenAI ChatGPT Sample Project

This sample project demonstrates AutoKitteh's integration with
[OpenAI ChatGPT](https://chat.openai.com).

The file [`program.star`](./program.star) implements a single entry-point
function, which is configured in the [`autokitteh.yaml`](./autokitteh.yaml)
manifest file as the receiver of Slack `slash_command` events.

It sends a couple of requests to the ChatGPT API, and sends the responses
back to the user over Slack, as well as ChatGPT token usage stats.

API details:

- [OpenAI developer platform](https://platform.openai.com/)
- [Go client API](https://pkg.go.dev/github.com/sashabaranov/go-openai)

This project isn't meant to cover all available functions and events. it
merely showcases a few illustrative, annotated, reusable examples.

## Instructions

1. Create AutoKitteh connection tokens

   1. Open a browser, and go to the AutoKitteh server's URL
   2. Create ChatGPT and Slack connections, and copy the resulting tokens
   3. Replace the `TODO` lines in the [`autokitteh.yaml`](./autokitteh.yaml)
      manifest file

2. Via the `ak` CLI tool, or the AutoKitteh VS Code extension, deploy the
   `autokitteh.yaml` manifest file
