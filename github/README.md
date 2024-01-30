# GitHub Sample Project

This project demonstrates autokitteh's integration with
[GitHub](https://github.com).

The file [`program.star`](./program.star) implements multiple entry-point
functions that are mapped to various GitHub webhook events in the
[`autokitteh.yaml`](./autokitteh.yaml) manifest file. It also executes various
GitHub API calls.

API details:

- [GitHub REST API documentation](https://docs.github.com/en/rest)
- [Go client library documentation](https://pkg.go.dev/github.com/google/go-github/v57/github)

It also demonstrates using a custom builtin function (`rand.intn`) to generate
random integer numbers, based on <https://pkg.go.dev/math/rand#Rand.Intn>.

This project isn't meant to cover all available functions and events, it
merely showcases a few illustrative and annotated examples.

## Instructions

1. Open a browser, and go to the autokitteh server's URL
2. Go to the integrations page, and choose GitHub
3. Create a connection, and copy the resulting token
4. Paste it in the designated `TODO` line in the
   [`autokitteh.yaml`](./autokitteh.yaml) manifest file

Then, via the `ak` CLI tool, or the autokitteh VSCode extension:

1. Apply the `autokitteh.yaml` manifest file
2. Build and deploy [`program.star`](./program.star)

## Connection Notes

autokitteh supports 2 connection modes with GitHub:

- Personal Access Token (PAT - fine-grained or classic) + manually-configured
  webhook

  - [Authenticating with a personal access token](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api#authenticating-with-a-personal-access-token)
  - [Managing your personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
  - [Setting a PAT policy for your organization](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization)
  - [Endpoints available for fine-grained PATs](https://docs.github.com/en/rest/authentication/endpoints-available-for-fine-grained-personal-access-tokens)

- GitHub App (installed and authorized in step 3 above)

  - [About using GitHub Apps](https://docs.github.com/en/apps/using-github-apps/about-using-github-apps)
