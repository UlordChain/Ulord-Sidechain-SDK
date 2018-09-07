#!/usr/bin/python3
# encoding: utf-8 
# @author  : zza
# @Email   : 740713651@qq.com
# @Time    : 2018/8/10 0010
import os

from appdirs import AppDirs

# provider = "http://192.168.12.232:58858"
# provider = "http://192.168.12.231:80"
provider = "http://testnet.usc.ulord.one:58858"
# provider = "http://114.67.37.244:58858"
# provider = "https://rinkeby.infura.io/v3/IPYK4Y721E5JAHXZC48BX4VT56EC67XI1N"
# provider = "https://rinkeby.infura.io/v3/7226f0ad456a4f1189fee961011684ac"
BLOCK_GAS_LIMIT = 6800000
GAS_LIMIT = 6800000
USER_DATA_DIR = AppDirs("UlordPySdk", "").user_data_dir
CURR_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sols")

print(USER_DATA_DIR,CURR_DIR)
if os.path.isdir(USER_DATA_DIR) is False:
    import shutil
    shutil.copytree(CURR_DIR, USER_DATA_DIR)