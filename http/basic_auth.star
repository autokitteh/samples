"""This entry-point function demonstrates HTTP basic authentication.

See: https://datatracker.ietf.org/doc/html/rfc7617

To trigger this, send an HTTP GET request with this command:

    curl -v "http://localhost:9980/http/http_sample/basic/{username}/{password}"

The trigger is defined in the "autokitteh.yaml" manifest file.

The "{username}" and "{password}" substrings are the expected credentials.
If the autokitteh connection was created with these credentials, the first
HTTP response will have a status code of 200 OK. Otherwise, it will be 401
Unauthorized.

The second HTTP response will always have a status code of 200 OK, because
the request overrides the autokitteh connection's credentials.

To see the results (i.e. the workflow's print messages), run this command:

    ak session log --prints-only
"""

load("@http", "http_with_basic_auth")
load("env", "HTTPBIN_BASE_URL")  # Set in "autokitteh.yaml".

def on_http_get_with_basic_auth(data):
    """https://www.rfc-editor.org/rfc/rfc9110#GET

    Args:
        data: Incoming HTTP request details.
    """
    print(data.path)  # "basic/{username}/{password}"
    print(data.params)  #  {"username": "...", "password": "..."}

    expected_creds = (data.params["username"], data.params["password"])
    url = HTTPBIN_BASE_URL + "/basic-auth/%s/%s" % expected_creds

    # Example 1: use the autokitteh connection's secret credentials.
    resp = http_with_basic_auth.get(url)
    print_details(resp)

    # Example 2: override the autokitteh connection's credentials.
    override_creds = data.params["username"] + ":" + data.params["password"]
    headers = {"Authorization": "Basic " + base64.encode(override_creds)}
    print(headers)

    resp = http_with_basic_auth.get(url, headers = headers)
    print_details(resp)

def print_details(resp):
    """Prints HTTP response details.

    Args:
        resp: HTTP response object.
    """
    print(resp.url)
    print(resp.status_code)
    print(resp.body.text())

    for key, value in resp.headers.items():
        print("Response header: %s = %s" % (key, value))
