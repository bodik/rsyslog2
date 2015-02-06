#!/usr/bin/python

import json, requests

import sys

import pprint
pp = pprint.PrettyPrinter(indent=4)

def printf(format, *args):
    sys.stdout.write(format % args)

url = 'http://100.64.24.81:39200/_status'

params = dict()

resp = requests.get(url=url, params=params)
data = json.loads(resp.text)


for key in data['indices'].keys():
        printf("%s index.size_in_bytes %s num_doc %d\n", key, data['indices'][key]['index']['size_in_bytes'], data['indices'][key]['docs']['num_docs'])


