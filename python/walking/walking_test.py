from unittest.mock import MagicMock

import handler

class AttrDict(dict):
    def __getattr__(self, name):
        try:
            value = self[name]
            if isinstance(value, dict):
                value = AttrDict(value)
            return value
        except KeyError:
            raise AttributeError(name)


def test_handler(monkeypatch):
    mock = MagicMock()
    mock.spreadsheets.return_value = mock
    mock.values.return_value = mock

    monkeypatch.setattr(handler, 'build', lambda *args, **kw: mock)

    date, distance = '2024-03-12', 4.7
    event = AttrDict({
        'data': {
            'body': f'{{"date": "{date}", "distance": {distance}}}'.encode(),
        },
    })
    handler.on_event(event)
    assert mock.update.called
    expected = {
        'spreadsheetId': handler.spreadsheet_id, 
        'range': 'A73:B73', 
        'valueInputOption': 'USER_ENTERED', 
        'body': {
            'values': [['2024-03-12', 4.7]],
        },
    }
    assert mock.update.call_args.kwargs == expected
