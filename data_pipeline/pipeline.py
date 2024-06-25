import json
import xml.etree.ElementTree as xml
from contextlib import closing
from io import BytesIO
from os import getenv

import boto3
import psycopg2

insert_sql = '''
INSERT INTO points
(track_id, lat, lng, height)
VALUES
(%(track_id)s, %(lat)s, %(lng)s, %(height)s)
'''


def on_new_s3_object(event):
    # Connection secrets
    access_key = getenv('aws__AccessKeyID')
    secret_key = getenv('aws__SecretKey')

    # vars secret
    dsn = getenv('DB_DSN')

    client = boto3.client(
        's3',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
    )

    sns_event = json.loads(event.data.body)
    # sns events encodes the `Message` field in JSON
    s3_event = json.loads(sns_event['Message'])

    with psycopg2.connect(dsn) as conn:
        for record in s3_event['Records']:
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']

            response = client.get_object(Bucket=bucket, Key=key)
            data = response['Body'].read().decode('utf-8')
            cur = conn.cursor()
            with cur:
                cur.executemany(insert_sql, parse_gpx(bucket, data))


trkpt_tag = '{http://www.topografix.com/GPX/1/1}trkpt'


def parse_gpx(track_id, data):
    io = BytesIO(data)
    root = xml.parse(io).getroot()
    for elem in root.findall('.//' + trkpt_tag):
        yield {
            'track_id': track_id,
            'lat': float(elem.get('lat')),
            'lng': float(elem.get('lon')),
            'height': float(elem.findtext('.//')),
        }
