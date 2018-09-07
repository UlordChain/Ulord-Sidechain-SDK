# coding=utf-8
# Copyright (c) 2016-2018 The Ulord Core Developers
# @File  : setup.py
# @Author: Ulord_PuJi
# @Date  : 2018/7/13 0013
import os
from setuptools import setup, find_packages

requires = [
    'aniso8601>=3.0.2', 'ApiDoc>=1.4.0', 'appdirs>=1.4.3', 'asn1crypto>=0.24.0', 'attrdict>=2.0.0', 'backcall>=0.1.0',
    'certifi>=2018.4.16', 'cffi>=1.11.5', 'chardet>=3.0.4', 'click>=6.7', 'colorama>=0.3.9', 'cryptography>=2.3.1',
    'cytoolz>=0.9.0.1', 'decorator>=4.3.0', 'eth-abi>=1.1.1', 'eth-account>=0.2.3', 'eth-hash>=0.1.4',
    'eth-keyfile>=0.5.1', 'eth-keys>=0.2.0b3', 'eth-rlp>=0.1.2', 'eth-typing>=1.1.0', 'eth-utils>=1.0.3',
    'Flask>=1.0.2', 'Flask-Cors>=3.0.6', 'flask-doc>=0.2.5', 'Flask-Docs>=0.0.7', 'Flask-RESTful>=0.3.6',
    'Flask-SQLAlchemy>=2.3.2', 'hexbytes>=0.1.0', 'idna>=2.7', 'ipfsapi>=0.4.3', 'ipython>=6.5.0',
    'ipython-genutils>=0.2.0', 'itsdangerous>=0.24', 'jedi>=0.12.1', 'Jinja2>=2.10', 'jsonschema>=2.4.0',
    'lru-dict>=1.1.6', 'lxml>=4.2.4', 'Markdown>=2.6.11', 'MarkupSafe>=1.0', 'parsimonious>=0.8.0', 'parso>=0.3.1',
    'passlib>=1.7.1', 'pickleshare>=0.7.4', 'prompt-toolkit>=2.0.3', 'py-solc>=3.1.0', 'pycparser>=2.18',
    'pycryptodome>=3.6.4', 'pygame>=1.9.4', 'Pygments>=2.2.0', 'PyMySQL>=0.9.2', 'pypiwin32>=223', 'pytz>=2018.5',
    'pywin32>=223', 'PyYAML>=3.11', 'requests>=2.19.1', 'rlp>=1.0.1', 'semantic-version>=2.6.0', 'simplegeneric>=0.8.1',
    'six>=1.11.0', 'SQLAlchemy>=1.2.11', 'toolz>=0.9.0', 'traitlets>=4.3.2', 'ulordapi>=0.0.1', 'urllib3>=1.23',
    'Vector2D>=1.1.0', 'wcwidth>=0.1.7', 'web3>=4.4.1', 'websockets>=5.0.1', 'Werkzeug>=0.14.1'
]

base_dir = os.path.abspath(os.path.dirname(__file__))
# Get the long description from the README file
with open(os.path.join(base_dir, 'README.md'), 'rb') as f:
    long_description = f.read().decode('utf-8')

setup(
    name="ulordapi",
    # version=about['__version__'],
    version='0.0.1',
    packages=find_packages(base_dir),
    author="PuJi",
    author_email="caolinan@ulord.net",
    url="https://github.com/UlordChain/py-ulord-api",
    description="SDK for the Ulord APIs",
    long_description=long_description,
    keywords="ulord api blockchain",
    license='MIT',
    include_package_data=True,
    install_requires=requires,
    zip_safe=False,
    entry_points={
        'console_scripts': [
            'ucwallet = ucwallet.uwallet_cli:cli'
        ]},
    Platform=['win32', 'linux'],
    # python_requires='>=2.6, <3',
    classifiers=[
        # How mature is this project? Common values are
        #   3 - Alpha
        #   4 - Beta
        #   5 - Production/Stable
        'Development Status :: 3 - Alpha',

        # Indicate who your project is intended for
        'Intended Audience :: Developers',
        'Topic :: Software Development :: Build Tools',

        # Pick your license as you wish (should match "license" above)
        'License :: OSI Approved :: MIT License',

        # Specify the Python versions you support here. In particular, ensure
        # that you indicate whether you support Python 2, Python 3 or both.
        'Programming Language :: Python :: both',
    ]
)
