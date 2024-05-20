# Pull Request Review Reminder (PuRRR)

PuRRR streamlines code reviews, to cut down the turnaround time for
merging pull requests.

- Integrates GitHub and Slack seamlessly and efficiently
- Provides real-time, relevant, informative, 2-way updates
- Enables better collaboration and faster execution

No more:

- Delays or stress due to missed requests, comments, and state changes
- Notification fatigue due to updates that don't concern you
- Qestions like "Who's turn is it" or "What should I do now"

All that - and more - is implemented in AutoKitteh with about ~500 lines of
actual code!

## Slack Usage

Event-based, 2-way synchronization:

- Slack channels are created and archived automatically for each PR
- Stakeholders are added and removed automatically to/from them
- Also: reviews, comments, threads, and emoji reactions

User matching between GitHub and Slack is based on email addresses and
case-insensitive full names.

Available Slack slash commands:

- `/ak purrr help`
- `/ak purrr opt-in`
- `/ak purrr opt-out`
- `/ak purrr list`
- `/ak purrr status [PR]`
- `/ak purrr approve [PR]`

## Cache Considerations

This project uses [Redis](https://redis.io/) or [Valkey](https://valkey.io/)
as a NoSQL cache for:

1. Mapping between GitHub PRs and Slack channels
2. Mapping between GitHub comments/reviews and Slack message threads
3. Caching user IDs (optimization to reduce API calls)
4. User opt-out database

Use-cases 1 and 2 use a TTL of 30 days (configurable in the `autokitteh.yaml`
manifest file). Use-case 3 uses a TTL of one day since the last cache hit.
Use-case 4 is permanent (until the user opts back in).
