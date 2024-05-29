"""This program queries a server and posts a message to a Slack channel.

An HTTP GET request triggers this program to query a server for a list 
of nodes. It then posts a message to a Slack channel when nodes are 
added or removed.

Starlark is a dialect of Python (see https://bazel.build/rules/language).
"""

load("@http", "http_no_auth")
load("@slack", "my_slack")
load("env", "SLEEP_SECONDS","SLACK_CHANNEL", "URL")

def on_http_get():
    all_nodes = []
    while True:
        all_nodes, new_nodes, removed_nodes = check_node_state(all_nodes)
        if new_nodes:
            my_slack.chat_post_message(SLACK_CHANNEL, "New nodes: " + str(new_nodes))
        if removed_nodes:
            my_slack.chat_post_message(SLACK_CHANNEL, "Removed nodes: " + str(removed_nodes))

        sleep(SLEEP_SECONDS)

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

def get_node_list():
    node_ids = []
    next_token = None
    while True:
        url = URL
        if next_token:
            url += "?next_token=" + next_token
        response = http_no_auth.get(url)

        if response.status_code >= 400:
            print("Error: ", response.status)
            return node_ids

        parsed_data = response.body.json()
        for node in parsed_data["Nodes"]:
            node_ids.append(node["Info"]["NodeID"])
        next_token = parsed_data.get("NextToken")
        if not next_token:
            return node_ids
