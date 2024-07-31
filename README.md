# Sample Projects for AutoKitteh

## Overview

Each of the project directories contains:

- A `README.md` documentation file
- (At least) one `autokitteh.yaml` manifest file
- One or more program files (code and resources)

Some projects focus on the capabilities and API details of specific AutoKitteh
integrations.

Other projects are more cross-functional and product-oriented, demonstrating
the operation and value of the system as a whole.

### Manifest Files

The `autokitteh.yaml` file is a declarative manifest that describes the
configuration of a project:

- Project name
- AutoKitteh connection(s)
- Triggers (asynchronous events from connections, with optional filtering,
  mapped to entry-point functions)
- Optional: global variables

## Projects

Capabilities and API details of specific AutoKitteh integrations:

- [Atlassian Jira](./jira/)
- [GitHub](./github/)
- [Google](./google/)
  - [Gmail](./google/gmail/)
  - [Sheets](./google/sheets/)
- [HTTP / REST](./http/)
- [OpenAPI ChatGPT](./openai_chatgpt/)
- [Scheduler](./scheduler/)
- [Slack](./slack/)
- [Twilio](./twilio/)

For cross-functional and product-oriented, demonstrating the operation and value
of the system as a whole, see [kittehub](https://github.com/autokitteh/kittehub).
