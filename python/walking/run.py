"""Run handler outside of AutoKitteh"""

import handler
from handler_test import AttrDict


date, distance = '2024-01-02', 3.9 
event = AttrDict({
    'data': {
        'body': f'{{"date": "{date}", "distance": {distance}}}'.encode(),
    },
})
handler.on_event(event)
