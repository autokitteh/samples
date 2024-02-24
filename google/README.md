# Google Sample Projects

These sample projects demonstrate autokitteh's integration with Google APIs:

Google Workspace:

- Calendar
- Chat
- Drive
- Forms
- [Gmail](./gmail/)
- [Sheets](./sheets/)

Google Cloud:

- Stay tuned!

## Instructions

1. Open a browser, and go to the autokitteh server's URL
2. Go to the integrations page, and choose a Google service
3. Create a connection for it, and copy the resulting token
4. Replace the `TODO` line in the [`autokitteh.yaml`](./autokitteh.yaml)
   manifest file

Then, via the `ak` CLI tool, or the autokitteh VSCode extension:

1. Apply the `autokitteh.yaml` manifest file
2. Build and deploy [`program.star`](./program.star)

## Connection Notes

autokitteh supports 2 connection modes with Google APIs:

- OAuth v2 (the user signs-in and authorizes autokitteh in step 3 above)

  - [Learn about authentication and authorization](https://developers.google.com/workspace/guides/auth-overview)
  - [Google Identity - Using OAuth 2.0](https://developers.google.com/identity/protocols/oauth2/web-server)

- GCP service account (JSON key)

  - [GCP service accounts overview](https://cloud.google.com/iam/docs/service-account-overview)
  - [Service account credentials](https://cloud.google.com/iam/docs/service-account-creds)
  - [Create and delete service account keys](https://cloud.google.com/iam/docs/keys-create-delete)
  - [Best practices for managing service account keys](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)
