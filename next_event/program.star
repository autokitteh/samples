def on_http_get():
    print("got meow, waiting for a woof")

    s = subscribe("myhttp", "data.url.path == '/woof'")
    next = next_event(s)

    print("got woof: " + next['body'].text())
