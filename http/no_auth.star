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
"""

load("@http", "http_without_auth")
load("env", "HTTPBIN_BASE_URL")  # Set in "autokitteh.yaml".

# TODO: FIX "resp.body" across this file!!!

# data(
#     params = {\"username\": \"aaa\", \"password\": \"bbb\"},
#     url = url(
#         fragment = \"\", host = \"\", opaque = \"\", path = \"/basic/aaa/bbb\",
#         query = {},
#         raw = \"\",
#         raw_fragment = \"\",
#         raw_query = \"\",
#         scheme = \"\"
#     )
# )

def on_http_get(data):
    """https://www.rfc-editor.org/rfc/rfc9110#GET

    Args:
        data: Incoming HTTP request details.
    """
    print(data.method)  # "GET"
    print(data.url)  # Reference: https://pkg.go.dev/net/url#URL
    # TODO: print(data.url_string)

    for key, value in data.headers.items():
        print("Request header: %s = %s" % (key, value))

    print(data.body.text())  # "" (because GET requests don't have a body).

    get_echo_params()
    get_html()
    get_json()
    # TODO: get_error()

def get_echo_params():
    """https://www.rfc-editor.org/rfc/rfc9110#GET

    https://httpbin.org/#/HTTP_Methods/get_get
    """

    # Other optional dictionary argument: headers.
    params = {"key1": "value1", "key2": "value2"}
    resp = http_without_auth.get(HTTPBIN_BASE_URL + "/get", params = params)

    print(resp.url)  # HTTPBIN_BASE_URL + "/get?key1=value1&key2=value2"
    print(resp.status_code)  # 200

    for key, value in resp.headers.items():
        print("Response header: %s = %s" % (key, value))

    print(resp.body.text())  # "{\n  \"args\": {\n    \"key1\": \"value1\", ... }\n"

    # Note: "args" is expected to exist because it's a part of httpbin's
    # echo reponse body, there is no standard structure in "resp.body.json()".
    # Also, if "args" is empty in httpbin's JSON response, then it won't be in
    # "resp.body.json()" at all. "dict.get()" handles this possibility safely,
    # compared to direct access like "dict['key']".
    args = resp.body.json().get("args")
    print(args.get("key1", "not found"))
    print(args.get("key2", "not found"))

def get_html():
    """https://www.rfc-editor.org/rfc/rfc9110#GET

    https://httpbin.org/#/Response_formats/get_html
    """

    # Optional dictionary arguments: headers, params.
    resp = http_without_auth.get(HTTPBIN_BASE_URL + "/html")

    print(resp.url)  # HTTPBIN_BASE_URL + "/html"
    print(resp.status_code)  # 200

    for key, value in resp.headers.items():
        print("Response header: %s = %s" % (key, value))

    print(resp.body.text())  # "\u003c!DOCTYPE html\u003e\\n..."

def get_json():
    """https://www.rfc-editor.org/rfc/rfc9110#GET

    https://httpbin.org/#/Response_formats/get_json
    """

    # Optional dictionary arguments: headers, params.
    resp = http_without_auth.get(HTTPBIN_BASE_URL + "/json")

    print(resp.url)  # HTTPBIN_BASE_URL + "/json"
    print(resp.status_code)  # 200

    for key, value in resp.headers.items():
        print("%s = %s" % (key, value))

    print(resp.body.json())  # {"slideshow": {"author": "Yours Truly", ... }}
    print(resp.body.json().get("slideshow", {}).get("author"))  # "Yours Truly"

def get_error():
    pass  # TODO: Implement.

def on_http_post(data):
    """https://www.rfc-editor.org/rfc/rfc9110#POST

    Args:
        data: Incoming HTTP request details.
    """
    print(data.method)  # "GET"
    print(data.url)  # Reference: https://pkg.go.dev/net/url#URL
    # TODO: print(data.url_string)

    for key, value in data.headers.items():
        print("Request header: %s = %s" % (key, value))

    print(data.body.text())
    print(data.body.form())

    for key, value in data.body.form().items():
        print("Request body: %s = %s" % (key, value))

    post_echo_form()
    # TODO: post_json()
    # TODO: post_error()

def post_echo_form():
    """https://www.rfc-editor.org/rfc/rfc9110#POST

    https://httpbin.org/#/HTTP_Methods/post_post
    """

    # Other optional dictionary arguments: headers, params.
    # Alternative body arguments: raw_body (string), or json_body (struct).
    form = {"key1": "value1", "key2": "value2"}
    resp = http_without_auth.post(HTTPBIN_BASE_URL + "/post", form_body = form)

    print(resp.url)  # HTTPBIN_BASE_URL + "/post"
    print(resp.status_code)  # 200

    for key, value in resp.headers.items():
        print("Response header: %s = %s" % (key, value))

    print(resp.body.text())  # "{\n  \"args\": {}, ... }\n"
    print(resp.body.json())  # "{"args": {}, ... }"

    # Note: "form" is expected to exist because it's a part of httpbin's
    # echo reponse body, there is no standard structure in "resp.body.json()".
    # Also, if "form" is empty in httpbin's JSON response, then it won't be in
    # "resp.body.json()" at all. "dict.get()" handles this possibility safely,
    # compared to direct access like "dict['key']".
    form = resp.body.json().get("args")
    print(form.get("key1", "not found"))
    print(form.get("key2", "not found"))
