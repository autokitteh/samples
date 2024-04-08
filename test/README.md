# Testing Samples

An end-to-end testing for samples.

Currently, only `http` is tested.

## Idea

For each sample, we'll

- Start `ak up -m dev1
- Deply the workflow
- Trigger the workflow
- Check that the session completed successfully

The main hurdle is triggering the workflow.
I started with the `http` since it's simple to test,
but for otheres we'll need to do more work and store secrets in GitHub actions.
