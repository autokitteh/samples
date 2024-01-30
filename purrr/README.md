# Pull Request Review Reminder (PuRRR)

PuRRR streamlines code reviews, to cut down the turnaround time for
merging pull requests.

- Integrates GitHub and Slack seamlessly and efficiently
- Provides real-time, relevant, informative, and bidirectional updates
- Enables better collaboration and faster execution

No more:

- Delays or stress due to missed requests, comments, and state changes
- Notification fatigue due to updates that don't concern you
- Qestions like "Who's turn is it?" or "What should I do now?"

All that - and more - is implemented in autokitteh with about 500 lines of
code! (Not including comments, whitespaces, and multi-line wrapping for
readability)

## Cache Considerations

This project uses [Redis](https://redis.io/) as a NoSQL cache for:

1. Mapping PRs to Slack channel ID strings
2. Mapping reviews to Slack message ID strings

> [!NOTE]
> For the purpose of these two use-cases, PuRRR assumes that a PR's cache
> doesn't expire as long as that PR is active. Furthermore, PuRRR doesn't
> perform any cleanup when PRs are closed (because they may be reopened).

By default, autokitteh uses an in-memory instance of
[Miniredis](https://github.com/alicebob/miniredis). This simplifies
evaluation, but is unreliable for production usage.

> [!CAUTION]
> If you intend to use this project "for real", make sure you:
>
> - Use a real Redis server or cluster
> - Consider the following when you configure Redis:
>   - [Disaster recovery](https://redis.io/docs/management/persistence/#disaster-recovery)
>   - [Resource usage](https://redis.io/docs/reference/eviction/)
>   - [Security](https://redis.io/docs/management/security/)
> - Set autokitteh's `store.server_url` configuration to your Redis URL
