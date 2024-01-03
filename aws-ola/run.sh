#!/usr/bin/env bash
#
# This is a script helping with AWS authorization via OneLogin records
#     All public functions are prefixed with "laws"
#     All private functions are prefixed with "_aws_ola_cli_"
#
#-------------------------------------------------------------------#

_DIR="$( dirname $(readlink -f $0) )"

ONELOGIN_AWS_CLI_PATH="$HOME/Library/Application Support/onelogin-aws-cli"
ONELOGIN_AWS_CLI_ENV_VARS_FILE="custom.env"
ONELOGIN_AWS_CLI_KEYCHAIN_PWD_NAME="onelogin"
# Note: non-default loops don't work with OTP MFA, since it cannot re-login
ONELOGIN_AWS_CLI_LOOPS=""
ONELOGIN_AWS_CLI_DEFAULT_LOOPS=1

# auto-import env vars
export $(grep -v '^#' "${_DIR}/${ONELOGIN_AWS_CLI_ENV_VARS_FILE}" | xargs)
for v in 'ONELOGIN_USER' 'ONELOGIN_SUBDOMAIN' 'ONELOGIN_AWS_APP_ID' 'ONELOGIN_AWS_REGION' 'ONELOGIN_OLA_SDK_REGION' 'ONELOGIN_OLA_SDK_CLIENT_ID' 'ONELOGIN_OLA_SDK_CLIENT_SECRET'; do
  if [ -z "${v+1}" ]; then
    echo "ERROR: Missing env variable '${v}'!"
  fi
done

#-------------------------------------------------------------------#
### aliases

alias laws="_aws_ola_cli_login_select"

function laws-current {
  local AWS_STS_IDENTITY="$( aws sts get-caller-identity )"
  local account_id="$( echo "${AWS_STS_IDENTITY}" | jq -r '.Account' )"
  local role="$( echo "${AWS_STS_IDENTITY}" | jq -r '.Arn' | awk -F '/' '{print $2}' )"
  local user="$( echo "${AWS_STS_IDENTITY}" | jq -r '.Arn' | awk -F '/' '{print $3}' )"

  echo "AWS_STS_IDENTITY: ${account_id}-${role} (user ${user})"
  echo "AWS_DEFAULT_PROFILE: ${AWS_DEFAULT_PROFILE}"
  echo "AWS_ACCOUNT_ID: $( echo "${AWS_DEFAULT_PROFILE}" | awk -F '-' '{print $2}' )"
}

# include script with custom aliases, that are handy for your custom Account/Role shortcuts
# check its template for more info
ONELOGIN_AWS_CLI_CUSTOM_ALIASES_SCRIPT="${_DIR}/custom.sh"
if [ -f "${ONELOGIN_AWS_CLI_CUSTOM_ALIASES_SCRIPT}" ]; then . "${ONELOGIN_AWS_CLI_CUSTOM_ALIASES_SCRIPT}"; fi

#-------------------------------------------------------------------#
### main

function _aws_ola_cli_get_keychain_pwd {
  security find-generic-password -a ${USER} -s ${ONELOGIN_AWS_CLI_KEYCHAIN_PWD_NAME} -w
}

# download OneLogin AWS CLI and write properties
function _aws_ola_cli_install {
  mkdir -p "${ONELOGIN_AWS_CLI_PATH}"
  pushd "${ONELOGIN_AWS_CLI_PATH}" > /dev/null
  curl -L -O "https://github.com/onelogin/onelogin-aws-cli-assume-role/raw/master/onelogin-aws-assume-role-cli/dist/onelogin-aws-cli.jar"
  if [ ! -f onelogin.sdk.properties ] ; then
    touch onelogin.sdk.properties
    echo "onelogin.sdk.client_id=${ONELOGIN_OLA_SDK_CLIENT_ID}"
    echo "onelogin.sdk.client_secret=${ONELOGIN_OLA_SDK_CLIENT_SECRET}"
    echo "onelogin.sdk.region=${ONELOGIN_OLA_SDK_REGION}"
  fi
  popd > /dev/null

  # copy configs from templates
  if [ ! -f "${ONELOGIN_AWS_CLI_ENV_VARS_FILE}" ] ; then
    cp "${_DIR}/custom.template.env" "${ONELOGIN_AWS_CLI_ENV_VARS_FILE}"
  fi
  if [ ! -f "${ONELOGIN_AWS_CLI_CUSTOM_ALIASES_SCRIPT}" ] ; then
    cp "${_DIR}/custom.template.sh" "${ONELOGIN_AWS_CLI_CUSTOM_ALIASES_SCRIPT}"
  fi

  # add OneLogin password to keychain (will ask for input, optional step)
  if [ -z "`_aws_ola_cli_get_keychain_pwd 2> /dev/null`" ]; then
    security add-generic-password -a ${USER} -s ${ONELOGIN_AWS_CLI_KEYCHAIN_PWD_NAME} -w
  fi
}
if [ ! -d "${ONELOGIN_AWS_CLI_PATH}" ]; then
  echo "${ONELOGIN_AWS_CLI_PATH} does not exist. Installing it..."
  _aws_ola_cli_install
fi

# OneLogin AWS CLI caller
function _aws_ola_cli_run {
  java -jar "${ONELOGIN_AWS_CLI_PATH}/onelogin-aws-cli.jar" \
    -a ${ONELOGIN_AWS_APP_ID} -d ${ONELOGIN_SUBDOMAIN} \
    --loop ${ONELOGIN_AWS_CLI_LOOPS:-${ONELOGIN_AWS_CLI_DEFAULT_LOOPS}} \
    $@
}

function _aws_ola_cli_login {
  local profile="$1"
  local profile_args=""

  local account_id="$2"
  local role="$3"
  if [ -n "${account_id}" ] && [ -n "${role}" ]; then
    profile_args="-aws-account-id \"${account_id}\" -aws-role-name \"${role}\""
  fi

  # Prevent "You have to log out" error from AWS by forcing a logout first
  ONELOGIN_AWS_LOGOUT=""
  if ! test "`aws sts get-caller-identity --profile "${profile}" 2> /dev/null `" ; then
    ONELOGIN_AWS_LOGOUT="https://signin.aws.amazon.com/oauth?Action=logout&redirect_uri=aws.amazon.com"
    ONELOGIN_PWD="$(_aws_ola_cli_get_keychain_pwd 2>/dev/null)"
    _aws_ola_cli_run -p "${profile}" $(echo "${profile_args}") \
      -username "${ONELOGIN_USER}" ${ONELOGIN_PWD:+"-password ${ONELOGIN_PWD}"} \
      -region "${ONELOGIN_AWS_REGION}"
  fi

  export AWS_DEFAULT_PROFILE="${profile}"
}

# OneLogin AWS CLI login showing the list of available roles
function _aws_ola_cli_login_select {
  local profile="onelogin"
  ONELOGIN_AWS_CLI_LOOPS=""

  _aws_ola_cli_login "${profile}"
}

# OneLogin AWS CLI login with pre-selected profile
function _aws_ola_cli_login_with_profile {
  local profile="$1"
  ONELOGIN_AWS_CLI_LOOPS="$2"

  local account_id="$(echo "${profile}" | awk -F '-' '{print $1}')"
  local role="$(echo "${profile}" | awk -F '-' '{print $2}')"

  _aws_ola_cli_login "onelogin-${profile}" "${account_id}" "${role}"
}
