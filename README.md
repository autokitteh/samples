# Sample Projects for autokitteh

## Overview

Each of the projects below comprises an `autokitteh.yaml` manifest file, and
one or more program files.

The `autokitteh.yaml` file is a declarative manifest that describes the setup
of an autokitteh project:

- Project name
- Program file(s)
- autokitteh connection(s)
- Execution environments (e.g. test/prod, geographical regions, availability
  zones)
- Triggers (asyncrhnous events from connections, mapped to entry-point
  functions)

All the programs are currently implemented in
[Starlark](https://bazel.build/rules/language) - a simple dialect of Python.

Stay tuned for implementations in Python, TypeScript, and other languages!

## Projects

Integration demos:

- [GitHub](/github/)
- [Google](/google/)
  - [Sheets](/google/sheets/)
- [Scheduler (Cron)](/scheduler/)
- [Slack](/slack/)
- [Twilio](/twilio/)
