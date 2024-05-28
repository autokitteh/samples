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

- [Enable Google Sheets API](https://console.cloud.google.com/apis/enableflow?apiid=sheets.googleapis.com)
- [Create a service account key](https://cloud.google.com/iam/docs/keys-create-delete#creating) and download it to `/tmp/credentials.json`
- Add `GOOGLE_CREDS` secret
    - `ak var set --secret --env walking/default GOOGLE_CREDS < credentials.json`
- Update `sheet_id` in `walking.py` with your sheet ID
    - If the sheet URL is `https://docs.google.com/spreadsheets/d/1JW_WmNcuGlLnRPlt-kvjdX0flM3l7ScnDKAIkGJ3NYE/edit` then the ID is `1JW_WmNcuGlLnRPlt-kvjdX0flM3l7ScnDKAIkGJ3NYE`
