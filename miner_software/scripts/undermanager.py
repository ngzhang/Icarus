#!/usr/bin/env python

import json, urllib
from optparse import OptionParser

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
    parser = OptionParser()
    parser.add_option("-a",
                      "--api-key",
                      dest="api",
                      default="",
                      help="JSON API key")

    (options, args) = parser.parse_args()

    print json.dumps(Deepbit.get_stats(options.api), indent=2)
except Exception as e:
    print e
