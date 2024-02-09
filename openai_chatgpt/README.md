# OpenAI ChatGPT Sample Project

This project demonstrates autokitteh's integration with
[OpenAI ChatGPT](https://chat.openai.com).

The file [`program.star`](./program.star) implements a single entry-point
function, which is mapped in the [`autokitteh.yaml`](./autokitteh.yaml)
manifest file as the receiver of `"slack_slash_command"` events.

It sends a couple of requests to the ChatGPT API, and sends the responses
back to the user over Slack, as well as ChatGPT token usage stats.

API details:

- [OpenAI developer platform](https://platform.openai.com/)
- [Go client API](https://pkg.go.dev/github.com/sashabaranov/go-openai)

This project isn't meant to cover all available functions and events. it
merely showcases a few illustrative, annotated, reusable examples.

This project isn't meant to cover all available functions, it merely showcases
a few illustrative and annotated examples.

## Instructions

1. Open a browser, and go to the autokitteh server's URL
2. Go to the integrations page, and choose OpenAI ChatGPT and Slack
3. Create connections for them, and copy the resulting tokens
4. Paste them in the designated `TODO` lines in the
   [`autokitteh.yaml`](./autokitteh.yaml) manifest file

Then, via the `ak` CLI tool, or the autokitteh VSCode extension:

1. Apply the `autokitteh.yaml` manifest file
2. Build and deploy [`program.star`](./program.star)
