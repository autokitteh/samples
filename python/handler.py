import json
from datetime import datetime, UTC
from os import getenv
from pathlib import Path

from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build

# TODO: Change to your spreadsheet ID
spreadsheet_id = '1JW_WmNcuGlLnRPlt-kvjdX0flM3l7ScnDKAIkGJ3NYE'
creds_file = 'credentials.json'
scopes = [
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/spreadsheets',
]


def on_event(event):
    request = json.loads(event.data.body)
    distance = request.get('distance')
    if not distance:
        raise ValueError(f'distance missing from {event!r}')

    date = request.get('date') or datetime.now(UTC).strftime('%Y-%m-%d')
    day_of_year = datetime.strptime(date, '%Y-%m-%d').timetuple().tm_yday
    row = day_of_year + 1  # Skip header

    creds = load_creds()
    sheets = build('sheets', 'v4', credentials=creds).spreadsheets()
    cell_range = f'A{row}:B{row}'
    sheets.values().update(
        spreadsheetId=spreadsheet_id,
        range=cell_range,
        valueInputOption='USER_ENTERED',
        body={
            'values': [[date, distance]],
        },
    ).execute()

    print(f'{date} -> {distance}')


def load_creds():
    """Load Google credentials"""
    if not Path(creds_file).exists():
        data = getenv('GOOGLE_CREDS')
        if not data:
            raise RuntimeError('GOOGLE_CREDS is not set')

        with open(creds_file, 'w') as out:
            out.write(data)

    return Credentials.from_service_account_file(creds_file, scopes=scopes)
