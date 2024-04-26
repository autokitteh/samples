"""These entry-point functions demonstrate autokitteh's HTTP integration.

They are triggered by HTTP events (such as receiving GET and POST requests),
and then send HTTP requests to an HTTP testing server.

To trigger them, send HTTP GET and POST requests with these commands:

    curl -v "http://localhost:9980/http/http_sample/get"

    curl -v -X POST "http://localhost:9980/http/http_sample/" \
         --data key1=value1 --data key2=value2

The triggers are defined in the "autokitteh.yaml" manifest file:
the (no auth) HTTP connection, the HTTP methods (GET and POST), and
the URL paths under the project's webhook for receiving HTTP events.

The HTTP integration in autokitteh supports sending and receiving requests
with these HTTP methods: GET, HEAD, POST, PUT, DELETE, OPTIONS, and PATCH.

This sample is implemented in Starlark, which is a dialect of Python
(see https://bazel.build/rules/language).


Relevant types and function signatures:

HTTPResponseBody:
    bytes() # Returns response body as bytes
    text()  # Returns response body as text
    json()  # Parses response body as json, returning JSON-decoded result


HTTPResponse:
    url: string             # the url that was ultimately requested (may change after redirects)
    status_code: int        # response status code (for example: 200 == OK)
    headers: dict           # dictionary of response headers
    encoding: string        # transfer encoding. example: "octet-stream" or "application/json"
    body: HTTPResponseBody

get(url: str, params: Optional[str], headers: Optional[str]) -> HTTPResponse

post(url: str, params: Optional[dict], headers: Optional[None],
     data: Optional[string|bytes|list|dict],
     json: Optional[str|dict]
    ) -> HTTPResponse

"""

load("@http", "http_no_auth")
load("env", "HTTPBIN_BASE_URL")  # Set in "autokitteh.yaml".


def print_headers(http_obj, req_type):
    print(req_type, " headers:")
    for key, value in http_obj.headers.items():
        print("  %s = %s" % (key, value))

def print_resp_url_status_headers(resp):
    print("url: ", resp.url)
    print("status code: ", resp.status_code)

    print_headers(resp, "response")

def on_http_get(data):
    """https://www.rfc-editor.org/rfc/rfc9110#GET

    Args:
        data: Incoming HTTP GET request details.
    """
    print("triggered with GET request on %s", data.url.path)
    print("url: ", data.url)  # Reference: https://pkg.go.dev/net/url#URL
    # TODO: print(data.url_string)

    print_headers(data, "request")

    print("request body (text): -----v\n", data.body.text())
    print("request body (form): -----v\n", data.body.form()) # will be empty, no matter what would be sent in body

    # if body isn't JSON (since GET request don't have a body), catch the error:
    j, err = catch(lambda: data.body.json())
    print("request body (json): %s, err: %s \n" % (j, err))

    print("invoking subsequent GET requests:")
    get_echo_params()
    get_html()
    get_json()
    # TODO: get_error()

def get_echo_params():
    """ See
    https://www.rfc-editor.org/rfc/rfc9110#GET
    https://httpbin.org/#/HTTP_Methods/get_get
    """

    url = HTTPBIN_BASE_URL + "/get"
    print("--- (1) get with params (via GET to %s) ---" % url)

    params = {"key1": "value1", "key2": "value2"}
    resp = http_no_auth.get(url, params = params)
    print_resp_url_status_headers(resp)
    # observe that `Content-Type` header is `application/json`.

    # httpbin.org/get echoes back params (as "args"), headers and other things as json
    # In this specific case "headers", "args", "url" keys should be present in the response body.
    print("response body (text): -----v\n", resp.body.text())  # same as json, formatted as multiline text
    print("response body (json): -----v\n", resp.body.json())  # {"args":{"key1":"value1", ... }, ...}

    # Note(s):
    # - "args" key is expected to exist due to httpbin's echo behavior. Params sent will be echoed back as "args".
    # - use get to access probably unexisting dictionary keys safely.
    print("params/args: ")
    args = resp.body.json().get("args", {})
    for k in ("key1", "key2"):
        print("  %s: %s" % (k, args.get(k, "not found")))

def get_html():
    """ See
    https://www.rfc-editor.org/rfc/rfc9110#GET
    https://httpbin.org/#/Response_formats/get_html
    """

    url = HTTPBIN_BASE_URL + "/html"
    print("\n--- (2) get HTML (via GET to %s) ---" % url)

    resp = http_no_auth.get(url)
    print_resp_url_status_headers(resp)

    # In this case, httpbin won't echo back the request body, so the response body will be just html.
    print("response body (txt): -----v\n", resp.body.text())  # "\u003c!DOCTYPE html\u003e\\n..."
    # no need to resp.body.json(), since HTML is not a valid JSON

def get_json():
    """ See
    https://www.rfc-editor.org/rfc/rfc9110#GET
    https://httpbin.org/#/Response_formats/get_json
    """

    url = HTTPBIN_BASE_URL + "/json"
    print("\n--- (2) get JSON (via GET to %s) ---" % url)

    resp = http_no_auth.get(url)
    print_resp_url_status_headers(resp)

    print("response body (bytes): -----v\n", resp.body.bytes()) # same as json, formatted as bytes, printed as multiline text
    print("response body (json): -----v\n", resp.body.json())  # {"slideshow": {"author": "Yours Truly", ... }}
    print("response_json['slideshow']['author']: ", resp.body.json().get("slideshow", {}).get("author"))  # "Yours Truly"

def get_error():
    pass  # TODO: Implement.

def on_http_post(data):
    """https://www.rfc-editor.org/rfc/rfc9110#POST

    Args:
        data: Incoming HTTP POST request details.
    """
    print("triggered with POST request on %s", data.url.path)
    print("url: ", data.url)  # Reference: https://pkg.go.dev/net/url#URL
    # TODO: print(data.url_string)

    print_headers(data, "request")

    print("request body (text): -----v\n", data.body.text()) # key1=value1&key2=value2
    print("request body (form): -----v\n", data.body.form()) # {"key1": "value1", "key2": "value2"}
    print("request form, keys <-> values:")
    for key, value in data.body.form().items():
        print("  %s = %s" % (key, value))

    j, err = catch(lambda: data.body.json())
    print("request body (json): %s, err: %s \n" % (j, err))

    print("invoking subsequent POST requests:")
    url = HTTPBIN_BASE_URL + "/post"
    post_echo_form(url)
    post_json(url)
    # TODO: post_error()

def post_echo_form(url):
    """ See
    https://www.rfc-editor.org/rfc/rfc9110#POST
    https://httpbin.org/#/HTTP_Methods/post_post
    """
    print("--- (1) post form (via POST to %s) ---" % url)

    form = {"foo": "bar"}
    resp = http_no_auth.post(url, data = form)
    print_resp_url_status_headers(resp)

    # httpbin.org/get echoes back form, json, data, headers and other things
    print("response body (text): -----v\n", resp.body.text()) # multiline text, form sent will appear in {"form": ...}
    bodyJson = resp.body.json()
    print("response body (json): -----v\n", bodyJson)

    # form sent will be found in {"form": ...}
    print("form sent: -----v\n", bodyJson.get("form", {}))

def post_json(url):
    """ See
    https://www.rfc-editor.org/rfc/rfc9110#POST
    https://httpbin.org/#/HTTP_Methods/post_post
    """

    # 1
    print("\n--- (2) post json #1 (via POST to %s) ---" % url)

    # send data= param and pass JSON content type
    resp = http_no_auth.post(url, data = {"foo1": "bar1"}, headers={"Content-Type": "application/json"})
    print_resp_url_status_headers(resp)

    # httpbin.org/get echoes back form, json, data, headers and other things
    print("response body (text): -----v\n", resp.body.text()) # multiline text, json sent will appear both under `data` and in `json' keys
    bodyJson = resp.body.json()
    print("response body (json): -----v\n", bodyJson) # {"form": {}, "data": "{\"foo1\":\"bar1\"}", "args": {}, "json": {"foo1": "bar1"}, "headers": {"Content-Type": "application/json", ...}, ...}

    # Note(s):
    # - "json" key is expected due to httpbin's echo behavior. JSON sent will be echoed back in {"json": ...}.
    print("json sent: -----v\n", bodyJson.get("json", {}))

    # 2
    print("\n--- post json #2 (via POST to %s) ---" % url)

    # send JSON via json= param without specifying content type
    resp = http_no_auth.post(url, json = {"foo2": "bar2"})
    print_resp_url_status_headers(resp)

    print("response body (text): -----v\n", resp.body.text()) # multiline text, json sent will appear both under `data` and in `json'
    bodyJson = resp.body.json()
    print("response body (json): -----v\n", bodyJson) # {"form": {}, "data": "{\"foo2\":\"bar2\"}", "args": {}, "json": {"foo2": "bar2"}, "headers": {"Content-Type": "application/json", ...}, ...}
    print("json sent: -----v\n", bodyJson.get("json", {}))
