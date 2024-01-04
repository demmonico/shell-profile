#!/usr/bin/env bash
#
# This is a script helping with AWS / OneLogin authorization
#     All public functions are prefixed with "laws", interface env vars with "PS_MOD_OLA_"
#     All private functions are prefixed with "_ps_mod_ola_cli_", internal env vars with "_PS_MOD_OLA_"
#
#-------------------------------------------------------------------#

_PS_MOD_OLA_ROOT_DIR="$( dirname $(readlink -f $0) )"
_PS_MOD_OLA_ENV_VARS_FILE="${PS_MOD_OLA_ENV_VARS_FILE:-"${_PS_MOD_OLA_ROOT_DIR}/custom.env"}"
_PS_MOD_OLA_KEYCHAIN_PWD_NAME="onelogin"
_PS_MOD_OLA_CUSTOM_ALIASES_SCRIPT="${PS_MOD_OLA_CUSTOM_ALIASES_SCRIPT:-"${_PS_MOD_OLA_ROOT_DIR}/custom.sh"}"

_PS_MOD_OLA_CLI_PATH="$HOME/Library/Application Support/onelogin-aws-cli"
# Note: non-default loops don't work with OTP MFA, since it cannot re-login in background
_PS_MOD_OLA_CLI_LOOPS=""
_PS_MOD_OLA_CLI_DEFAULT_LOOPS=1

# auto-import env vars
eval $(grep -v '^#' "${_PS_MOD_OLA_ENV_VARS_FILE}" | xargs)
for v in 'PS_MOD_OLA_CLI_USER' 'PS_MOD_OLA_CLI_SUBDOMAIN' 'PS_MOD_OLA_AWS_APP_ID' 'PS_MOD_OLA_AWS_REGION' 'PS_MOD_OLA_SDK_REGION' 'PS_MOD_OLA_SDK_CLIENT_ID' 'PS_MOD_OLA_SDK_CLIENT_SECRET'; do
  if [ -z "${v+1}" ]; then
    echo "ERROR: Missing env variable '${v}'!"
  fi
done

#-------------------------------------------------------------------#
### aliases

alias laws="_ps_mod_ola_cli_login_select"
alias lawsp="_ps_mod_ola_cli_login_with_profile"

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
if [ -f "${_PS_MOD_OLA_CUSTOM_ALIASES_SCRIPT}" ]; then . "${_PS_MOD_OLA_CUSTOM_ALIASES_SCRIPT}"; fi

#-------------------------------------------------------------------#
### main

function _ps_mod_ola_cli_get_keychain_pwd {
  security find-generic-password -a ${USER} -s ${_PS_MOD_OLA_KEYCHAIN_PWD_NAME} -w
}

# download OneLogin AWS CLI and write properties
function _ps_mod_ola_cli_install {
  mkdir -p "${_PS_MOD_OLA_CLI_PATH}"
  pushd "${_PS_MOD_OLA_CLI_PATH}" > /dev/null
  curl -L -O "https://github.com/onelogin/onelogin-aws-cli-assume-role/raw/master/onelogin-aws-assume-role-cli/dist/onelogin-aws-cli.jar"
  if [ ! -f onelogin.sdk.properties ] ; then
    touch onelogin.sdk.properties
    echo "onelogin.sdk.client_id=${PS_MOD_OLA_SDK_CLIENT_ID}"
    echo "onelogin.sdk.client_secret=${PS_MOD_OLA_SDK_CLIENT_SECRET}"
    echo "onelogin.sdk.region=${PS_MOD_OLA_SDK_REGION}"
  fi
  popd > /dev/null

  # copy configs from templates
  if [ ! -f "${_PS_MOD_OLA_ENV_VARS_FILE}" ] ; then
    cp "${_PS_MOD_OLA_ROOT_DIR}/custom.template.env" "${_PS_MOD_OLA_ENV_VARS_FILE}"
  fi
  if [ ! -f "${_PS_MOD_OLA_CUSTOM_ALIASES_SCRIPT}" ] ; then
    cp "${_PS_MOD_OLA_ROOT_DIR}/custom.template.sh" "${_PS_MOD_OLA_CUSTOM_ALIASES_SCRIPT}"
  fi

  # add OneLogin password to keychain (will ask for input, optional step)
  if [ -z "`_ps_mod_ola_cli_get_keychain_pwd 2> /dev/null`" ]; then
    security add-generic-password -a ${USER} -s ${_PS_MOD_OLA_KEYCHAIN_PWD_NAME} -w
  fi
}
if [ ! -d "${_PS_MOD_OLA_CLI_PATH}" ]; then
  echo "${_PS_MOD_OLA_CLI_PATH} does not exist. Installing it..."
  _ps_mod_ola_cli_install
fi

# OneLogin AWS CLI caller
function _ps_mod_ola_cli_run {
  java -jar "${_PS_MOD_OLA_CLI_PATH}/onelogin-aws-cli.jar" \
    -a ${PS_MOD_OLA_AWS_APP_ID} -d ${PS_MOD_OLA_CLI_SUBDOMAIN} \
    --loop ${_PS_MOD_OLA_CLI_LOOPS:-${_PS_MOD_OLA_CLI_DEFAULT_LOOPS}} \
    $@
}

function _ps_mod_ola_cli_login {
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
    ONELOGIN_PWD="$(_ps_mod_ola_cli_get_keychain_pwd 2>/dev/null)"
    _ps_mod_ola_cli_run -p "${profile}" $(echo "${profile_args}") \
      -username "${PS_MOD_OLA_CLI_USER}" ${ONELOGIN_PWD:+"-password ${ONELOGIN_PWD}"} \
      -region "${PS_MOD_OLA_AWS_REGION}"
  fi

  export AWS_DEFAULT_PROFILE="${profile}"
}

# OneLogin AWS CLI login showing the list of available roles
function _ps_mod_ola_cli_login_select {
  local profile="onelogin"
  _PS_MOD_OLA_CLI_LOOPS=""

  _ps_mod_ola_cli_login "${profile}"
}

# OneLogin AWS CLI login with pre-selected profile
function _ps_mod_ola_cli_login_with_profile {
  local profile="$1"
  _PS_MOD_OLA_CLI_LOOPS="$2"

  local account_id="$(echo "${profile}" | awk -F '-' '{print $1}')"
  local role="$(echo "${profile}" | awk -F '-' '{print $2}')"

  _ps_mod_ola_cli_login "onelogin-${profile}" "${account_id}" "${role}"
}
