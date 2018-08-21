#!/usr/bin/python3
# encoding: utf-8 
# @author  : zza
# @Email   : 740713651@qq.com
# @Time    : 2018/8/10 0010
import os

from appdirs import AppDirs

# provider = "http://192.168.12.232:58858"
provider = "http://testnet.usc.ulord.one:58858"
# provider = "https://rinkeby.infura.io/v3/7226f0ad456a4f1189fee961011684ac"
USH_TOKEN_ADDRESS = '0xa0544b7124c36d50f2580a67750f10cd5a16056c'
CENTER_PUBLISH_ADDRESS = '0x300d7fd299d1994b0c9da55c64f78fc9fe32c301'
BLOCK_GAS_LIMIT = 6800000
GAS_LIMIT = 6800000,
USER_DATA_DIR = AppDirs("UlordPySdk", "").user_data_dir
CURR_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sols")
print(USER_DATA_DIR)
