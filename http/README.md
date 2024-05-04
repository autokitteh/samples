# HTTP/REST Sample Project

This sample project demonstrates AutoKitteh's bidirectional integration with
HTTP.

The `.star` files implement entry-point functions that are triggered by HTTP
events (such as receiving GET and POST requests), and then send HTTP requests
to an HTTP testing server.

The [`autokitteh.yaml`](./autokitteh.yaml) manifest file configures the URL
paths of the project's webhooks for receiving HTTP events, and the base URL
for sending HTTP requests.

The HTTP integration in AutoKitteh supports sending and receiving requests
with these HTTP methods:

- [GET](https://www.rfc-editor.org/rfc/rfc9110#GET)
- [HEAD](https://www.rfc-editor.org/rfc/rfc9110#HEAD)
- [POST](https://www.rfc-editor.org/rfc/rfc9110#POST)
- [PUT](https://www.rfc-editor.org/rfc/rfc9110#PUT)
- [DELETE](https://www.rfc-editor.org/rfc/rfc9110#DELETE)
- [OPTIONS](https://www.rfc-editor.org/rfc/rfc9110#OPTIONS)
- [PATCH](https://www.rfc-editor.org/rfc/rfc5789)

## Instructions

1. Optional: prepare an HTTP server for testing (the default is
   <https://httpbin.org>)

2. Create AutoKitteh connection tokens for authenticated HTTP

   1. Open a browser, and go to the AutoKitteh server's URL
   2. Create HTTP connections, and copy the resulting tokens
   3. Replace the `TODO` lines in the [`autokitteh.yaml`](./autokitteh.yaml)
      manifest file

3. Via the `ak` CLI tool, or the AutoKitteh VS Code extension, deploy the
   `autokitteh.yaml` manifest file

4. Trigger the project by sending HTTP requests to its webhook:

   ```shell
   curl "http://<autokitteh address>/http/http_sample/<trigger_path>"
   ```

   ```shell
   curl -X POST "http://<autokitteh address>/http/http_sample/" \
        --data key1=value1 --data key2=value2
   ```
