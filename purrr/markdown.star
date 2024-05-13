"""Markdown-related helper functions across GitHub and Slack."""

load("user_helpers.star", "resolve_github_user")

def github_markdown_to_slack(text, pr_url):
    """Convert GitHub markdown text to Slack markdown text.

    References:
    - https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax
    - https://api.slack.com/reference/surfaces/formatting
    - https://qri.io/docs/reference/starlark-packages/re

    Args:
        text: Text body, possibly containing GitHub markdown.
        pr_url: URL of the PR we're working on, used to convert
            other PR references in the text ("#123") to links.

    Returns:
        Slack markdown text.
    """

    # Split into lines (Qri's "re" module doesn't support the MULTILINE flag).
    lines = text.replace("\r", "").split("\n")

    # Header lines --> bold lines.
    lines = [re.sub(r"^#+\s+(.+)", "**$1**", line) for line in lines]

    # Lists: "-" --> "•" and "◦".
    lines = [re.sub(r"^- ", "  •  ", line) for line in lines]
    lines = [re.sub(r"^  - ", r"          ◦   ", line) for line in lines]
    text = "\n".join(lines)

    # Links: "[text](url)" --> "<url|text>".
    # Images: "![text](url)" --> "Image: <url|text>".
    text = re.sub(r"\[(.*?)\]\((.*?)\)", "<$2|$1>", text)
    text = re.sub(r"!<(.*?)>", "Image: <$1>", text)

    # "@..." --> "<@U...>" or "<https://github.com/...|...>".
    # TODO: "https://github.com/" doesn't support GitHub Enterprise.
    for github_user in re.findall(r"@[\w-]+", text):
        profile_link = "https://github.com/" + github_user[1:]
        user_obj = struct(login = github_user[1:], htmlurl = profile_link)
        slack_user = resolve_github_user(user_obj)
        text = text.replace(github_user, slack_user)

    # "#123" --> "<PR URL|#123>".
    url_base = re.sub(r"/pull/\d+$", "/pull", pr_url)
    text = re.sub(r"#(\d+)", "<%s/$1|#$1>" % url_base, text)

    # Bold and nested italic text: "***" --> "**_".
    text = re.sub(r"\*\*\*(.+?)\*\*\*", "**_${1}_**", text)

    # Italic text: "*" --> "_".
    text = re.sub(r"(^|[^*])\*([^*]+?)\*", "${1}_${2}_", text)

    # Bold text: "**" or "__" --> "*".
    text = re.sub(r"\*\*(.+?)\*\*", "*$1*", text)
    text = re.sub(r"__(.+?)__", "*$1*", text)

    return text

def slack_markdown_to_github(text):
    """Convert Slack markdown text to GitHub markdown text.

    References:
    - https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax
    - https://api.slack.com/reference/surfaces/formatting
    - https://qri.io/docs/reference/starlark-packages/re

    Args:
        text: Text body, possibly containing Slack markdown.

    Returns:
        GitHub markdown text.
    """

    # Bold text: "*" --> "**".
    text = re.sub(r"\*(.+?)\*", "**$1**", text)

    # Links: "<url|text>" --> "[text](url)".
    text = re.sub(r"<(.*?)\|(.*?)>", "[$2]($1)", text)

    # Channels: "<#...|name>" --> "[name](#...)" -->
    # "[#name](https://slack.com/app_redirect?channel=...)"
    # (see https://api.slack.com/reference/deep-linking).
    text = re.sub(r"\[(.*?)\]\(#(.*?)\)", "[#$1](https://slack.com/app_redirect?channel=$2)", text)

    # TODO: Users: "<@U...>" --> "@github-user".

    # TODO: Multiline code blocks: ```aaa\nbbb``` --> ```\naaa\nbbb\n```

    # TODO: Quoted text not working?

    return text
