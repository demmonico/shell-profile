# Profile Scripts

## Description

This project contains a set of profile scripts that helps as a shortcuts in a ZSH/Bash shell.

## Structure

Project has entrypoint, that needs to be loaded in the profile shell. 
The scripts are organized into modules and are loaded dynamically at runtime.

The main entrypoint of the project is the `zsh.sh` script. 
This script loads common functionalities from `_common.sh` and then loads all the ZSH specific modules located in the `modules-zsh` and `modules` directories.

The `modules` directory contains various modules that can be loaded to provide additional functionalities. 
Each module should have an `index.sh` script which will be executed when the module is loaded.

```tree
modules         # contains modules that will be dynamically loaded
├── ola         # module for AWS / OneLogin authorization
│ └── index.sh  # entrypoint for the module
│ └── ...
└── ...
modules-zsh     # contains specific to ZSH modules that will be dynamically loaded
├── ps          # module tunes PS1 prompt
│ └── index.sh  # entrypoint for the module
│ └── ...
└── ...
_common.sh      # common for all shells functions, aliases, and variables; autoloads the modules
README.md       # this file
zsh.sh          # entrypoint for the ZSH profile
```

## Usage

One of recommended ways of includes this profile scripts:
- this project is cloned to `$HOME/REPLACE_WITH_THIS_PROJECT_REPO_LOCATION` location
- `OSX, ZSH: ~/.zshrc` has entry, so that it loads the profile scripts from the custom location
    ```bash
    SCRIPT="${HOME}/_profile/zsh.sh"
    if [ -f "$SCRIPT" ]; then . "${SCRIPT}"; fi
    ```
- `${HOME}/_profile` folder has structure as described below
    ```tree
    _profile
    ├── modules               # contains customisation for base modules or fully custom modules that will be dynamically loaded
    │   ├── ola               # customisation for AWS / OneLogin authorization module
    │   │   └── custom.env    # custom environment variables for the module
    │   │   └── custom.sh     # custom aliases for the module
    │   └── ...
    └── zsh.sh                # entrypoint for the ZSH profile with loading customisation and base framework (this project)
    ```
- `${HOME}/_profile/zsh.sh` has following content
    ```bash
    #!/usr/bin/env bash
    _PS_CUSTOM_DIR="$( dirname $(readlink -f $0) )"
    
    # ola module customisation's location (optional when not using ola module)
    PS_MOD_OLA_ENV_VARS_FILE="${_PS_CUSTOM_DIR}/modules/ola/custom.env"
    PS_MOD_OLA_CUSTOM_ALIASES_SCRIPT="${_PS_CUSTOM_DIR}/modules/ola/custom.sh"
    
    ### framework
    _PS_FRAMEWORK_DIR="$HOME/REPLACE_WITH_THIS_PROJECT_REPO_LOCATION"
    . "${_PS_FRAMEWORK_DIR}/zsh.sh"
    
    _ps_log_msg "ZSH profile scripts have been initiated - _PS_CUSTOM_DIR='${_PS_CUSTOM_DIR}'"
    _ps_log_msg "ZSH framework has been connected - _PS_FRAMEWORK_DIR='${_PS_FRAMEWORK_DIR}'"
    
    ### autoload CS modules
    for module in $( find "${_PS_CUSTOM_DIR}/modules" -type d -mindepth 1 -maxdepth 1 ); do
    local INDEX_SCRIPT="${module}/index.sh"
    if [ -f "${INDEX_SCRIPT}" ]; then
    . "${INDEX_SCRIPT}"
    _ps_log_msg "CS module has been connected - INDEX_SCRIPT='${INDEX_SCRIPT}'"
    fi
    done
    ```

## Installation

Keeping in mind usage scenario that was described above, installation steps are following:

- clone the repository to your local machine. Ensure that you have at least one of ZSH or Bash shells installed.
- create `${HOME}/_profile` folder with structure as described above
- add sourcing of entrypoint to your profile script (usually `${HOME}/_profile/zsh.sh` for `~/.zshrc` or `${HOME}/_profile/bash.sh` for `~/.bashrc`)
- add customisation to the modules that you want to use (optional)


## Current framework's functionality

### Common

- `ll`: Alias for `ls -al`.
- `watcha`: Function to watch the output of an alias.
- `t`: Function to run terragrunt, terramate, or terraform based on the presence of certain files.

### Modules

#### Helpers

Set of functions that can be used in other modules.

- `ps-help-cmd` : Iterate over folders and print ONLY entities, that named as PUBLICLY accessible

#### K8s

Set of functions that can be used to manage K8s clusters.

#### OLA

Helps with AWS / OneLogin authorization. This module provides several aliases and functions to manage AWS / OneLogin authorization.

- `laws`: Alias for `_ps_mod_ola_cli_login_select`.
- `lawsp`: Alias for `_ps_mod_ola_cli_login_with_profile`.
- `laws-current`: Function to display the current AWS identity and profile.

#### Git

Set of functions that can be used to manage Git repositories.

#### PS

Set of functions that can be used to manage PS1 prompt.


## Contributing

If you want to contribute to this project, please create a new branch and submit a pull request.
