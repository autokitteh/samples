"""User-related helper functions across GitHub and Slack."""

load("@redis", "redis")
load("@github", "github")
load("@slack", "slack")
load("debug.star", "debug")

# Optimization: cache user lookup results for a day, to
# reduce the amount of API calls, especially to Slack.
_USER_CACHE_TTL = "24h"

def email_to_slack_user_id(email):
    """Convert an email address into a Slack user ID.

    Args:
        email: Email address.

    Returns:
        Slack user ID, or "" if not found.
    """

    # See: https://api.slack.com/methods/users.lookupByEmail
    resp = slack.users_lookup_by_email(email)
    if resp.ok:
        return resp.user.id
    else:
        debug("Look-up Slack user by email %s: `%s`" % (email, resp.error))
        return ""

def github_pr_participants(pr):
    """Return all the participants in the given GitHub pull request.

    Args:
        pr: GitHub pull request data.

    Returns:
        List of usernames (author/reviewers/assignees),
        guaranteed to be sorted and without repetitions.
    """
    usernames = []

    # Author.
    if pr.user.type == "User":
        usernames.append(pr.user.login)

    # Specific reviewers (not reviewing teams) + assignees.
    for user in pr.requested_reviewers + pr.assignees:
        if user.type == "User" and user.login not in usernames:
            usernames.append(user.login)

    return sorted(usernames)

def github_username_to_slack_user_id(username):
    """Convert a GitHub username into a Slack user ID.

    This function tries to match the email address first, and then
    falls back to matching the user's full name (case-insensitive).

    This function also caches successful results for a day,
    to reduce the amount of API calls, especially to Slack.

    Args:
        username: GitHub username.

    Returns:
        Slack user ID, or "" if not found.
    """

    # Optimization: if we already have it cached, return it.
    slack_id = redis.get("github_user:" + username)
    if slack_id:
        # Optimization: extend the TTL after a successful cache hit.
        redis.expire("github_user:" + username, _USER_CACHE_TTL)
        return slack_id
    if slack_id == "external user":
        # Note: don't extend the TTL for external-user cache hits,
        # in order to reevaluate them on a daily basis.
        return ""

    # See: https://docs.github.com/en/rest/users#get-a-user
    resp = github.get_user(username)

    # Try to match by the email address first.
    if not resp.email:
        link = "<https://github.com/%s|%s>" % ((username,) * 2)
        debug("GitHub user %s: email address not found" % link)
    else:
        slack_id = email_to_slack_user_id(resp.email)
        if slack_id:
            # Optimization: cache successful results for a day.
            redis.set("github_user:" + username, slack_id, _USER_CACHE_TTL)
            return slack_id

    # Otherwise, try to match by the user's full name.
    gh_full_name = getattr(resp, "name", "")  # May be None.
    gh_full_name = gh_full_name.lower()
    for user in _slack_users():
        slack_names = (
            user.profile.real_name.lower(),
            user.profile.real_name_normalized.lower(),
        )
        if gh_full_name in slack_names:
            # Optimization: cache successful results for a day.
            redis.set("github_user:" + username, user.id, _USER_CACHE_TTL)
            return user.id

    link = "<https://github.com/%s|%s>" % ((username,) * 2)
    debug("GitHub user %s: email & name not found in Slack" % link)

    # Optimization: cache unsuccessful results too (i.e. external users).
    redis.set("github_user:" + username, "external user", _USER_CACHE_TTL)
    return ""

def resolve_github_user(github_user):
    """Convert a GitHub username to a linkified user reference in Slack.

    Args:
        github_user: GitHub user object.

    Returns:
        Slack user reference, or GitHub profile link.
        Used for mentioning users in Slack messages.
    """
    id = github_username_to_slack_user_id(github_user.login)
    if id:
        # Mention the user by their Slack ID, if possible.
        return "<@%s>" % id
    else:
        # Otherwise, fall-back to their GitHub profile link.
        return "<%s|%s>" % (github_user.htmlurl, github_user.login)

def _slack_users(cursor = ""):
    """Return a list of all Slack users in the workspace.

    This function uses recursion for pagination because
    Starlark doesn't officially support the "while" statement
    (even though autokitteh does, with starlark-go).

    Args:
        cursor: Optional, for pagination (initial value must be "").

    Returns:
        List of all Slack users in the workspace.
    """

    # See: https://api.slack.com/methods/users.list
    resp = slack.users_list(cursor, limit = 100)
    if resp.ok:
        users = resp.members
        if resp.response_metadata.next_cursor:
            users += _slack_users(resp.response_metadata.next_cursor)
        return users
    else:
        debug('List Slack users (cursor `"%s"`): `%s`' % (cursor, resp.error))
        return []
