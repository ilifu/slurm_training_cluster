#!/home/ubuntu/bin/.venv/bin/python3
"""Manage LDAP group memberships for HPC cluster."""

from argparse import ArgumentParser
from getpass import getpass
from logging import getLogger
from os import environ

from coloredlogs import install as coloredlogs_install
from ldap3 import (
    ALL_ATTRIBUTES,
    AUTO_BIND_NO_TLS,
    Connection,
    MODIFY_ADD,
    MODIFY_DELETE,
    Server,
)

LDAP_ADMIN = 'cn=admin,{{ dcs }}'
LDAP_PORT = 389
LDAP_SEARCH_BASE = '{{ dcs }}'
LDAP_SERVER_ADDRESS = '{{ ldap.host }}'
LDAP_GROUP_BASE = 'cn={groupname},ou=users,{{ dcs }}'
LDAP_USER_BASE = 'cn={username},ou=users,{{ dcs }}'

logger = getLogger()


def get_ldap_connection(
        ldap_admin: str = LDAP_ADMIN,
        ldap_server_address: str = LDAP_SERVER_ADDRESS,
        ldap_port: int = LDAP_PORT,
) -> Connection:
    """Establish connection to LDAP server as admin."""
    ldap_password = environ.get('LDAP_ADMIN_PASSWORD', None)
    if not ldap_password:
        ldap_password = getpass(f'Enter password for {ldap_admin} (or set env variable "LDAP_ADMIN_PASSWORD"): ')
    ldap_server = Server(host=ldap_server_address, port=ldap_port)
    logger.debug(f'Creating connection to {ldap_server}')
    conn = Connection(ldap_server, user=ldap_admin, password=ldap_password, auto_bind=AUTO_BIND_NO_TLS)
    logger.debug(f'LDAP identity: {conn.extend.standard.who_am_i()}')
    return conn


def user_exists(ldap_connection: Connection, username: str) -> bool:
    """Check if a user exists in LDAP."""
    user_dn = LDAP_USER_BASE.format(username=username)
    ldap_connection.search(
        search_base=user_dn,
        search_filter='(objectClass=posixAccount)',
        attributes=ALL_ATTRIBUTES,
    )
    return len(ldap_connection.entries) > 0


def group_exists(ldap_connection: Connection, groupname: str) -> bool:
    """Check if a group exists in LDAP."""
    group_dn = LDAP_GROUP_BASE.format(groupname=groupname)
    ldap_connection.search(
        search_base=group_dn,
        search_filter='(objectClass=posixGroup)',
        attributes=ALL_ATTRIBUTES,
    )
    return len(ldap_connection.entries) > 0


def get_group_members(ldap_connection: Connection, groupname: str) -> list[str]:
    """Get list of usernames in a group."""
    group_dn = LDAP_GROUP_BASE.format(groupname=groupname)
    ldap_connection.search(
        search_base=group_dn,
        search_filter='(objectClass=posixGroup)',
        attributes=['memberUid'],
    )
    if not ldap_connection.entries:
        return []

    members = ldap_connection.entries[0].memberUid
    if not members:
        return []
    # memberUid can be a list or single value
    return members if isinstance(members, list) else [members]


def add_user_to_group(ldap_connection: Connection, username: str, groupname: str, make_changes: bool = False) -> bool:
    """Add a user to an LDAP group."""
    if not user_exists(ldap_connection, username):
        logger.error(f"User '{username}' does not exist in LDAP")
        return False

    if not group_exists(ldap_connection, groupname):
        logger.error(f"Group '{groupname}' does not exist in LDAP")
        return False

    group_dn = LDAP_GROUP_BASE.format(groupname=groupname)
    members = get_group_members(ldap_connection, groupname)

    if username in members:
        logger.warning(f"User '{username}' is already a member of group '{groupname}'")
        return True

    if not make_changes:
        logger.info(f"DRY RUN: Would add user '{username}' to group '{groupname}'. Use --make-changes to apply.")
        return True

    success = ldap_connection.modify(
        dn=group_dn,
        changes={'memberUid': (MODIFY_ADD, [username])}
    )

    if success:
        logger.info(f"Added user '{username}' to group '{groupname}'")
    else:
        logger.error(f"Failed to add user '{username}' to group '{groupname}': {ldap_connection.result}")

    return success


def remove_user_from_group(ldap_connection: Connection, username: str, groupname: str, make_changes: bool = False) -> bool:
    """Remove a user from an LDAP group."""
    if not user_exists(ldap_connection, username):
        logger.error(f"User '{username}' does not exist in LDAP")
        return False

    if not group_exists(ldap_connection, groupname):
        logger.error(f"Group '{groupname}' does not exist in LDAP")
        return False

    group_dn = LDAP_GROUP_BASE.format(groupname=groupname)
    members = get_group_members(ldap_connection, groupname)

    if username not in members:
        logger.warning(f"User '{username}' is not a member of group '{groupname}'")
        return True

    if not make_changes:
        logger.info(f"DRY RUN: Would remove user '{username}' from group '{groupname}'. Use --make-changes to apply.")
        return True

    success = ldap_connection.modify(
        dn=group_dn,
        changes={'memberUid': (MODIFY_DELETE, [username])}
    )

    if success:
        logger.info(f"Removed user '{username}' from group '{groupname}'")
    else:
        logger.error(f"Failed to remove user '{username}' from group '{groupname}': {ldap_connection.result}")

    return success


def list_group_members(ldap_connection: Connection, groupname: str) -> bool:
    """List all members of a group."""
    if not group_exists(ldap_connection, groupname):
        logger.error(f"Group '{groupname}' does not exist in LDAP")
        return False

    members = get_group_members(ldap_connection, groupname)

    if not members:
        print(f"Group '{groupname}' has no members")
    else:
        print(f"Members of group '{groupname}':")
        for member in sorted(members):
            print(f"  - {member}")

    return True


def main():
    parser = ArgumentParser(description='Manage LDAP group memberships')
    parser.add_argument('--log-level', default='INFO', choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'])

    subparsers = parser.add_subparsers(dest='command', required=True, help='Command to execute')

    # Add command
    add_parser = subparsers.add_parser('add', help='Add user to group')
    add_parser.add_argument('-u', '--user', dest='username', required=True, help='Username to add')
    add_parser.add_argument('-g', '--group', dest='groupname', required=True, help='Group name')
    add_parser.add_argument('--make-changes', action='store_true', help='Apply changes (default is dry-run)')

    # Remove command
    remove_parser = subparsers.add_parser('remove', help='Remove user from group')
    remove_parser.add_argument('-u', '--user', dest='username', required=True, help='Username to remove')
    remove_parser.add_argument('-g', '--group', dest='groupname', required=True, help='Group name')
    remove_parser.add_argument('--make-changes', action='store_true', help='Apply changes (default is dry-run)')

    # List command
    list_parser = subparsers.add_parser('list', help='List members of a group')
    list_parser.add_argument('-g', '--group', dest='groupname', required=True, help='Group name')

    args = parser.parse_args()

    # Setup logging
    coloredlogs_install(level=args.log_level)

    # Connect to LDAP
    conn = get_ldap_connection()

    try:
        if args.command == 'add':
            success = add_user_to_group(conn, args.username, args.groupname, args.make_changes)
            exit(0 if success else 1)
        elif args.command == 'remove':
            success = remove_user_from_group(conn, args.username, args.groupname, args.make_changes)
            exit(0 if success else 1)
        elif args.command == 'list':
            success = list_group_members(conn, args.groupname)
            exit(0 if success else 1)
    finally:
        conn.unbind()


if __name__ == '__main__':
    main()
