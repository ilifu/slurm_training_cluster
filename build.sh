#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
ORANGE='\033[0;33m'

join_arr() {
  local IFS="$1"
  shift
  echo "$*"
}

VARIABLES_FILE=variables.auto.hcl

if [[ ! -f $VARIABLES_FILE ]]; then
  echo -e "Variables file ${VARIABLES_FILE} not found. Use ${VARIABLES_FILE}.template as a template.\nAborting build."
  exit 1
fi

if grep -q "TODO:CONFIGURE_ME" $VARIABLES_FILE; then
  echo -e "${RED}Unconfigured variables found in $VARIABLES_FILE. Please update the values.\n\n$(cat ${VARIABLES_FILE} | grep 'TODO:CONFIGURE_ME')${NC}\n"
  echo -e "${RED}Note the following existing Network and Security Groups:\n$(openstack network list; openstack security group list)${NC}\n"
  echo "${RED}Aborting build.${NC}"
  exit 1
fi

echo "inspecting packer…"

BASE_IMAGE_NAME=$(packer inspect . | grep 'local.base_image_name' | sed 's/.*: "\(.*\)"$/\1/')
SLURM_BASE_IMAGE_NAME=$(packer inspect . | grep 'local.slurm_base_image_name' | sed 's/.*: "\(.*\)"$/\1/')
LDAP_IMAGE_NAME=$(packer inspect . | grep 'local.ldap_image_name' | sed 's/.*: "\(.*\)"$/\1/')
DATABASE_IMAGE_NAME=$(packer inspect . | grep 'local.database_image_name' | sed 's/.*: "\(.*\)"$/\1/')

echo "Done inspecting packer."

echo "" | openstack -q image list &> /dev/null || { echo -e "${RED}Openstack seemingly not connected. Remember to source your '?-openrc.sh' file.\nAborting build.${NC}"; exit 1; }

if openstack image show "${BASE_IMAGE_NAME}" &> /dev/null
then
  echo -e "Openstack image '${GREEN}${BASE_IMAGE_NAME}${NC}' found. Not rebuilding."
else
  echo -e "Openstack image '${ORANGE}${BASE_IMAGE_NAME}${NC}' not found. Creating…"
  packer build -only="step1.openstack.base_image" .
fi

TO_BUILD=()

if openstack image show "${SLURM_BASE_IMAGE_NAME}" &> /dev/null
then
  echo -e "Openstack image '${GREEN}${SLURM_BASE_IMAGE_NAME}${NC}' found. Not rebuilding."
else
  echo -e "Openstack image '${ORANGE}${SLURM_BASE_IMAGE_NAME}${NC}' not found. Adding to build list."
  TO_BUILD+=("step2.openstack.slurm_image")
#  packer build -only="step2.openstack.slurm_image" .
fi

if openstack image show "${LDAP_IMAGE_NAME}" &> /dev/null
then
  echo -e "Openstack image '${GREEN}${LDAP_IMAGE_NAME}${NC}' found. Not rebuilding."
else
  echo -e "Openstack image '${ORANGE}${LDAP_IMAGE_NAME}${NC}' not found. Adding to build list."
  TO_BUILD+=("step3.openstack.ldap_image")
#  packer build -only="step2.openstack.slurm_image" .
fi

if openstack image show "${DATABASE_IMAGE_NAME}" &> /dev/null
then
  echo -e "Openstack image '${GREEN}${DATABASE_IMAGE_NAME}${NC}' found. Not rebuilding."
else
  echo -e "Openstack image '${ORANGE}${DATABASE_IMAGE_NAME}${NC}' not found. Adding to build list."
  TO_BUILD+=("step4.openstack.database_image")
#  packer build -only="step2.openstack.slurm_image" .
fi

joined_steps=$(join_arr , "${TO_BUILD[@]}")
echo -e "Building images: ${ORANGE}${joined_steps}${NC}"
packer build -only="${joined_steps}" .
