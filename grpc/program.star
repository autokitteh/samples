"""This program queries a gRPC server.

An HTTP GET request triggers this program to query a server using gRPC.
In this sample Autokitteh is querying itself for demonstration purposes,
however this is not required. The host can be any gRPC server.

TODO: Link to information on how the gRPC function works and parameters
it takes?

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load("@grpc", "my_grpc")

def on_http_get():
    response = my_grpc.call(
        host="localhost:9980",
        service="autokitteh.projects.v1.ProjectsService",
        method="List"
    )
    print(response)
