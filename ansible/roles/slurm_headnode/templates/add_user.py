#!/home/ubuntu/bin/.venv/bin/python3
from argparse import ArgumentParser
from getpass import getpass
from grp import getgrnam
from logging import getLogger
from os import environ
from pwd import getpwnam
import secrets
import subprocess

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
LDAP_SERVER_ADDRESS = '{{ ldap.host }}'
LDAP_USER_BASE = 'cn={username},ou=users,{{ dcs }}'

# SLURM configuration
SLURM_DEFAULT_ACCOUNT = 'training'



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


def get_users_from_ldap(ldap_connection: Connection, organizational_unit: str | None = None) -> list[Entry]:
    if not organizational_unit:
        ldap_connection.search(
            search_base=LDAP_SEARCH_BASE,
            search_filter=f'(objectclass=posixAccount)',
            attributes=ALL_ATTRIBUTES,
        )
        return ldap_connection.entries[:]
    ldap_connection.search(
        search_base=f'ou={organizational_unit},{LDAP_SEARCH_BASE}',
        search_filter=f'(objectclass=posixAccount)',
        attributes=ALL_ATTRIBUTES,
    )
    return ldap_connection.entries[:]

def get_next_uid(ldap_connection: Connection, min_allowed: int = 10000, max_allowed: int = 20000) -> int:
    all_uids = [user.uidNumber.value for user in get_users_from_ldap(ldap_connection)]
    user_uids = [uid for uid in all_uids if min_allowed <= uid <= max_allowed]
    uid = min_allowed if not user_uids else max(user_uids) + 1
    assert min_allowed <= uid <= max_allowed
    return uid


def user_exists(connection: Connection, username: str) -> bool:
    """Check if a user already exists in LDAP."""
    user_dn = LDAP_USER_BASE.format(username=username)
    connection.search(
        search_base=user_dn,
        search_filter='(objectClass=posixAccount)',
        attributes=ALL_ATTRIBUTES,
    )
    return len(connection.entries) > 0


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


def add_user_to_sudo(username: str):
    """Add user to admin group for passwordless sudo privileges."""
    try:
        # Add user to admin group (configured with NOPASSWD in sudoers)
        cmd = ['sudo', 'usermod', '-a', '-G', 'admin', username]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        logger.info(f'Successfully added {username} to admin group (passwordless sudo)')
        return True
        
    except subprocess.CalledProcessError as e:
        logger.error(f'Failed to add {username} to admin group: {e.stderr}')
        return False
    except Exception as e:
        logger.error(f'Unexpected error adding {username} to admin group: {str(e)}')
        return False


def create_user_directories(username: str):
    """Create user directories in /scratch and /data with proper ownership and permissions."""
    try:
        # Get the training group ID
        training_gid = getgrnam('training').gr_gid
        # Get user UID
        user_uid = getpwnam(username).pw_uid

        # Create /scratch/USERNAME with sudo
        scratch_dir = f'/scratch/{username}'
        mkdir_cmd = ['sudo', 'mkdir', '-p', scratch_dir]
        subprocess.run(mkdir_cmd, capture_output=True, text=True, check=True)

        # Set ownership and permissions on /scratch/USERNAME with sudo
        chown_cmd = ['sudo', 'chown', f'{user_uid}:{training_gid}', scratch_dir]
        subprocess.run(chown_cmd, capture_output=True, text=True, check=True)

        chmod_cmd = ['sudo', 'chmod', '700', scratch_dir]
        subprocess.run(chmod_cmd, capture_output=True, text=True, check=True)

        logger.info(f'Created {scratch_dir} with ownership {username}:training and permissions u=rwx,go=')

        # Create /data/USERNAME with sudo
        data_dir = f'/data/{username}'
        mkdir_cmd = ['sudo', 'mkdir', '-p', data_dir]
        subprocess.run(mkdir_cmd, capture_output=True, text=True, check=True)

        # Set ownership and permissions on /data/USERNAME with sudo
        chown_cmd = ['sudo', 'chown', f'{user_uid}:{training_gid}', data_dir]
        subprocess.run(chown_cmd, capture_output=True, text=True, check=True)

        chmod_cmd = ['sudo', 'chmod', '700', data_dir]
        subprocess.run(chmod_cmd, capture_output=True, text=True, check=True)

        logger.info(f'Created {data_dir} with ownership {username}:training and permissions u=rwx,go=')

        return True

    except KeyError as e:
        logger.error(f'Failed to create directories for {username}: {e} (user or group not found)')
        return False
    except subprocess.CalledProcessError as e:
        logger.error(f'Failed to create directories for {username}: {e.stderr}')
        return False
    except Exception as e:
        logger.error(f'Unexpected error creating directories for {username}: {str(e)}')
        return False


def add_user_to_slurm(username: str, account: str = SLURM_DEFAULT_ACCOUNT, admin: bool = False):
    """Add user to SLURM accounting system."""
    try:
        # Check if user already exists in SLURM
        check_cmd = ['sacctmgr', 'show', 'user', username, '--parsable2']
        result = subprocess.run(check_cmd, capture_output=True, text=True, check=False)
        
        if result.returncode == 0 and username in result.stdout:
            logger.info(f'User {username} already exists in SLURM')
            return True
            
        # Create user in SLURM
        create_cmd = ['sacctmgr', '--immediate', 'create', 'user', f'name={username}', f'DefaultAccount={account}']
        result = subprocess.run(create_cmd, capture_output=True, text=True, check=True)
        
        logger.info(f'Successfully added {username} to SLURM account {account}')
        
        # Set admin level if requested
        if admin:
            admin_cmd = ['sacctmgr', '--immediate', 'modify', 'user', 'where', f'name={username}', 'set', 'adminlevel=Admin']
            admin_result = subprocess.run(admin_cmd, capture_output=True, text=True, check=True)
            logger.info(f'Successfully set {username} as SLURM admin')
        
        return True
        
    except subprocess.CalledProcessError as e:
        logger.error(f'Failed to add {username} to SLURM: {e.stderr}')
        return False
    except Exception as e:
        logger.error(f'Unexpected error adding {username} to SLURM: {str(e)}')
        return False


def get_next_bulk_user_number(connection: Connection) -> int:
    """Find the next available user## number by checking existing LDAP users."""
    try:
        # Get all users from LDAP
        all_users = get_users_from_ldap(connection)
        
        # Find all user## patterns and extract numbers
        user_numbers = []
        for user in all_users:
            username = user.uid.value
            if username.startswith('user') and len(username) >= 6:  # user## is at least 6 chars
                try:
                    # Extract the number part (everything after 'user')
                    number_part = username[4:]  # Skip 'user'
                    if number_part.isdigit():
                        user_numbers.append(int(number_part))
                except (ValueError, AttributeError):
                    continue
        
        # Return next available number (highest + 1, or 1 if no users exist)
        return max(user_numbers) + 1 if user_numbers else 1
        
    except Exception as e:
        logger.warning(f'Could not determine next user number, starting from 1: {str(e)}')
        return 1


def create_bulk_users(connection: Connection, user_count: int, make_changes: bool = False):
    """Create bulk users with random passwords, starting from next available user number."""
    
    # Determine starting number based on existing user## accounts in LDAP
    if make_changes:
        start_num = get_next_bulk_user_number(connection)
        logger.info(f'Starting bulk user creation from user{start_num:02d}')
    else:
        # For dry run, still check what number we would start from
        start_num = get_next_bulk_user_number(connection) if connection else 1
        logger.info(f'Would start bulk user creation from user{start_num:02d}')
    
    for i in range(start_num, start_num + user_count):
        username = f"user{i:02d}"
        password = generate_random_password()
        
        # Output username:password to stdout
        print(f"{username}: {password}")
        
        if make_changes:
            logger.debug(f'Creating bulk user {username}')
            uid = get_next_uid(connection)
            create_user(
                connection=connection,
                username=username,
                given_name=username.capitalize(),
                gid_number=20000,
                surname="User",
                uid_number=uid,
                login_shell='/bin/bash',
                ssh_public_key='',  # No SSH key for bulk users
                home_directory=f'/users/{username}',
                user_password=password
            )

            # Add user to SLURM
            add_user_to_slurm(username)
            # Create user directories in /scratch and /data
            create_user_directories(username)
        else:
            logger.warning(f'Would create user {username} with random password (specify --make-changes to create)')


def create_argument_parser() -> ArgumentParser:
    new_parser = ArgumentParser(description='Create new user accounts')
    new_parser.add_argument('--make-changes', dest='make_changes', default=False, action='store_true', help='Actually make changes')
    new_parser.add_argument('-un', '--username', dest='username', help="Username")
    new_parser.add_argument('-n', '--givenname', dest='givenname', help='Given name')
    new_parser.add_argument('-sn', '--surname', dest='surname', help='Surname')
    new_parser.add_argument('-ssh', '--ssh-public-key', dest='ssh_key', help='SSH public key')
    new_parser.add_argument('-p', '--password', dest='password', help='Password (use "RANDOM" for auto-generated password)')
    new_parser.add_argument('--user_count', dest='user_count', type=int, help='Number of users to create (creates user01, user02, etc.)')
    new_parser.add_argument('--admin', dest='is_admin', action='store_true', default=False, help='Grant user admin privileges (sudo access + SLURM admin)')
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

    # Handle bulk user creation
    if args.user_count:
        if args.make_changes:
            connection = get_ldap_connection()
            create_bulk_users(connection, args.user_count, make_changes=True)
        else:
            create_bulk_users(None, args.user_count, make_changes=False)
        return

    # Validate required arguments for single user creation
    if not args.username or not args.givenname or not args.surname:
        logger.error("For single user creation, username, givenname, and surname are required")
        exit(1)

    # Determine password
    if args.password:
        if args.password.upper() == "RANDOM":
            user_password = generate_random_password()
            print(f"Generated password: {user_password}")
        else:
            user_password = args.password
    else:
        user_password = generate_random_password()  # Secure random fallback
        print(f"Generated password: {user_password}")

    # Validate SSH key if provided
    if args.ssh_key:
        try:
            SSHKey(args.ssh_key).parse()
            logger.debug(f'SSH key checked and is valid')
        except InvalidKeyError:
            logger.error(f'Invalid ssh key: {args.ssh_key}. Aborting.')
            exit(1)
    else:
        # No SSH key provided
        args.ssh_key = ''

    # Create single user
    if args.make_changes:
        logger.debug(f'Creating user {args.username}')
        connection = get_ldap_connection()

        # Check if user already exists
        if user_exists(connection, args.username):
            logger.error(f"User '{args.username}' already exists in LDAP")
            exit(1)

        uid = get_next_uid(connection)
        create_user(
            connection=connection,
            username=args.username,
            given_name=args.givenname,
            gid_number=20000,
            surname=args.surname,
            uid_number=uid,
            login_shell='/bin/bash',
            ssh_public_key=args.ssh_key,
            home_directory=f'/users/{args.username}',
            user_password=user_password
        )

        # Add user to SLURM (with admin privileges if requested)
        add_user_to_slurm(args.username, admin=args.is_admin)

        # Create user directories in /scratch and /data
        create_user_directories(args.username)

        # Add sudo privileges if admin requested
        if args.is_admin:
            add_user_to_sudo(args.username)
    else:
        logger.warning('Not creating user. Specify --make-changes to get it done')

if __name__ == "__main__":
    main()
