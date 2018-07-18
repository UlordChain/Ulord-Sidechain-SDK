# coding=utf-8
# Copyright (c) 2016-2018 The Ulord Core Developers
# @File  : ucwallet-cli.py
# @Author: Ulord_PuJi
# @Date  : 2018/7/13 0013
import sys
import os
import logging
import inspect

import click
from prompt_toolkit import PromptSession
from prompt_toolkit.history import FileHistory  # 历史记录
from prompt_toolkit.auto_suggest import AutoSuggestFromHistory  # 自动联想
from prompt_toolkit.completion import WordCompleter  # 词汇建议

sys.path.insert(0, os.path.dirname(os.getcwd()))
from ucwallet import __version__
from ucwallet.content_contract import ContentContract
from ucwallet.udfs.udfs import UdfsHelper
from ucwallet.version import PACKAGE_ROOT


class UCwallet():
    """ucwallet 添加cli方法"""
    logfile = None
    log = None
    history = None

    def __init__(self,keystorefile, keystore_pwd, **kwargs):
        """init a ucwallet"""
        self.content_contract = ContentContract(
            keystorefile=keystorefile,
            keystore_pwd=keystore_pwd,
            **kwargs
        )
        self.udfs_helper = UdfsHelper()
        self.load()

    def set_private_key(self, keystorefile, keystore_pwd):
        """重新加载私钥文件和密码"""
        return self.content_contract.set_private_key(keystorefile=keystorefile, keystore_pwd=keystore_pwd)

    def transfer_token(self, to_address, value, sum=0):
        """交易token"""
        return self.content_contract.transfer_token(to_address=to_address, value=value, sum=sum)

    def publish_resource(self, udfs_hash, author_address, price, deposit, t=1):
        """发布资源"""
        return self.content_contract.publish_resource(udfs_hash=udfs_hash, author_address=author_address, price=price, deposit=deposit, t=t)

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
        return self.content_contract.get_token_balance(address)

    def transfer_gas(self, to_address, value):
        """交易gas"""
        return self.transfer_gas(to_address=to_address, value=value)

    def _get_commands(self):
        """get current commands"""
        # self.CONTRACT_COMMANDS = [command[0] for command in inspect.getmembers(self.content_contract, predicate=inspect.ismethod) if not command[0].startswith('_')]
        # self.CLI_COMMANDS = [command[0] for command in inspect.getmembers(self, predicate=inspect.ismethod) if not command[0].startswith('_')]
        # self.UDFS_COMMANDS = [command[0] for command in inspect.getmembers(self.udfs_helper, predicate=inspect.ismethod) if not command[0].startswith('_')]
        # self.BASIC_COMMANDS = self.CONTRACT_COMMANDS + self.CLI_COMMANDS + self.UDFS_COMMANDS
        self.BASIC_COMMANDS = [command[0] for command in inspect.getmembers(self, predicate=inspect.ismethod) if not command[0].startswith('_')]

    def load(self, logfile=os.path.join(PACKAGE_ROOT,'ucwallet.log'), history='history.txt'):
        """加载cli一些必要的配置文件"""
        if self.logfile:
            self.logfile =logfile
        else:
            self.logfile = os.path.join(PACKAGE_ROOT,'ucwallet.log')
        self.log = logging.getLogger('ucwallet')
        self.history = history
        # setting log module todo set log max file
        logging.basicConfig(
            level='INFO',
            filename=self.logfile,
            format='[%(asctime)s] %(levelname)-8s %(name)s %(message)s'
        )

        self._get_commands()
        self.COMMANDS = WordCompleter(self.BASIC_COMMANDS)

    def _info(self, info):
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

    # command
    def help(self, *args):
        """打印帮助信息"""
        result = ''
        for command in self.BASIC_COMMANDS:
            method_to_call = getattr(self, command)
            result += command.ljust(20) + "\t" + method_to_call.__doc__ + "\n"
        return result

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
                        # run command
                        method_to_call = getattr(self, commands[0])
                        self._info(method_to_call(*commands[1:]))
                except KeyboardInterrupt:
                    continue
                except EOFError:
                    break
                except Exception as e:
                    print(e)
                    break
        except Exception as e:
            self.log.error("Error do while:{}".format(e))
            self._info('Goodbye!')


@click.command()
@click.help_option('-h', '--help')
@click.version_option(__version__, '-v', '--version', is_flag=True, help="ucwallet版本信息")
@click.option('-logfile',type=click.Path(), help='日志文件位置(全路径)')
@click.option('--keystorefile', type=click.Path(), prompt='私钥文件位置(全路径)', help='私钥文件位置(全路径)')
@click.option('--keystore_pwd', prompt='私钥密码', help='私钥密码')
def cli(keystorefile, keystore_pwd, logfile):
    """ucwallet ---- ulord 侧链内容钱包"""
    #
    # check keystorefile
    if not os.path.isfile(keystorefile):
        click.echo(click.style(
            'error keystorefile.',
            bg='red',
            bold=True
        ))
        sys.exit(-1)
    # 初始化CLI
    ucwallet = UCwallet(keystorefile=keystorefile, keystore_pwd=keystore_pwd)
    ucwallet.load(logfile=logfile)
    ucwallet._run_cli()


if __name__ == '__main__':
    cli()
    # ucwallet = UCwallet(keystorefile=r"E:\ulord\Ulord-Sidechain-SDK-py-\ucwallet\content_contract\resources\keystore\haibo.json", keystore_pwd="12345678")
    # ucwallet._run_cli()