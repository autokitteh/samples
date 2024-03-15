"""Minimal handler for incoming HTTP GET requests."""

def on_http_get(data):
    print("received a %s request" % data.method)
