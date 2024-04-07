"""Minimal handler for incoming HTTP GET requests."""

def on_http_get(data):
    print("Received %s request" % data.method)
