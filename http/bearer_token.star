"""This entry-point function demonstrates HTTP OAuth with a bearer token.

See: https://datatracker.ietf.org/doc/html/rfc6750

To trigger this, send an HTTP GET request with this command:

    curl -v "http://localhost:9980/http/http_sample/bearer/{token}"

The trigger is defined in the "autokitteh.yaml" manifest file.

The "{token}" substring overrides the autokitteh connection's
bearer token in the second HTTP request.

To see the results (i.e. the workflow's print messages), run this command:

    ak session log --prints-only
"""

load("@http", "http_with_bearer_token")
load("env", "HTTPBIN_BASE_URL")  # Set in "autokitteh.yaml".

def on_http_get_with_bearer_token(data):
    """https://www.rfc-editor.org/rfc/rfc9110#GET

    Args:
        data: Incoming HTTP request details.
    """
    print(data.path)  # "bearer/token}"
    print(data.params)  #  {"token": "..."}

    url = HTTPBIN_BASE_URL + "/bearer"

    # Example 1: use the autokitteh connection's secret credentials.
    resp = http_with_bearer_token.get(url)
    print_details(resp)

    # Example 2: override the autokitteh connection's credentials.
    headers = {"Authorization": "Bearer " + data.params["token"]}
    resp = http_with_bearer_token.get(url, headers = headers)
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
