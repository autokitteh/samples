# Google Sheets Sample Project

This project demonstrates autokitteh's integration with
[Google Sheets](https://www.google.com/sheets/about/).

The file [`program.star`](./program.star) implements single entry-point
function, which is configured in the [`autokitteh.yaml`](./autokitteh.yaml)
manifest file. Once triggered by a Slack user, it reads and writes in a
Google Sheet.

API details:

- [Google Sheets REST API](https://developers.google.com/sheets/api/reference/rest)
- [Go client library documentation](https://pkg.go.dev/google.golang.org/api/sheets/v4)

This project isn't meant to cover all available functions and events, it
merely showcases a few illustrative and annotated examples.

## Instructions

1. Open a browser, and go to the autokitteh server's URL
2. Go to the integrations page, and choose Google and Slack
3. Create connections for them, and copy the resulting tokens
4. Paste them in the designated `TODO` lines in the
   [`autokitteh.yaml`](./autokitteh.yaml) manifest file

Then, via the `ak` CLI tool, or the autokitteh VSCode extension:

1. Apply the `autokitteh.yaml` manifest file
2. Build and deploy [`program.star`](./program.star)

## Connection Notes

autokitteh supports 2 connection modes with Google APIs:

- OAuth v2 (the user signs-in and authorizes autokitteh in step 3 above)

  - [Google Identity - Using OAuth 2.0](https://developers.google.com/identity/protocols/oauth2/web-server)

- GCP service account (JSON key)

  - [GCP service accounts overview](https://cloud.google.com/iam/docs/service-account-overview)
  - [Service account credentials](https://cloud.google.com/iam/docs/service-account-creds)
  - [Create and delete service account keys](https://cloud.google.com/iam/docs/keys-create-delete)
  - [Best practices for managing service account keys](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)

autokitteh supports connecting to Twilio using either an auth token or an
[API key](https://www.twilio.com/docs/glossary/what-is-an-api-key), which are
configured in step 3 above.
