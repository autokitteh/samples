"""Long-running handler for incoming HTTP GET requests."""

FIVE_SECONDS = 5

def on_http_get(data):
    for i in range(50):
        print("Loop iteration: %d of 50" % (i + 1))
        sleep(FIVE_SECONDS)

    print("Finished processing %s request" % data.method)
