#!/home/ubuntu/bin/.venv/bin/python3
from argparse import ArgumentParser
from getpass import getpass
from logging import getLogger
from os import environ
import secrets

from coloredlogs import install as coloredlogs_install
from ldap3 import (
    AUTO_BIND_NO_TLS,
    Connection,
    MODIFY_REPLACE,
    Server,
)
from ldap3.utils.hashed import hashed, HASHED_SALTED_SHA

LDAP_ADMIN = 'cn=admin,{{ dcs }}'
LDAP_PORT = 389
LDAP_SEARCH_BASE = '{{ dcs }}'
LDAP_SERVER_ADDRESS = '{{ ldap.host }}'
LDAP_USER_BASE = 'cn={username},ou=users,{{ dcs }}'


logger = getLogger()


def load_word_list(dictionary_path: str = '/usr/share/dict/american-english') -> list[str]:
    """Load words from dictionary file, filtering for lowercase words without punctuation."""
    try:
        with open(dictionary_path, 'r', encoding='utf-8') as f:
            words = []
            for line in f:
                word = line.strip()
                # Only include words that are lowercase and contain only letters
                if word and word.islower() and word.isalpha():
                    words.append(word)
            return words
    except FileNotFoundError:
        logger.error(f"Dictionary file not found: {dictionary_path}")
        # Fallback to basic word list
        return [
            'able', 'about', 'after', 'again', 'almost', 'alone', 'along', 'already', 'also', 'always',
            'among', 'animal', 'another', 'answer', 'appear', 'around', 'asked', 'away', 'back', 'became',
            'because', 'become', 'been', 'before', 'began', 'begin', 'being', 'below', 'between', 'black',
            'blue', 'book', 'both', 'bring', 'brown', 'build', 'called', 'came', 'cannot', 'carry',
            'change', 'children', 'city', 'close', 'color', 'come', 'could', 'country', 'course', 'cut'
        ]


def generate_random_password() -> str:
    """Generate a random password using 5 English words separated by spaces."""
    word_list = load_word_list()
    if len(word_list) < 5:
        logger.error("Not enough words available for password generation")
        raise RuntimeError("Cannot generate password: not enough words available")
    words = secrets.SystemRandom().choices(word_list, k=5)
    return ' '.join(words)


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


def user_exists(connection: Connection, username: str) -> bool:
    """Check if a user exists in LDAP."""
    try:
        user_dn = LDAP_USER_BASE.format(username=username)
        connection.search(search_base=user_dn, search_filter='(objectClass=*)')
        return len(connection.entries) > 0
    except Exception as e:
        logger.error(f'Error checking if user exists: {str(e)}')
        return False


def update_user_password(
        connection: Connection,
        username: str,
        new_password: str,
        make_changes: bool = False,
) -> bool:
    """Update a user's password in LDAP."""
    user_dn = LDAP_USER_BASE.format(username=username)

    # Check if user exists
    if not user_exists(connection, username):
        logger.error(f'User {username} does not exist in LDAP')
        return False

    # Hash the password
    hashed_password = hashed(HASHED_SALTED_SHA, new_password)

    logger.debug(f'Password hash for {username}: {hashed_password}')

    if make_changes:
        try:
            # Update the password in LDAP
            connection.modify(
                dn=user_dn,
                changes={'userPassword': [(MODIFY_REPLACE, [hashed_password])]}
            )
            if connection.result['result'] == 0:
                logger.warning(f'Successfully updated password for user {username}')
                return True
            else:
                logger.error(f'Failed to update password for {username}: {connection.result}')
                return False
        except Exception as e:
            logger.error(f'Error updating password for {username}: {str(e)}')
            return False
    else:
        logger.warning(f'Would update password for user {username} (specify --make-changes to apply)')
        return True


def create_argument_parser() -> ArgumentParser:
    parser = ArgumentParser(description='Update LDAP user password')
    parser.add_argument('-u', '--username', dest='username', required=True, help='Username to update')
    parser.add_argument('-p', '--password', dest='password', help='New password (use "RANDOM" for auto-generated)')
    parser.add_argument('--random', dest='generate_random', action='store_true', default=False, help='Generate random password')
    parser.add_argument('--make-changes', dest='make_changes', action='store_true', default=False, help='Actually make changes')
    parser.add_argument('--debug', action='store_true', default=False, help='More verbose output')

    return parser


def main():
    parser = create_argument_parser()
    args = parser.parse_args()

    if args.debug:
        coloredlogs_install(level='DEBUG')
    else:
        coloredlogs_install(level='INFO')

    # Determine password
    if args.generate_random or args.password == 'RANDOM':
        new_password = generate_random_password()
        print(f"Generated password: {new_password}")
    elif args.password:
        new_password = args.password
    else:
        # Prompt for password
        new_password = getpass(f'Enter new password for {args.username}: ')
        confirm_password = getpass('Confirm password: ')

        if new_password != confirm_password:
            logger.error('Passwords do not match')
            exit(1)

    # Update password
    if args.make_changes:
        logger.debug(f'Updating password for {args.username}')
        connection = get_ldap_connection()
        success = update_user_password(
            connection=connection,
            username=args.username,
            new_password=new_password,
            make_changes=True
        )
        exit(0 if success else 1)
    else:
        logger.warning(f'Not updating password. Specify --make-changes to apply changes')
        logger.info(f'Would update password for user {args.username}')


if __name__ == "__main__":
    main()