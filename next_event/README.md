# next_event

This simple project demonstrate simple use of `subscribe` and `get_event`.

Once deployed, a session is triggered by:

```
$ curl ${AUTOKITTEH_ADDR}/http/next_event/meow
```

That session keeps running until the `/woof` endpoint is accessed:

```
$ curl -X POST http://localhost:9980/http/next_event/woof --data "moo"
```
