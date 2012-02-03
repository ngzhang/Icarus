#!/usr/bin/env python

import json, urllib

API_KEY='http://deepbit.net/api/4edf2d91069172fdae000000_DE38384EE2'
#API_KEY='http://www.abcpool.co/api.php?api_key=06fa7b691f845f76406f37be5254a3216b67392a4ff7252bf6332b09770f252e'

class Deepbit(object):
    @staticmethod
    def get_stats(url):
        try:
            result = json.load(urllib.urlopen(url))
        except:
            # An error occurred; raise an exception
            raise NameError('Could not get the data, sorry. Maybe a non-functional internet connection or wrong API key?')
        return result

try:
    print json.dumps(Deepbit.get_stats(API_KEY), indent=2)
except Exception as e:
    print e
