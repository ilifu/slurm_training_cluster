#!/bin/bash

# init_slurm_accounts.sh
# Initialize SLURM accounting with default training account and ubuntu admin user
# This script should be run as root

set -euo pipefail

ACCOUNT_NAME="training"
ADMIN_USER="ubuntu"

echo "Initializing SLURM accounting..."

# Check if we're running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if sacctmgr is available
if ! command -v sacctmgr &> /dev/null; then
    echo "Error: sacctmgr command not found. Is SLURM installed?"
    exit 1
fi

# Function to run sacctmgr commands with immediate confirmation
run_sacctmgr() {
    local cmd="$1"
    echo "Running: sacctmgr $cmd"
    eval "sacctmgr --immediate $cmd"
}

echo "Creating default training account..."
# Create the training account (ignore if it already exists)
if ! sacctmgr show account "$ACCOUNT_NAME" --parsable2 | grep -q "^$ACCOUNT_NAME"; then
    run_sacctmgr "add account name=$ACCOUNT_NAME description=\"Default training account\""
    echo "✓ Created account: $ACCOUNT_NAME"
else
    echo "✓ Account $ACCOUNT_NAME already exists"
fi

echo "Setting up ubuntu admin user..."
# Create ubuntu user with admin privileges (ignore if already exists)
if ! sacctmgr show user "$ADMIN_USER" --parsable2 | grep -q "^$ADMIN_USER"; then
    run_sacctmgr "create user name=$ADMIN_USER DefaultAccount=$ACCOUNT_NAME"
    echo "✓ Created user: $ADMIN_USER"
else
    echo "✓ User $ADMIN_USER already exists"
fi

# Set ubuntu user as admin
run_sacctmgr "modify user where name=$ADMIN_USER set adminlevel=Admin"
echo "✓ Set $ADMIN_USER as admin"

# Associate ubuntu with training account if not already associated
run_sacctmgr "modify user where name=$ADMIN_USER set DefaultAccount=$ACCOUNT_NAME"
echo "✓ Associated $ADMIN_USER with $ACCOUNT_NAME account"

echo ""
echo "SLURM accounting initialization complete!"
echo "Account: $ACCOUNT_NAME"
echo "Admin user: $ADMIN_USER"
echo ""
echo "You can now add regular users to the '$ACCOUNT_NAME' account using:"
echo "sacctmgr create user name=<username> DefaultAccount=$ACCOUNT_NAME"