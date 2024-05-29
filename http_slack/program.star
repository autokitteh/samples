""" This program illustrates Autokitteh's usage with Slack and HTTP

This program queries a server for a list of nodes and posts a message to
a Slack channel when new nodes are added or removed.

API details:
- Web API reference: https://api.slack.com/methods
- Events API reference: https://api.slack.com/events?filter=Events

This program also demonstrates using a custom builtin function (sleep)
to sleep for a specified number of seconds.

This program isn't meant to cover all available functions and events.
It merely showcases various illustrative, annotated, reusable examples.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load("@http", "http_no_auth")
load("@slack", "my_slack")
load("env", "SERVER")
load("env", "ENDPOINT")
load("env", "SLACK_CHANNEL")

def get_node_list():
    node_ids = []
    next_token = None
    while True:
        full_endpoint = SERVER + ENDPOINT
        if next_token:
            full_endpoint += "?next_token=" + next_token
        response = http_no_auth.get(full_endpoint)

        if response.status_code >= 400:
            print("Error: ", response.status)
            return node_ids

        parsed_data = response.body.json()
        for node in parsed_data["Nodes"]:
            node_ids.append(node["Info"]["NodeID"])
        next_token = parsed_data.get("NextToken")
        if not next_token:
            return node_ids

def check_node_state(previous_state):
    new_nodes = []
    removed_nodes = []
    all_nodes = get_node_list()

    for node_id in all_nodes:
        if node_id in previous_state:
            previous_state.remove(node_id)
        else:
            new_nodes.append(node_id)

    for node_id in previous_state:
        removed_nodes.append(node_id)

    return all_nodes, new_nodes, removed_nodes

def on_http_get():
    all_nodes = []
    while True:
        all_nodes, new_nodes, removed_nodes = check_node_state(all_nodes)
        if new_nodes:
            my_slack.chat_post_message(SLACK_CHANNEL, "New nodes: " + str(new_nodes))
        if removed_nodes:
            my_slack.chat_post_message(SLACK_CHANNEL, "Removed nodes: " + str(removed_nodes))

        sleep(10)
