#!/usr/bin/env bash
#
# This is a customisation for AWS / OneLogin authorization script
#
#-------------------------------------------------------------------#

# To set your roles:
# 1. Run 'laws' and check the list of available roles
# 2. Create new alias similar to following
#    alias <YOUR_ALIAS>="_aws_ola_cli_login_with_profile <YOUR_AWS_ACCOUNT_ID>-<YOUR_AWS_ROLE_NAME>"

#-------------------------------------------------------------------#
### aliases

alias laws-example="_aws_ola_cli_login_with_profile 123-SuperAdminRole"
