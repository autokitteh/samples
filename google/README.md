# Google Sample Projects

These sample projects demonstrate AutoKitteh's integration with Google APIs:

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

1. [Configure your Google integration](https://docs.autokitteh.com/config/integrations/google).

2. Via the `ak` CLI tool, or the AutoKitteh VS Code extension, deploy the
   `autokitteh.yaml` manifest file

3. Tell AutoKitteh's Slack bot what to do, using a slash command.
   Available options are described in each project.

## Connection Notes

AutoKitteh supports 2 connection modes with Google APIs:

- OAuth v2 (the user signs-in and authorizes AutoKitteh in step 3 above)

  - [Learn about authentication and authorization](https://developers.google.com/workspace/guides/auth-overview)
  - [Google Identity - Using OAuth 2.0](https://developers.google.com/identity/protocols/oauth2/web-server)

- GCP service account (JSON key)

  - [GCP service accounts overview](https://cloud.google.com/iam/docs/service-account-overview)
  - [Service account credentials](https://cloud.google.com/iam/docs/service-account-creds)
  - [Create and delete service account keys](https://cloud.google.com/iam/docs/keys-create-delete)
  - [Best practices for managing service account keys](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)
