# HTTP/REST Sample Project

This sample project demonstrates autokitteh's bidirectional integration with
HTTP.

The [`program.star`](./program.star) file implements two entry-point functions
that are triggered by HTTP events (such as receiving GET and POST requests),
and then send HTTP requests to an HTTP testing server.

The [`autokitteh.yaml`](./autokitteh.yaml) manifest file configures the URL
path of the project's webhook for receiving HTTP events, the HTTP method
triggers, and the base URL for sending HTTP requests.

The HTTP integration in autokitteh supports sending and receiving requests
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

2. Via the `ak` CLI tool, or the autokitteh VS Code extension:

   - Apply the `autokitteh.yaml` manifest file
   - Build and deploy [`program.star`](./program.star)

3. Trigger the project by sending HTTP requests to its webhook:

   ```shell
   curl "http://<autokitteh address>/http/http_simple/trigger_url_path"
   ```

   ```shell
   curl -X POST "http://<autokitteh address>/http/http_simple/trigger_url_path" \
        --data key1=value1 --data key2=value2
   ```

TODO: Support URL suffix (e.g. path, params)
