#!/home/ubuntu/bin/.venv/bin/python3
from argparse import ArgumentParser
from getpass import getpass
from logging import getLogger
from os import environ, path, system
from pwd import getpwall

from coloredlogs import install as coloredlogs_install
from ldap3 import (
    ALL_ATTRIBUTES,
    AUTO_BIND_NO_TLS,  # TLS_BEFORE_BIND,
    Connection,
    Entry,
    HASHED_SALTED_SHA,
    MODIFY_ADD,
    MODIFY_DELETE,
    MODIFY_REPLACE,
    Server,
)
from ldap3.utils.hashed import hashed
from sshpubkeys import InvalidKeyError, SSHKey

LDAP_ADMIN = 'cn=admin,{{ dcs }}'
LDAP_PORT = 389
LDAP_SEARCH_BASE = '{{ dcs }}'
LDAP_SERVER_ADDRESS = '{{ ldap_host }}'
LDAP_USER_BASE = 'cn={username},ou=users,{{ dcs }}'


logger = getLogger()

def get_ldap_connection(
        ldap_admin: str = LDAP_ADMIN,
        ldap_server_address: str = LDAP_SERVER_ADDRESS,
        ldap_port: int = LDAP_PORT,
) -> Connection:
    ldap_password = environ.get('LDAP_ADMIN_PASSWORD', None)
    if not ldap_password:
        ldap_password = getpass(f'Enter password for {ldap_admin} (or set env variable "LDAP_ADMIN_PASSWORD"): ')
    ldap_server = Server(host=ldap_server_address, port=ldap_port)
    logger.debug(f'Creating connection to {ldap_server}')
    conn = Connection(ldap_server, user=ldap_admin, password=ldap_password, auto_bind=AUTO_BIND_NO_TLS)
    logger.debug(f'LDAP identity: {conn.extend.standard.who_am_i()}')
    return conn


def get_next_uid(min_allowed: int = 10000, max_allowed: int = 20000) -> int:
    # Get user-id to use
    users = getpwall()
    users = list(map(lambda x: x.pw_uid, users))
    users = list(filter(lambda x: min_allowed <= x <= max_allowed, users))
    if not users:
        return min_allowed
    proposed_uid = max([max(users) + 1, min_allowed])
    assert min_allowed <= proposed_uid <= max_allowed
    return proposed_uid


def create_user(
        connection: Connection,
        username: str,
        given_name: str,
        gid_number: int,
        surname: str,
        uid_number: int,
        login_shell: str,
        ssh_public_key: str,
        home_directory: str,
        user_password: str,
):
    user_detail = {
        'uid': username,
        'givenName': given_name,
        'gidNumber': gid_number,
        'sn': surname,
        'uidNumber': uid_number,
        'loginShell': login_shell,
        'sshPublicKey': ssh_public_key,
        # 'mail': email_address,
        # 'departmentNumber': department_number,
        'homeDirectory': home_directory,
        'userPassword': hashed(HASHED_SALTED_SHA, user_password),
    }
    logger.debug(f'About to create the following user: {user_detail}')
    connection.add(
        dn=LDAP_USER_BASE.format(username=username),
        object_class=['inetOrgPerson', 'posixAccount', 'ldapPublicKey', 'top'],
        attributes=user_detail,
    )
    logger.warning(f'User {username} added with { user_detail }.')


def create_argument_parser() -> ArgumentParser:
    new_parser = ArgumentParser(description='Create new user accounts')
    new_parser.add_argument('--make-changes', dest='make_changes', default=False, action='store_true', help='Actually make changes')
    new_parser.add_argument('-un', '--username', dest='username', required=True, help="Username")
    new_parser.add_argument('-n', '--givenname', dest='givenname', required=True, help='Given name')
    new_parser.add_argument('-sn', '--surname', dest='surname', required=True, help='Surname')
    new_parser.add_argument('-ssh', '--ssh-public-key', dest='ssh_key', required=True, help='SSH public key')
    new_parser.add_argument('--debug', action='store_true', default=False, help='More verbose output')

    new_parser.set_defaults(extra_groups=[],)
    return new_parser


def main():
    parser = create_argument_parser()
    args = parser.parse_args()

    if args.debug:
        coloredlogs_install(level='DEBUG')
    else:
        coloredlogs_install(level='INFO')

    try:
        SSHKey(args.ssh_key).parse()
        logger.debug(f'SSH key checked and is valid')
    except InvalidKeyError:
        logger.error(f'Invalid ssh key: {args.ssh_key}. Aborting.')
        exit(1)

    if args.make_changes:
        logger.debug(f'Creating user {args.username}')
        connection = get_ldap_connection()
        uid = get_next_uid()
        create_user(connection, args.username, args.givenname, 20000, args.surname, uid, '/bin/bash', args.ssh_key, f'/users/{args.username}', 'OkayFixThisSoon')
    else:
        logger.warning('Not creating user. Specify --make-changes to get it done')

if __name__ == "__main__":
    main()


#def create_user(
#        connection: Connection,
#        username: str,
#        given_name: str,
#        gid_number: int,
#        surname: str,
#        uid_number: int,
#        login_shell: str,
#        ssh_public_key: str,
#        home_directory: str,
#        user_password: str,
