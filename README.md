# Sample Projects for autokitteh

## Overview

Each of the project directories contains:

- A `README.md` documentation file
- An `autokitteh.yaml` manifest file
- One or more program files (code and resources)

Some projects focus on the capabilities and API details of specific
autokitteh integrations.

Other projects are more cross-functional and product-oriented, demonstrating
the operation and value of the system as a whole.

### Manifest Files

The `autokitteh.yaml` file is a declarative manifest that describes the
configuration of a project:

- Project name
- Code and resource file(s)
- autokitteh connection(s)
- Execution environments (e.g. test/prod, geographical regions, availability
  zones)
- Triggers (asyncrhnous events from connections, mapped to entry-point
  functions)

### Source Code Files

All the programs are currently implemented in
[Starlark](https://bazel.build/rules/language) - a dialect of Python.

Stay tuned for implementations in Python, TypeScript, and other languages!

## Projects

Capabilities and API details of specific autokitteh integrations:

- [GitHub](./github/)
- [Google](./google/)
  - [Sheets](./google/sheets/)
- [Scheduler (Cron)](./scheduler/)
- [Slack](./slack/)
- [Twilio](./twilio/)

Cross-functional and product-oriented, demonstrating the operation and value
of the system as a whole:

- [Pull Request Review Reminder (PuRRR)](./purrr/)
