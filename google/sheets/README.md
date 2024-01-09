# Google Sheets Sample Project

This project demonstrates autokitteh's integration with
[Google Sheets](https://www.google.com/sheets/about/).

API details:

- [Google Sheets REST API](https://developers.google.com/sheets/api/reference/rest)
- [Go client library documentation](https://pkg.go.dev/google.golang.org/api/sheets/v4)

## Instructions

1. Open a browser, and go to the autokitteh server's URL
2. Go to the integrations page, and choose Google and Slack
3. Create connections for them, and copy the resulting tokens
4. Paste them in the designated lines in the
   [`autokitteh.yaml`](./autokitteh.yaml) manifest file
5. Apply the `autokitteh.yaml` file - via the `ak` CLI, or VSCode extension
6. Build and deploy [`program.star`](./program.star)

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
