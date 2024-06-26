import json
import sqlite3
import xml.etree.ElementTree as xml
from contextlib import closing
from io import BytesIO
from os import getenv
from pathlib import Path

import autokitteh
import boto3

with open('insert.sql') as fp:
    insert_sql = fp.read()

worflow_dir = Path(__file__).absolute().parent
default_dsn = worflow_dir / 'hikes.db'


# Connection secrets
ACCESS_KEY = getenv('aws__AccessKeyID')
SECRET_KEY = getenv('aws__SecretKey')
# vars secret
DB_DSN = getenv('DB_DSN')


def on_new_s3_object(event):
    sns_event = json.loads(event.data.body)
    # sns events encodes the `Message` field in JSON
    s3_event = json.loads(sns_event['Message'])
    for record in s3_event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        print(f'getting {bucket}/{key}')
        data = get_s3_object(bucket, key)
        records = parse_gpx(key, data)
        count = insert_records(DB_DSN, records)
        print(f'inserted {count} records')


@autokitteh.activity
def get_s3_object(bucket, key):
    s3_client = boto3.client(
        's3',
        aws_access_key_id=ACCESS_KEY,
        aws_secret_access_key=SECRET_KEY,
    )
    response = s3_client.get_object(Bucket=bucket, Key=key)
    return response['Body'].read().decode('utf-8')


@autokitteh.activity
def insert_records(db_dsn, records):
    with closing(sqlite3.connect(db_dsn)) as conn, conn:
        cur = conn.executemany(insert_sql, records)
    return cur.rowcount


trkpt_tag = '{http://www.topografix.com/GPX/1/1}trkpt'


def parse_gpx(track_id, data):
    io = BytesIO(data)
    root = xml.parse(io).getroot()
    for i, elem in enumerate(root.findall('.//' + trkpt_tag)):
        yield {
            'track_id': track_id,
            'n': i,
            'lat': float(elem.get('lat')),
            'lng': float(elem.get('lon')),
            'height': float(elem.findtext('.//')),
        }
