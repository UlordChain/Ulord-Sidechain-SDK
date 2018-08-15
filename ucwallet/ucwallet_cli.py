# coding=utf-8
# Copyright (c) 2016-2018 The Ulord Core Developers
# @File  : ucwallet_cli.py
# @Author: Ulord_PuJi
# @Date  : 2018/7/13 0013
import sys
import os
import logging
import inspect
import traceback

import click
from prompt_toolkit import PromptSession
from prompt_toolkit.history import FileHistory  # 历史记录
from prompt_toolkit.auto_suggest import AutoSuggestFromHistory  # 自动联想
from prompt_toolkit.completion import WordCompleter  # 词汇建议

from deploy_contract import Deploy

sys.path.insert(0, os.path.dirname(os.getcwd()))
from ucwallet import __version__
from ucwallet.content_contract import ContentContract
from ucwallet.udfs.udfs import Udfs
from ucwallet.version import PACKAGE_ROOT


class UCwallet():
    """ucwallet 添加cli方法"""
    logfile = None
    log = None
    history = None

    def __init__(self, keystore_file, keystore_pwd, **kwargs):
        """init a ucwallet"""
        self.content_contract = ContentContract(
            keystore_file=keystore_file,
            keystore_pwd=keystore_pwd,
            **kwargs
        )
        self.udfs_helper = Udfs()
        self._add_call_function()
        self._load()

    def _add_call_function(self):
        for name, cont in self.content_contract.contract.items():
            self.__setattr__(name, self._contract)

    def _get_commands(self):
        """get current commands"""
        basic_commands = [command[0] for command in inspect.getmembers(self, predicate=inspect.ismethod) if
                          not command[0].startswith('_')]
        for name, cont in self.content_contract.contract.items():
            func_names = list(cont.abi.keys())
            basic_commands.extend(func_names)
        # 去重
        self.BASIC_COMMANDS = list(set(basic_commands))

    def _load(self, logfile=os.path.join(PACKAGE_ROOT, 'ucwallet.log')):
        """加载cli一些必要的配置文件"""
        if self.logfile:
            self.logfile = logfile
        else:
            self.logfile = os.path.join(PACKAGE_ROOT, 'ucwallet.log')
        self.log = logging.getLogger('ucwallet')
        # self.history = 'history.txt'
        # setting log module todo set log max file
        logging.basicConfig(
            level='INFO',
            filename=self.logfile,
            format='[%(asctime)s] %(levelname)-8s %(name)s %(message)s'
        )

        self._get_commands()
        self.COMMANDS = WordCompleter(self.BASIC_COMMANDS)

    @staticmethod
    def _info(info):
        """Print a info to stdout.

        The message will be logged in the audit log.

        """
        # if self.logfile:
        #     self.log.info(info)
        click.echo(click.style(
            str(info),
            bg='green',
            bold=True
        ))

    def _error(self, error):
        """Print a error to stdout.

        The message will be logged in the audit log.

        """
        if self.logfile:
            self.log.error(error)
        click.echo(click.style(
            str(error),
            bg='red',
            bold=True
        ))

    def _run_cli(self):
        """交互式shell运行"""
        try:
            session = PromptSession()
            while True:
                # 运行命令
                try:
                    command = session.prompt(
                        message='ucwallet>',
                        # history=FileHistory(self.history), removed in v2.0, auto done.
                        auto_suggest=AutoSuggestFromHistory(),
                        completer=self.COMMANDS,
                    )
                    # command 为用户输入
                    commands = command.split(' ')
                    if commands[0] not in self.BASIC_COMMANDS:
                        self._error('error command {}'.format(commands[0]))
                    else:
                        # For contract save first word
                        self.last_command = commands[0]
                        # run command
                        method_to_call = getattr(self, commands[0])
                        self._info(method_to_call(*commands[1:]))
                except KeyboardInterrupt:
                    continue
                except EOFError:
                    break
                except Exception as e:
                    print(e)
                    # break
        except Exception as e:
            self.log.error("Error do while:{}".format(e))
            self._info('Goodbye!')

    # command
    def help(self, *args):
        """打印帮助信息"""
        result = ''
        for command in self.BASIC_COMMANDS:
            method_to_call = getattr(self, command)
            result += command.ljust(20) + "\t" + method_to_call.__doc__.split(':')[0].strip() + "\n"
        return result

    def login_by_key_file(self, keystorefile, keystore_pwd):
        """重新加载私钥文件和密码"""
        return self.content_contract.set_account_from_wallet(wallet_file=keystorefile, wallet_password=keystore_pwd)

    def login_by_private_key(self, key, wallet_password=None):
        return self.content_contract.set_account_from_privatekey(key, wallet_password)

    def transfer_token(self, to_address, value):
        """交易token"""
        return self.contract("Token", "transfer", to_address, value)

    def publish_resource(self, udfs_hash, author_address, price, deposit, t=1):
        """发布资源"""
        return self.contract("CenterPublish", "createClaim", udfs_hash, author_address, price, deposit, t)

    def transfer_tokens(self, addresses, qualitys):
        """多地址结算"""
        addresses = addresses.split(',')
        return self.content_contract.transfer_tokens(addresses=addresses, qualitys=qualitys)

    def get_for_receipt(self, tx_hash):
        """获取交易回执"""
        return self.content_contract.get_for_receipt(tx_hash=tx_hash)

    def get_gas_balance(self):
        """获取侧链余额"""
        return self.content_contract.get_gas_balance()

    def get_token_balance(self, address=None):
        """获取token余额"""
        return self.contract("Token", "balanceOf", address)

    def transfer_gas(self, to_address, value):
        """交易gas"""
        return self.content_contract.transfer_gas(to_address=to_address, value=value)

    def upload(self, file_path):
        """
        上传文件获取hash值

        :param file_path: 文件路径（绝对路径）
        :return: udfs哈希值
        """
        return self.udfs_helper.upload(file_path)

    def set_udfs_ip(self, ip, port):
        """修改udfs的ip"""
        self.udfs_helper._config(host=ip, port=port)
        return "更换成功"

    def exit(self):
        """退出"""
        sys.exit(-1)

    def downloadhash(self, filehash, filepath=None, Debug=False):
        """从udfs上下载文件"""
        return self.udfs_helper.downloadhash(filehash, filepath, Debug)

    def deploy_contract(self):
        """部署 Ushare 合约"""
        d = Deploy(
            config="deploy_contract.json",
            spath="sols",
            privateKey=self.content_contract.account.privateKey,
        )
        d.deploy()
        self.content_contract.reloading_contract()
        return True

    def _contract(self, function, *param):
        """使用合约的方法"""
        return self.contract(self.last_command, function, param)

    def contract(self, contract_name, function, *param):
        """使用合约的方法"""
        return self.content_contract.func_call(contract_name, function, param)

    def creat_wallet(self, passwd):
        return self.content_contract.create(passwd)

    def get_last_info(self):
        """获取上次合约调用的详细信息"""
        return self.content_contract.get_last_call_info()


@click.command()
@click.help_option('-h', '--help')
@click.version_option(__version__, '-v', '--version', is_flag=True, help="ucwallet版本信息")
@click.option('-logfile', type=click.Path(), help='日志文件位置(全路径)')
@click.option('--keystorefile', type=click.Path(), prompt='私钥文件位置(全路径)', help='私钥文件位置(全路径)')
@click.option('--keystore_pwd', prompt='私钥密码', help='私钥密码')
def cli(keystorefile, keystore_pwd, logfile):
    """ucwallet ---- ulord 侧链内容钱包"""
    # check keystorefile
    if not os.path.isfile(keystorefile):
        click.echo(click.style(
            'error keystorefile.',
            bg='red',
            bold=True
        ))
        sys.exit(-1)
    # 初始化CLI
    ucwallet = UCwallet(keystore_file=keystorefile, keystore_pwd=keystore_pwd)
    if logfile:
        ucwallet._load(logfile=logfile)
    ucwallet._run_cli()


if __name__ == '__main__':
    # cli()
    ucwallet = UCwallet(keystore_file=r"./content_contract/resources/keystore/haibo.json", keystore_pwd="12345678")
    ucwallet._run_cli()
