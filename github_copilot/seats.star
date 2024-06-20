load("env", "ORG", "IDLE_USAGE_THRESHOLD", "LOGINS")
load("@github", "mygithub")
load("@slack", "myslack")
load("helpers.star", "github_username_to_slack_user_id")

logins = LOGINS.split(",")
idle_usage_threshold = time.parse_duration(IDLE_USAGE_THRESHOLD)

def prune_idle_seats():
    seats = find_idle_seats()
    for seat in seats:
        k = "users/%s/engaged" % seat.assignee.id

        if store.get(k):
            print("already egaged %s" % seat.assignee.login)
            continue
        
        store.set(k, True)

        print("new idle: {}".format(seat))
        start("seats.star:engage_seat", {"seat": seat})
    return seats

def _get_all_seats():
    # TODO: pagination.
    return mygithub.list_copilot_seats(ORG).seats

def find_idle_seats():
    seats = _get_all_seats()

    t, idle_seats = time.now(), []
    for seat in seats:
        if seat.assignee.login not in logins:
            print("skipping %s" % seat.assignee.login)
            continue

        delta = t - seat.last_activity_at
        is_idle = delta >= idle_usage_threshold

        print("{}: {} - {} = {} {} {}".format(
            seat.assignee.login, t, seat.last_activity_at, delta, ">=" if is_idle else "<", idle_usage_threshold
        ))

        if is_idle:
            idle_seats.append(seat)

    return idle_seats

def engage_seat(seat):
    github_login = seat.assignee.login
    slack_id = github_username_to_slack_user_id(github_login, ORG)
    if not slack_id:
        print("No slack user found for github user %s" % github_login)
        return

    mygithub.remove_copilot_users(ORG, [github_user_id])

    myslack.chat_post_message(
        slack_id,
        "You have been removed from the Copilot program due to inactivity. Reply with `reinstate` to resubscribe or `ok` to ignore.",
    )

    s = subscribe('myslack', 'data.type == "message" && data.user == "{}" && data.channel_type == "im"'.format(slack_id))

    say = lambda msg: myslack.chat_post_message(slack_id, msg)

    while True:
        text = next_event(s)["text"]
        if text == 'reinstate':
            break
        elif text == 'ok':
            say("Okey dokey!")
            return
        
        say("???")

    mygithub.add_copilot_users(ORG, [github_login])

    say("You have been reinstated to the Copilot program.")
