# AI Driven Slack Support

This automation uses a durable function for a slack bot to receive requests for help, as a bot mentions. Once a request for help is received, the subject of the request is inferred using Google's Gemini AI. The appropriate person is mentioned per a predetermined table of expertise that resides in a Google Doc. The person can then `!take` the request and later `!resolve` it. If no one picks up the request for a configurable duration, the automation will remind the person that a request is pending.

For example, given this expertise table:

```
   | A       | B         | C
---+---------+-----------+--------------
 1 | Itay    | U12345678 | cats,dogs
 2 | Haim    | U87654321 | russian
```

This would happen:

![demo](./demo.png)

# Deploy

Requirements:

- Slack integration is set up. See https://docs.autokitteh.com/tutorials/new_connections/slack.
- Google integration is set up. See TODO.

First, apply the manifest:

```
$ ak manifest apply autokitteh.yaml
```

Then, initialize the Google and Slack connections. This will authenticate them to the desired Slack workspace and Google account.

```
$ ak connection init slack_support/myslack
$ ak connection init slack_support/mygsheets
```

Now acquire a Gemini API key from Google. Go to https://ai.google.dev/gemini-api/docs/api-key and follow the instructions.
Set the variable in autokitteh:

```
$ ak env set --env slack_support/default --secret GEMINI_API_KEY <api-key>
```

Next, create your Google Sheet containing the schedule, it should look like this:

```
   | A       | B         | C
---+---------+-----------+--------------
 1 | Gizmo   | U12345678 | topic1,topic2
 2 | George  | U87654321 | topic3
```

Set the sheet ID in the autokitteh environment:

```
$ ak env set --env slack_support/default DIRECTORY_GOOGLE_SHEET_ID <google-sheet-id>
```

Now, you are ready to roll. Deploy your project:

```
$ ak deploy --project slack_support --dir .
```
