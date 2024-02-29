"""This program demonstrates autokitteh's bidirectional HTTP/REST integration.

It implements two entry-point functions that are triggered
by HTTP events (such as receiving GET and POST requests),
and then send HTTP requests to an HTTP testing server.

The "autokitteh.yaml" manifest file configures the URL path
of the project's webhook for receiving HTTP events, the HTTP
method triggers, and the base URL for sending HTTP requests.

The HTTP integration in autokitteh supports sending and receiving requests
with these HTTP methods: GET, HEAD, POST, PUT, DELETE, OPTIONS, and PATCH.

This sample is implemented in Starlark, which is a dialect of Python
(see https://bazel.build/rules/language).
"""

load("@http", "http")
load("env", "HTTPBIN_BASE_URL")  # Set in "autokitteh.yaml".

def on_http_get(data):
    """https://www.rfc-editor.org/rfc/rfc9110#GET

    Args:
        data: Incoming HTTP request details.
    """
    print(data.method)  # "GET"
    print(data.url)  # Reference: https://pkg.go.dev/net/url#URL
    # TODO: print(data.url_string)

    for key, value in data.header.items():  # TODO: Rename to "headers".
        print("Request header: %s = %s" % (key, value))

    print(data.body)  # "", because GET requests don't have a body.

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
    resp = http.get(HTTPBIN_BASE_URL + "/get", params = params)

    print(resp.url)  # HTTPBIN_BASE_URL + "/get?key1=value1&key2=value2"
    print(resp.status_code)  # 200

    for key, value in resp.headers.items():
        print("Response header: %s = %s" % (key, value))

    print(resp.body)  # "{\n  \"args\": {\n    \"key1\": \"value1\", ... }\n"

    # Note: "args" is expected to exist because it's a part of httpbin's
    # echo reponse body, there is no standard structure in "resp.body_json".
    # Also, if "args" is empty in httpbin's JSON response, then it won't
    # be in "resp.body_json" at all. "getattr()" handles this possibility
    # safely, compared to direct access like "resp.body_json.args.key1".
    # TODO: Is it an AK bug that we discard empty "args" in "resp.body_json"?
    args = getattr(resp.body_json, "args", struct(key1 = "?", key2 = "?"))
    print(args.key1)  # "value1"
    print(args.key2)  # "value2"

def get_html():
    """https://www.rfc-editor.org/rfc/rfc9110#GET

    https://httpbin.org/#/Response_formats/get_html
    """

    # Optional dictionary arguments: headers, params.
    resp = http.get(HTTPBIN_BASE_URL + "/html")

    print(resp.url)  # HTTPBIN_BASE_URL + "/html"
    print(resp.status_code)  # 200

    for key, value in resp.headers.items():
        print("Response header: %s = %s" % (key, value))

    print(resp.body)  # "\u003c!DOCTYPE html\u003e\\n..."
    print(resp.body_json)  # None

def get_json():
    """https://www.rfc-editor.org/rfc/rfc9110#GET

    https://httpbin.org/#/Response_formats/get_json
    """

    # Optional dictionary arguments: headers, params.
    resp = http.get(HTTPBIN_BASE_URL + "/json")

    print(resp.url)  # HTTPBIN_BASE_URL + "/json"
    print(resp.status_code)  # 200

    for key, value in resp.headers.items():
        print("%s = %s" % (key, value))

    print(resp.body)  # "{\n  \"slideshow\": {\n    \"author\": \"Yours Truly\", ..."
    print(resp.body_json.slideshow.author)  # "Yours Truly"

def get_error():
    pass  # TODO: Implement.

def on_http_post(data):
    """https://www.rfc-editor.org/rfc/rfc9110#POST

    Args:
        data: Incoming HTTP request details.
    """
    print(data.method)  # "POST"
    print(data.url)  # Reference: https://pkg.go.dev/net/url#URL
    # TODO: print(data.url_string)

    for key, value in data.header.items():  # TODO: Rename to "headers".
        print("Request header: %s = %s" % (key, value))

    print(data.body)
    for kv in data.body.split("&"):
        key, value = kv.split("=")
        print("Request body: %s = %s" % (key, value))

    # TODO: body_form
    # TODO: body_json

    post_echo_form()
    # TODO: post_json()
    # TODO: post_error()

def post_echo_form():
    """https://www.rfc-editor.org/rfc/rfc9110#POST

    https://httpbin.org/#/HTTP_Methods/post_post
    """

    # Other optional dictionary arguments: headers, params.
    # Alternative body arguments: raw_body (string), or json_body (struct).
    # TODO: Optional content-type argument: form_encoding (string).
    # TODO: form = {"key1": "value1", "key2": "value2"}
    resp = http.post(HTTPBIN_BASE_URL + "/post")  # , form_body = form)

    print(resp.url)  # HTTPBIN_BASE_URL + "/post"
    print(resp.status_code)  # 200

    for key, value in resp.headers.items():
        print("Response header: %s = %s" % (key, value))

    print(resp.body)  # "{\n  \"args\": {}, ... }\n"

    # Note: "form" is expected to exist because it's a part of httpbin's
    # echo reponse body, there is no standard structure in "resp.body_json".
    # Also, if "form" is empty in httpbin's JSON response, then it won't
    # be in "resp.body_json" at all. "getattr()" handles this possibility
    # safely, compared to direct access like "resp.body_json.form.key1".
    # TODO: Is it an AK bug that we discard empty "form" in "resp.body_json"?
    form = getattr(resp.body_json, "form", struct(key1 = "?", key2 = "?"))
    print(form.key1)  # "value1"
    print(form.key2)  # "value2"
