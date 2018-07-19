# coding=utf-8
# Copyright (c) 2016-2018 The Ulord Core Developers
# @File  : udfs.py
# @Author: Ulord_PuJi
# @Date  : 2018/5/18 0018

import sys
import os
import subprocess
import platform
import json
import time
import signal
import logging
import atexit
import copy
from uuid import uuid1

import ipfsapi

from ucwallet.version import PACKAGE_ROOT


class Udfs():
    """udfs helper"""
    def __init__(self, ip='114.67.37.2', host='20418'):
        """init a connector"""
        self.connect = ipfsapi.connect(ip=ip, host=host)
        self.log = logging.getLogger("udfs")

    def _config(self, ip, host):
        """change connect"""
        self.connect = ipfsapi.connect(ip=ip, host=host)

    def upload(self, filepath):
        """upload a file to udfs"""
        if os.path.isfile(filepath):
            return self.connect.add(filepath)
        else:
            self.log.error("Not a file:{}".format(filepath))
            return None


if __name__ == '__main__':
    pass
    # udfshelper = UdfsHelper()
    # udfshelper.upload_file(r'E:\ulord\py-ulord-api\ulordapi\udfs\config.json')
    # with open(r'E:\ulord\py-ulord-api\ulordapi\udfs\config.json', 'r') as target:
    #     udfshelper.upload_file(target)