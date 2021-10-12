#!/usr/bin/env python3

from argparse import ArgumentParser
from logging import getLogger

from coloredlogs import install as coloredlogs_install
from coloredlogs.syslog import enable_system_logging
from sshpubkeys import InvalidKeyError, SSHKey

logger = getLogger()


def create_argument_parser() -> ArgumentParser:
    new_parser = ArgumentParser(description='Check SSH key validity')
    new_parser.add_argument('-k', '--ssh-public-key', dest='ssh_key', help='SSH public key')
    new_parser.add_argument('-y', '--yaml', help='yaml file with ssh public keys')
    new_parser.add_argument('--header', help='CSV file\'s column header that has the SSH keys')

    new_parser.add_argument('--debug', action='store_true', default=False, help='More verbose output')

    new_parser.set_defaults(extra_groups=[],)
    return new_parser


def check_key(ssh_key: str):
    try:
        SSHKey(ssh_key).parse()
        logger.debug(f'Key "{ssh_key}" is valid')
        return True
    except InvalidKeyError:
        logger.error(f'Invalid ssh key: {ssh_key}. Aborting.')
        return False


def main():
    parser = create_argument_parser()
    args = parser.parse_args()

    ssh_key = args.ssh_key

    if args.debug:
        coloredlogs_install(level='DEBUG')
    else:
        coloredlogs_install(level='INFO')

    ssh_key = args.ssh_key

    if args.ssh_key:
        key_valid = check_key(ssh_key)
        if key_valid:
            exit(0)
        exit(1)

    if args.file:
        csv_reader = reader(args.file)
        header = next(csv_reader)
        print(header)


if __name__ == "__main__":
    main()

