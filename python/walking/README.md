# Python + Google Sheets

Say you'd like to keep track of how many miles you walk per day.
This workflow has an HTTP trigger that accepts a payload in the format:

```json
{
    "date": "2024-03-15",
    "distance": 3.7
}
```

It then will update a Google Sheet with these values.

## Setting Up

Make sure that AutoKitteh is running and then:

- [Enable Google Sheets API](https://console.cloud.google.com/apis/enableflow?apiid=sheets.googleapis.com)
- [Create a service account key](https://cloud.google.com/iam/docs/keys-create-delete#creating) and download it to `/tmp/credentials.json`
- Add `GOOGLE_CREDS` secret
    - `ak var set --secret --env walking/default GOOGLE_CREDS < credentials.json`
- Update `sheet_id` in `walking.py` with your sheet ID
    - If the sheet URL is `https://docs.google.com/spreadsheets/d/1JW_WmNcuGlLnRPlt-kvjdX0flM3l7ScnDKAIkGJ3NYE/edit` then the ID is `1JW_WmNcuGlLnRPlt-kvjdX0flM3l7ScnDKAIkGJ3NYE`
- Give the service account (`<name>@<project>.iam.gserviceaccount.com`) edit access to the document.

Now you're ready to deploy:

```shell
ak deploy --manifest ./autokitteh.yaml --file handler.py
```

After the workflow is deployed, you can trigger the workflow with an HTTP call:

```shell
curl -i -X POST -d'{"date": "2024-03-14", "distance": 5.9}' http://localhost:9980/http/walking/
```

You can check the logs with `ak session log`

Head up to your Google Sheet and see the added entry.
