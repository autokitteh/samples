"""Minimal handler for incoming HTTP GET requests."""

def on_http_get(data):
    print("Received a %s request" % data.method)
