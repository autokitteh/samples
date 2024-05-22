def start_github_action(data):
    """Start a GitHub action workflow.

    See the following link for more information:
    https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_dispatch

    This function isn't configured in "autokitteh.yaml" by default as the
    entry-point for an AutoKitteh trigger, because it requires a named
    workflow YAML file to be present in a relevant GitHub repository.

    Example workflow YAML file (in the repo's ".github/workflows" directory):

        on: workflow_dispatch
        jobs:
          job-name:
            runs-on: ubuntu-latest
            steps:
              - run: echo "Do stuff"

    Args:
        data: GitHub event data (e.g. new pull request).
    """
    repo = data.repo
    owner = repo.owner.login
    ref = data.pull_request.head.ref  # Branch name or tag
    workflow_file = "dispatch.yml"  # .github/workflows/dispatch.yml

    # https://docs.github.com/en/rest/actions/workflows#create-a-workflow-dispatch-event
    my_github.trigger_workflow(owner, repo.name, ref, workflow_file)
