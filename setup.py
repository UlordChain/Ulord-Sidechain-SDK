# coding=utf-8
# Copyright (c) 2016-2018 The Ulord Core Developers
# @File  : setup.py
# @Author: Ulord_PuJi
# @Date  : 2018/7/13 0013
import os
from setuptools import setup, find_packages

requires = [

]

base_dir = os.path.abspath(os.path.dirname(__file__))
# Get the long description from the README file
with open(os.path.join(base_dir, 'readme.md'), 'rb') as f:
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
            'ucwallet = ucwallet.uwallet-cli:cli'
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
