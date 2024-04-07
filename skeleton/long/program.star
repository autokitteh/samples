"""Long-running handler for incoming HTTP GET requests."""

FIVE_SECONDS = 5

def on_http_get(data):
    for i in range(100):
        print("Loop iteration: %d of 100" % (i + 1))
        sleep(FIVE_SECONDS)

    print("Finished processing the %s request" % data.method)
