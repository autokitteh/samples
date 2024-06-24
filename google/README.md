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

1. Choose one of the implementation options of this project: Python or
   Starlark

2. Deploy the manifest file which corresponds to your choice:

   ```shell
   ak deploy --manifest samples/google/.../autokitteh-python.yaml
   ```

   or

   ```shell
   ak deploy --manifest samples/google/.../autokitteh-starlark.yaml
   ```

3. Follow the instructions in the `ak` CLI tool's output:

   ```
   Connection created, but requires initialization.
   Please run this to complete:

   ak connection init <connection ID>
   ```

4. Tell AutoKitteh's Slack bot what to do, using a slash command.
   Available options are described in each project.

## Connection Notes

### Google APIs

AutoKitteh supports 2 connection modes with Google APIs:

- [User impersonation with OAuth 2.0](https://docs.autokitteh.com/config/integrations/google)
  (the user authorizes it in step 3 above)

  - [Learn about authentication and authorization](https://developers.google.com/workspace/guides/auth-overview)
  - [Using OAuth 2.0 for web server applications](https://developers.google.com/identity/protocols/oauth2/web-server)

- GCP service account (JSON key)

  - [GCP service accounts overview](https://cloud.google.com/iam/docs/service-account-overview)
  - [Service account credentials](https://cloud.google.com/iam/docs/service-account-creds)
  - [Create and delete service account keys](https://cloud.google.com/iam/docs/keys-create-delete)
  - [Best practices for managing service account keys](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)

### Slack

AutoKitteh supports 2 connection modes with Slack:

- Slack app that uses
  [OAuth v2](https://docs.autokitteh.com/config/integrations/slack)

- Slack app that uses
  [Socket Mode](https://docs.autokitteh.com/tutorials/new_connections/slack)

In both cases, the user authorizes the Slack app in step 3 above.
