# Room Reservarion

In our organization, we manage meeting rooms as resources in Google Calendar:

- Each meeting room is represented by an email account
- To reserve a room for a meeting, users can add it to the invite

While users can reserve rooms directly from the calendar, we wanted to add a
Slack interface to make it even quicker to reserve a room for an immediate
meeting within the next half hour.

We configured three slash commands in Slack:

- `/whatsfree` - list all the available rooms for the next hour
- `/roomstatus <room>` - show the status of a specific room right now
- `/reserveroom <room> <title>` - reserve a specific room

You can extend this project to add participants, set the time, etc.

## Configuration

Each meeting room is represented by an email account.

The list of available meeting rooms is stored in a Google Sheet as a single
column of room email addresses:

|     | A                   |
| --- | ------------------- |
| 1   | `room1@example.com` |
| 2   | `room2@example.com` |
| 3   | `room3@example.com` |

You can extend this project to add another column for user-friendly aliases.

## AutoKitteh Integrations

Google Calendar, Google Sheets, Slack