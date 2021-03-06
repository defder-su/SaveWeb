#!/usr/bin/env bash
###############################################################################
#            _                                                   _
#  ___ _   _| |__   ___ ___  _ __ ___  _ __ ___   __ _ _ __   __| |___
# / __| | | | '_ \ / __/ _ \| '_ ` _ \| '_ ` _ \ / _` | '_ \ / _` / __|
# \__ \ |_| | |_) | (_| (_) | | | | | | | | | | | (_| | | | | (_| \__ \
# |___/\__,_|_.__/ \___\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|\__,_|___/
#
#
# Boilerplate for creating a bash program with subcommands.
#
# Depends on:
#  list
#  of
#  programs
#  expected
#  in
#  environment
#
# Bash Boilerplate: https://github.com/xwmx/bash-boilerplate
#
# Copyright (c) 2015 William Melody • hi@williammelody.com
###############################################################################

# Notes #######################################################################

# Extensive descriptions are included for easy reference.
#
# Explicitness and clarity are generally preferable, especially since bash can
# be difficult to read. This leads to noisier, longer code, but should be
# easier to maintain. As a result, some general design preferences:
#
# - Use leading underscores on internal variable and function names in order
#   to avoid name collisions. For unintentionally global variables defined
#   without `local`, such as those defined outside of a function or
#   automatically through a `for` loop, prefix with double underscores.
# - Always use braces when referencing variables, preferring `${NAME}` instead
#   of `$NAME`. Braces are only required for variable references in some cases,
#   but the cognitive overhead involved in keeping track of which cases require
#   braces can be reduced by simply always using them.
# - Prefer `printf` over `echo`. For more information, see:
#   http://unix.stackexchange.com/a/65819
# - Prefer `$_explicit_variable_name` over names like `$var`.
# - Use the `#!/usr/bin/env bash` shebang in order to run the preferred
#   Bash version rather than hard-coding a `bash` executable path.
# - Prefer splitting statements across multiple lines rather than writing
#   one-liners.
# - Group related code into sections with large, easily scannable headers.
# - Describe behavior in comments as much as possible, assuming the reader is
#   a programmer familiar with the shell, but not necessarily experienced
#   writing shell scripts.

###############################################################################
# Strict Mode
###############################################################################

# Treat unset variables and parameters other than the special parameters ‘@’ or
# ‘*’ as an error when performing parameter expansion. An 'unbound variable'
# error message will be written to the standard error, and a non-interactive
# shell will exit.
#
# This requires using parameter expansion to test for unset variables.
#
# http://www.gnu.org/software/bash/manual/bashref.html#Shell-Parameter-Expansion
#
# The two approaches that are probably the most appropriate are:
#
# ${parameter:-word}
#   If parameter is unset or null, the expansion of word is substituted.
#   Otherwise, the value of parameter is substituted. In other words, "word"
#   acts as a default value when the value of "$parameter" is blank. If "word"
#   is not present, then the default is blank (essentially an empty string).
#
# ${parameter:?word}
#   If parameter is null or unset, the expansion of word (or a message to that
#   effect if word is not present) is written to the standard error and the
#   shell, if it is not interactive, exits. Otherwise, the value of parameter
#   is substituted.
#
# Examples
# ========
#
# Arrays:
#
#   ${some_array[@]:-}              # blank default value
#   ${some_array[*]:-}              # blank default value
#   ${some_array[0]:-}              # blank default value
#   ${some_array[0]:-default_value} # default value: the string 'default_value'
#
# Positional variables:
#
#   ${1:-alternative} # default value: the string 'alternative'
#   ${2:-}            # blank default value
#
# With an error message:
#
#   ${1:?'error message'}  # exit with 'error message' if variable is unbound
#
# Short form: set -u
#set -o nounset

# Exit immediately if a pipeline returns non-zero.
#
# NOTE: This can cause unexpected behavior. When using `read -rd ''` with a
# heredoc, the exit status is non-zero, even though there isn't an error, and
# this setting then causes the script to exit. `read -rd ''` is synonymous with
# `read -d $'\0'`, which means `read` until it finds a `NUL` byte, but it
# reaches the end of the heredoc without finding one and exits with status `1`.
#
# Two ways to `read` with heredocs and `set -e`:
#
# 1. set +e / set -e again:
#
#     set +e
#     read -rd '' variable <<HEREDOC
#     HEREDOC
#     set -e
#
# 2. Use `<<HEREDOC || true:`
#
#     read -rd '' variable <<HEREDOC || true
#     HEREDOC
#
# More information:
#
# https://www.mail-archive.com/bug-bash@gnu.org/msg12170.html
#
# Short form: set -e
#set -o errexit

# Print a helpful message if a pipeline with non-zero exit code causes the
# script to exit as described above.
#trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR

# Allow the above trap be inherited by all functions in the script.
#
# Short form: set -E
#set -o errtrace

# Return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
set -o pipefail

# Set $IFS to only newline and tab.
#
# http://www.dwheeler.com/essays/filenames-in-shell.html
IFS=$'\n\t'

###############################################################################
# Globals
###############################################################################

# $_ME
#
# This program's basename.
_ME="$(basename "${0}")"

# $_VERSION
#
# Manually set this to to current version of the program. Adhere to the
# semantic versioning specification: http://semver.org
_VERSION="0.1"

# $DEFAULT_SUBCOMMAND
#
# The subcommand to be run by default, when no subcommand name is specified.
# If the environment has an existing $DEFAULT_SUBCOMMAND set, then that value
# is used.
DEFAULT_SUBCOMMAND="${DEFAULT_SUBCOMMAND:-help}"

###############################################################################
# Debug
###############################################################################

# _debug()
#
# Usage:
#   _debug <command> <options>...
#
# Description:
#   Execute a command and print to standard error. The command is expected to
#   print a message and should typically be either `echo`, `printf`, or `cat`.
#
# Example:
#   _debug printf "Debug info. Variable: %s\\n" "$0"
__DEBUG_COUNTER=0
_debug() {
  if ((${_USE_DEBUG:-0}))
  then
    __DEBUG_COUNTER=$((__DEBUG_COUNTER+1))
    {
      # Prefix debug message with "bug (U+1F41B)"
      printf "🐛  %s " "${__DEBUG_COUNTER}"
      "${@}"
      printf "―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――\\n"
    } 1>&2
  fi
}

###############################################################################
# Error Messages
###############################################################################

# _exit_1()
#
# Usage:
#   _exit_1 <command>
#
# Description:
#   Exit with status 1 after executing the specified command with output
#   redirected to standard error. The command is expected to print a message
#   and should typically be either `echo`, `printf`, or `cat`.
_exit_1() {
  {
    printf "%s " "$(tput setaf 1)!$(tput sgr0)"
    "${@}"
  } 1>&2
  exit 1
}

# _warn()
#
# Usage:
#   _warn <command>
#
# Description:
#   Print the specified command with output redirected to standard error.
#   The command is expected to print a message and should typically be either
#   `echo`, `printf`, or `cat`.
_warn() {
  {
    printf "%s " "$(tput setaf 1)!$(tput sgr0)"
    "${@}"
  } 1>&2
}

###############################################################################
# Utility Functions
###############################################################################

# _function_exists()
#
# Usage:
#   _function_exists <name>
#
# Exit / Error Status:
#   0 (success, true) If function with <name> is defined in the current
#                     environment.
#   1 (error,  false) If not.
#
# Other implementations, some with better performance:
# http://stackoverflow.com/q/85880
_function_exists() {
  [ "$(type -t "${1}")" == 'function' ]
}

# _command_exists()
#
# Usage:
#   _command_exists <name>
#
# Exit / Error Status:
#   0 (success, true) If a command with <name> is defined in the current
#                     environment.
#   1 (error,  false) If not.
#
# Information on why `hash` is used here:
# http://stackoverflow.com/a/677212
_command_exists() {
  hash "${1}" 2>/dev/null
}

# _contains()
#
# Usage:
#   _contains <query> <list-item>...
#
# Exit / Error Status:
#   0 (success, true)  If the item is included in the list.
#   1 (error,  false)  If not.
#
# Examples:
#   _contains "${_query}" "${_list[@]}"
_contains() {
  local _query="${1:-}"
  shift

  if [[ -z "${_query}"  ]] ||
     [[ -z "${*:-}"     ]]
  then
    return 1
  fi

  for __element in "${@}"
  do
    [[ "${__element}" == "${_query}" ]] && return 0
  done

  return 1
}

# _join()
#
# Usage:
#   _join <delimiter> <list-item>...
#
# Description:
#   Print a string containing all <list-item> arguments separated by
#   <delimeter>.
#
# Example:
#   _join "${_delimeter}" "${_list[@]}"
#
# More information:
#   https://stackoverflow.com/a/17841619
_join() {
  local _delimiter="${1}"
  shift
  printf "%s" "${1}"
  shift
  printf "%s" "${@/#/${_delimiter}}" | tr -d '[:space:]'
}

# _blank()
#
# Usage:
#   _blank <argument>
#
# Exit / Error Status:
#   0 (success, true)  If <argument> is not present or null.
#   1 (error,  false)  If <argument> is present and not null.
_blank() {
  [[ -z "${1:-}" ]]
}

# _present()
#
# Usage:
#   _present <argument>
#
# Exit / Error Status:
#   0 (success, true)  If <argument> is present and not null.
#   1 (error,  false)  If <argument> is not present or null.
_present() {
  [[ -n "${1:-}" ]]
}

# _interactive_input()
#
# Usage:
#   _interactive_input
#
# Exit / Error Status:
#   0 (success, true)  If the current input is interactive (eg, a shell).
#   1 (error,  false)  If the current input is stdin / piped input.
_interactive_input() {
  [[ -t 0 ]]
}

# _piped_input()
#
# Usage:
#   _piped_input
#
# Exit / Error Status:
#   0 (success, true)  If the current input is stdin / piped input.
#   1 (error,  false)  If the current input is interactive (eg, a shell).
_piped_input() {
  ! _interactive_input
}

###############################################################################
# describe
###############################################################################

# describe()
#
# Usage:
#   describe <name> <description>
#   describe --get <name>
#
# Options:
#   --get  Print the description for <name> if one has been set.
#
# Examples:
# ```
#   describe "list" <<HEREDOC
# Usage:
#   ${_ME} list
#
# Description:
#   List items.
# HEREDOC
#
# describe --get "list"
# ```
#
# Set or print a description for a specified subcommand or function <name>. The
# <description> text can be passed as the second argument or as standard input.
#
# To make the <description> text available to other functions, `describe()`
# assigns the text to a variable with the format `$___describe_<name>`.
#
# When the `--get` option is used, the description for <name> is printed, if
# one has been set.
#
# NOTE:
#
# The `read` form of assignment is used for a balance of ease of
# implementation and simplicity. There is an alternative assignment form
# that could be used here:
#
# var="$(cat <<'HEREDOC'
# some message
# HEREDOC
# )
#
# However, this form appears to require trailing space after backslases to
# preserve newlines, which is unexpected. Using `read` simply requires
# escaping backslashes, which is more common.
describe() {
  _debug printf "describe() \${*}: %s\\n" "$@"
  [[ -z "${1:-}" ]] && _exit_1 printf "describe(): <name> required.\\n"

  if [[ "${1}" == "--get" ]]
  then # get ------------------------------------------------------------------
    [[ -z "${2:-}" ]] &&
      _exit_1 printf "describe(): <description> required.\\n"

    local _name="${2:-}"
    local _describe_var="___describe_${_name}"

    if [[ -n "${!_describe_var:-}" ]]
    then
      printf "%s\\n" "${!_describe_var}"
    else
      printf "No additional information for \`%s\`\\n" "${_name}"
    fi
  else # set ------------------------------------------------------------------
    if [[ -n "${2:-}" ]]
    then # argument is present
      read -r -d '' "___describe_${1}" <<HEREDOC
${2}
HEREDOC
    else # no argument is present, so assume piped input
      # `read` exits with non-zero status when a delimeter is not found, so
      # avoid errors by ending statement with `|| true`.
      read -r -d '' "___describe_${1}" || true
    fi
  fi
}

###############################################################################
# Program Option Parsing
#
# NOTE: The `getops` builtin command only parses short options and BSD `getopt`
# does not support long arguments (GNU `getopt` does), so use custom option
# normalization and parsing.
#
# For a pure bash `getopt` function, try pure-getopt:
#   https://github.com/agriffis/pure-getopt
#
# More info:
#   http://wiki.bash-hackers.org/scripting/posparams
#   http://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html
#   http://stackoverflow.com/a/14203146
#   http://stackoverflow.com/a/7948533
#   https://stackoverflow.com/a/12026302
#   https://stackoverflow.com/a/402410
###############################################################################

# Normalize Options ###########################################################

# Source:
#   https://github.com/e36freak/templates/blob/master/options

# Iterate over options, breaking -ab into -a -b and --foo=bar into --foo bar
# also turns -- into --endopts to avoid issues with things like '-o-', the '-'
# should not indicate the end of options, but be an invalid option (or the
# argument to the option, such as wget -qO-)
unset options
# while the number of arguments is greater than 0
while ((${#}))
do
  case "${1}" in
    # if option is of type -ab
    -[!-]?*)
      # loop over each character starting with the second
      for ((i=1; i<${#1}; i++))
      do
        # extract 1 character from position 'i'
        c="${1:i:1}"
        # add current char to options
        options+=("-${c}")
      done
      ;;
    # if option is of type --foo=bar, split on first '='
    --?*=*)
      options+=("${1%%=*}" "${1#*=}")
      ;;
    # end of options, stop breaking them up
    --)
      options+=(--endopts)
      shift
      options+=("${@}")
      break
      ;;
    # otherwise, nothing special
    *)
      options+=("${1}")
      ;;
  esac

  shift
done
# set new positional parameters to altered options. Set default to blank.
set -- "${options[@]:-}"
unset options

# Parse Options ###############################################################

_SUBCOMMAND=""
_SUBCOMMAND_ARGUMENTS=()
_USE_DEBUG=0

while ((${#}))
do
  __opt="${1}"

  shift

  case "${__opt}" in
    -h|--help)
      _SUBCOMMAND="help"
      ;;
    --debug)
      _USE_DEBUG=1
      ;;
    *)
      # The first non-option argument is assumed to be the subcommand name.
      # All subsequent arguments are added to $_SUBCOMMAND_ARGUMENTS.
      if [[ -n "${_SUBCOMMAND}" ]]
      then
        _SUBCOMMAND_ARGUMENTS+=("${__opt}")
      else
        _SUBCOMMAND="${__opt}"
      fi
      ;;
  esac
done

###############################################################################
# Main
###############################################################################

# Declare the $_DEFINED_SUBCOMMANDS array.
_DEFINED_SUBCOMMANDS=()

# _main()
#
# Usage:
#   _main
#
# Description:
#   The primary function for starting the program.
#
#   NOTE: must be called at end of program after all subcommands are defined.
_main() {
  # If $_SUBCOMMAND is blank, then set to `$DEFAULT_SUBCOMMAND`
  if [[ -z "${_SUBCOMMAND}" ]]
  then
    _SUBCOMMAND="${DEFAULT_SUBCOMMAND}"
  fi

  for __name in $(declare -F)
  do
    # Each element has the format `declare -f function_name`, so set the name
    # to only the 'function_name' part of the string.
    local _function_name
    _function_name=$(printf "%s" "${__name}" | awk '{ print $3 }')

    if ! { [[ -z "${_function_name:-}"                      ]] ||
           [[ "${_function_name}" =~ ^_(.*)                 ]] ||
           [[ "${_function_name}" == "bats_readlinkf"       ]] ||
           [[ "${_function_name}" == "describe"             ]] ||
           [[ "${_function_name}" == "shell_session_update" ]]
    }
    then
      _DEFINED_SUBCOMMANDS+=("${_function_name}")
    fi
  done

  # If the subcommand is defined, run it, otherwise return an error.
  if _contains "${_SUBCOMMAND}" "${_DEFINED_SUBCOMMANDS[@]:-}"
  then
    # Pass all comment arguments to the program except for the first ($0).
    ${_SUBCOMMAND} "${_SUBCOMMAND_ARGUMENTS[@]:-}"
  else
    _exit_1 printf "Unknown subcommand: %s\\n" "${_SUBCOMMAND}"
  fi
}

###############################################################################
# Default Subcommands
###############################################################################

# help ########################################################################

describe "help" <<HEREDOC
Usage:
  ${_ME} help [<subcommand>]

Description:
  Display help information for ${_ME} or a specified subcommand.
HEREDOC
help() {
  if [[ "${1:-}" ]]
  then
    describe --get "${1}"
  else
    cat <<HEREDOC
SaveWeb

Version: ${_VERSION}

Usage:
  ${_ME} <subcommand> [--subcommand-options] [<arguments>]
  ${_ME} -h | --help

Options:
  -h --help  Display this help information.

Help:
  ${_ME} help [<subcommand>]

$(_subcommands --)
HEREDOC
  fi
}

# subcommands #################################################################

describe "subcommands" <<HEREDOC
Usage:
  ${_ME} subcommands [--raw]

Options:
  --raw  Display the subcommand list without formatting.

Description:
  Display the list of available subcommands.
HEREDOC
_subcommands() {
  if [[ "${1:-}" == "--raw" ]]
  then
    printf "%s\\n" "${_DEFINED_SUBCOMMANDS[@]}"
  else
    printf "Available subcommands:\\n"
    printf "  %s\\n" "${_DEFINED_SUBCOMMANDS[@]}"
  fi
}

# version #####################################################################

#describe "version" <<HEREDOC
#Usage:
#  ${_ME} ( version | --version )
#
#Description:
#  Display the current program version.
#
#  To save you the trouble, the current version is ${_VERSION}
#HEREDOC
#version() {
#  printf "%s\\n" "${_VERSION}"
#}

###############################################################################
# Subcommands
# ===========..................................................................
#
# Example subcommand group structure:
#
# describe example ""   - Optional. A short description for the subcommand.
# example() { : }   - The subcommand called by the user.
#
#
# describe example <<HEREDOC
#   Usage:
#     $_ME example
#
#   Description:
#     Print "Hello, World!"
#
#     For usage formatting conventions see:
#     - http://docopt.org/
#     - http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html
# HEREDOC
# example() {
#   printf "Hello, World!\\n"
# }
#
###############################################################################

# Example Section #############################################################

# --------------------------------------------------------------------- example

describe "example" <<HEREDOC
Usage:
  ${_ME} example [<name>] [--farewell]

Options:
  --farewell  Print "Goodbye, World!"

Description:
  Print "Hello, World!"
HEREDOC
_example() {
  local _arguments=()
  local _greeting="Hello"
  local _name=

  for __arg in "${@:-}"
  do
    case ${__arg} in
      --farewell)
        _greeting="Goodbye"
        ;;
      -*)
        _exit_1 printf "Unexpected option: %s\\n" "${__arg}"
        ;;
      *)
        if _blank "${_name}"
        then
          _name="${__arg}"
        else
          _arguments+=("${__arg}")
        fi
        ;;
    esac
  done


  if [[ "${_name}" == "Moon" ]]
  then
    printf "%s, Luna!\\n" "${_greeting}"
  elif [[ -n "${_name}" ]]
  then
    printf "%s, %s!\\n" "${_greeting}" "${_name}"
  else
    printf "%s, World!\\n" "${_greeting}"
  fi
}

# --------------------------------------------------------------------- functions

# https://www.rfc-editor.org/rfc/rfc3986#appendix-B
#
readonly URI_REGEX='^(([^:/?#]+):)?(//((([^:/?#]+)@)?([^:/?#]+)(:([0-9]+))?))?(/([^?#]*))(\?([^#]*))?(#(.*))?'
#                    ↑↑            ↑  ↑↑↑            ↑         ↑ ↑            ↑ ↑        ↑  ↑        ↑ ↑
#                    |2 scheme     |  ||6 userinfo   7 host    | 9 port       | 11 rpath |  13 query | 15 fragment
#                    1 scheme:     |  |5 userinfo@             8 :…           10 path    12 ?…       14 #…
#                                  |  4 authority
#                                  3 //…
_parse_scheme () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[2]}"
}
_parse_authority () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[4]}"
}
_parse_user () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[6]}"
}
_parse_host () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[7]}"
}
_parse_port () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[9]}"
}
_parse_path () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[10]}"
}
_parse_rpath () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[11]}"
}
_parse_query () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[13]}"
}
_parse_fragment () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[15]}"
}

_random_value() {
	chars=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
	for i in {1..32} ; do
		echo -n "${chars:RANDOM%${#chars}:1}"
	done
	echo
}

_free_space() {
	echo $(df -Pk $1 | sed 1d | grep -v used | awk '{ print $4 "\t" }')
}

_check_free_space_for_temp() {
	if [ $(_free_space $(dirname $(mktemp -u 2>/dev/null || mktemp -u -t 'mytmpdir'))) -gt 102400 ]; then
		return 0
	else
		return 1
	fi
}

_wget() {
	MYTMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir')
	MYTMPFILE=$(mktemp 2>/dev/null || mktemp -t 'mytmpfile')
	cd $MYTMPDIR
	RAND="$(_random_value)"
	echo "Log $RAND" > $MYTMPFILE
	echo "$2" >> $MYTMPFILE
	wget --adjust-extension --no-cache --page-requisites --restrict-file-names=windows --convert-links --backup-converted --no-host-directories --timeout=10 --tries=6 --user-agent="Mozilla/5.0 (Windows NT 10.0; rv:91.0) Gecko/20100101 Firefox/91.0" --append-output=$MYTMPFILE $1
	WGETERR=$?
	RET=1
	if [[ $WGETERR -eq 0 || $WGETERR -eq 8 ]] && [ $(ls -A "$MYTMPDIR" | wc -l) -ne 0 ]; then
		CID="$(ipfs add --quieter --pin=false -r $MYTMPDIR)"
		ipfs files cp /ipfs/$CID $MFS_ADDR/$SUBDIR
		if [ $? -eq 0 ]; then
			LOGCID="$(ipfs add --quieter --pin=false $MYTMPFILE)"
			ipfs files cp /ipfs/$LOGCID $MFS_ADDR/$SUBDIR.log
			echo "$HASH/$SUBDIR"
			RET=0
		fi
	else
		>&2 echo "Error: wget can't download $1 (err. $WGETERR)"
	fi
	cd ..
	rm -r $MYTMPDIR
	rm $MYTMPFILE
	return $RET
}

_save_wget() {
	DT=$(export TZ=GMT ; date '+%Y%m%dGMT%H%M%S')
	SUBDIR="$DT-wget"
	ipfs files ls $MFS_ADDR/$SUBDIR &>/dev/null
	if [ $? -ne 0 ]; then
		_wget $1
		return $?
	else
		>&2 echo "$SUBDIR exists"
		return 0
	fi
}
_save_archived() {
	type -P wayback_machine_downloader &>/dev/null && ISINST=1 || ISINST=0
	if [ $ISINST -eq 0 ]
	then
		>&2 echo "Error: wayback_machine_downloader is not installed"
		return 127
	fi
	type -P jq &>/dev/null && ISINST=1 || ISINST=0
	if [ $ISINST -eq 0 ]
	then
		>&2 echo "Error: jq is not installed (seeing https://stedolan.github.io/jq/download/)"
		return 127
	fi
	RET=1
	for I in $(wayback_machine_downloader -s -e -l $1 2>/dev/null | jq --raw-output '.. | .timestamp? | strings' | tail -n1); do
		SUBDIR="${I:0:8}GMT${I:8:6}-archive"
		ipfs files ls $MFS_ADDR/$SUBDIR &>/dev/null
		if [ $? -ne 0 ]; then
			_wget "https://web.archive.org/web/$I/$URL"
			if [ $? -eq 0 ]; then
				RET=0
			fi
		else
			>&2 echo "$SUBDIR is already downloaded"
		fi
	done
	return $RET
}
_save_ipns() {
	DOMAIN=$(echo "$1" | awk -F/ '{print $1}')
	ADDR=$(ipfs resolve --timeout=60s /ipns/$DOMAIN)
	if [[ "$ADDR" != "" ]]; then
		DT=$(export TZ=GMT ; date '+%Y%m%dGMT%H%M%S')
		SUBDIR="$DT-ipns"
		ipfs files ls $MFS_ADDR/$SUBDIR &>/dev/null
		if [ $? -ne 0 ]; then
			GATEWAY=$(ipfs config Addresses.Gateway)
			if [ $? -eq 0 ]; then
				_wget "http://127.0.0.1:${GATEWAY##*/}/ipns/$1" "Resolved /ipns/$DOMAIN to $ADDR"
				return $?
			fi
		else
			>&2 echo "$SUBDIR exists"
			return 0
		fi
	fi
	return 1
}
_save_ipfs() {
	MAIN=$(echo "$1" | awk -F/ '{print $1}')
	ADDR=$(ipfs resolve --timeout=60s /ipfs/$MAIN)
	if [[ "$ADDR" != "" ]]; then
		DT=$(export TZ=GMT ; date '+%Y%m%dGMT%H%M%S')
		SUBDIR="$DT-ipfs"
		ipfs files ls $MFS_ADDR/$SUBDIR &>/dev/null
		if [ $? -ne 0 ]; then
			GATEWAY=$(ipfs config Addresses.Gateway)
			if [ $? -eq 0 ]; then
				_wget "http://127.0.0.1:${GATEWAY##*/}/ipfs/$1"
				return $?
			fi
		else
			>&2 echo "$SUBDIR exists"
			return 0
		fi
	fi
	return 1
}

describe "hash" <<HEREDOC
Usage:
  ${_ME} hash <URL>

Description:
  Calculate hash for URL
HEREDOC
hash() {
	if [[ "$1" == "" ]]; then
		>&2 echo "This subcommand requires URL as a parameter"
		return 1
	fi
	HASH="$(echo $1 | ipfs add --only-hash --quieter --cid-version=0)"
	if [[ "$HASH" != "" ]]; then
		HASH="page-$HASH"
		echo "$HASH"
	else
		>&2 echo "Installed ipfs-go is required for SaveWeb"
		return 1
	fi
}

_addToHistory() {
	mkdir --parents "$HOME/.saveweb"
	DT=$(export TZ=GMT ; date '+%Y-%m-%d GMT %H:%M:%S')
	printf "%s\t%s\n" "$DT" "$1" >> "$HOME/.saveweb/history.txt"
}

_reprovidingWarning() {
	REPROVIDING=$(ipfs config Reprovider.Strategy)
	if [[ "$REPROVIDING" == "all" ]]; then
		>&2 echo "Warning: the reprovider announces all IPFS data, including the SaveWeb Library,"
		>&2 echo " run 'ipfs config Reprovider.Strategy pinned' to announce only pinned data,"
		>&2 echo " see also https://github.com/ipfs/go-ipfs/blob/master/docs/config.md#reproviderstrategy"
	fi
}


describe "save" <<HEREDOC
Usage:
  ${_ME} save [<URL>]

Description:
  Save web page by URL
HEREDOC
save() {
	#TODO: --archives={default|none|last|all}, --tor={default|yes|no}
	if [[ "$1" == "urls" ]]; then
		_reprovidingWarning
		for I in $("$0" "$@" 2>/dev/null)
		do
			VERSIONS_COUNT=$(_versions $I | grep -e "^.*-wget$" -e "^.*-ip.s$" | wc -l)
			if [ "$VERSIONS_COUNT" -eq 0 ]; then
				>&2 echo -n "Saving $I"
				local rnumber=$((RANDOM%11+5))
				for (( i = 1; i <= $rnumber; i++ )) ; do
					sleep 1
					>&2 echo -n "."
				done
				>&2 echo ""
				"$0" save --no-warnings $I
			fi
			if ! _check_free_space_for_temp
			then
				>&2 echo "Free disk space for temporary files and run the command again"
				return 1
			fi
		done
		>&2 echo "Done"
		return 0
	fi
	URL=""
	local _arguments=()
	local _warnings=1
	local _val=
	for __arg in "${@:-}"
	do
	case ${__arg} in
	  --no-warnings)
		_warnings=0
		;;
	  -*)
		_exit_1 printf "Unexpected option: %s\\n" "${__arg}"
		;;
	  *)
		if _blank "${_URL}"
		then
		  _val="${__arg}"
		  URL="$_val"
		else
		  _arguments+=("${__arg}")
		fi
		;;
	esac
	done
	if [ $_warnings -eq 1 ]; then
		_reprovidingWarning
	fi
	if [[ "$URL" == "" ]]; then
		>&2 echo "This subcommand requires URL as a parameter"
		return 1
	fi
	_addToHistory "$URL"
	type -P wget &>/dev/null && ISINST=1 || ISINST=0
	if [ $ISINST -eq 0 ]
	then
		>&2 echo "Error: wget is not installed"
		return 127
	fi
	HASH=$(hash "$URL")
	if [[ "$HASH" != "" ]]; then
		MFS_ADDR="/SaveWeb/pages/$HASH"
		ipfs files ls $MFS_ADDR/URL.txt >/dev/null 2>/dev/null
		if [ $? -ne 0 ]; then
			ipfs files mkdir /SaveWeb 2>/dev/null
			ipfs files mkdir /SaveWeb/pages 2>/dev/null
			ipfs files mkdir $MFS_ADDR 2>/dev/null
			URLTXTCID="$(printf "%s\n%s\n" "URL $(_random_value)" "$URL" | ipfs add --quieter --pin=false)"
			ipfs files cp /ipfs/$URLTXTCID $MFS_ADDR/URL.txt
		fi
		if _check_free_space_for_temp
		then
			if [[ $URL == ipns://* ]]; then
				_save_ipns "${URL#ipns://}"
			elif [[ $URL == ipfs://* ]]; then
				_save_ipfs "${URL#ipfs://}"
			else
				_save_wget $URL
				if [ $? -ne 0 ]; then
					_save_archived $URL
				fi
			fi
			PARSEDPATH=$(_parse_path $URL)
			if [[ $URL != *://* ]]; then
				_save_ipns $URL
			elif [[ $URL == http*://*.*/ipfs/* ]]; then
				_save_ipfs "${PARSEDPATH#/ipfs/}"
			elif [[ $URL == http*://*.*/ipns/* ]]; then
				_save_ipns "${PARSEDPATH#/ipns/}"
			fi
		else
			>&2 echo "Error: insufficient disk space for temporary files"
			return 1
		fi
	else
		return 1
	fi
}

describe "urls" <<HEREDOC
Usage:
  ${_ME} urls <file>

Description:
  List URLs from file (text or json)
HEREDOC
urls() {
	FIL=""
	PARAM=""
	GREP=""
	BASE=""
	for I in "$@"; do
		if [[ $I == "--grep" ]]; then
		  	PARAM="grep"
		elif [[ $I == "--base" ]]; then
		  	PARAM="base"
		else
			if [[ $PARAM == "grep" ]]; then
				GREP=$I
			elif [[ $PARAM == "base" ]]; then
				BASE=$I
			else
				FIL=$I
			fi
			PARAM=""
		fi
	done
	if [[ "$FIL" == "" ]]; then
		>&2 echo "This subcommand requires file as a parameter:"
		>&2 echo " txt - contain URLs in separate lines"
		>&2 echo " json - contain URLs in the 'url' field"
		>&2 echo " html - contain URLs in the 'href' attribute"
		>&2 echo ""
		CID="$(ipfs files stat --hash /SaveWeb/pages/)"
		if [[ "$CID" != "" ]]; then
			>&2 echo "There are URLs already in the SaveWeb Library (see also 'sw history'):"
			mkdir --parents "$HOME/.saveweb/cache/urls"
			for I in $(ipfs files ls /SaveWeb/pages/); do
				if [[ $I == page-* ]]; then
					#MD5=`echo "$I" | md5sum | awk '{ print $1 }'`
					CACHE_FILE="$HOME/.saveweb/cache/urls/$I-URL"
					URL=$(grep "" "$CACHE_FILE" 2>/dev/null)
					if [[ "$URL" != "" ]]; then
						echo "$URL" | grep "$GREP"
					else
						URL=$(ipfs cat /ipfs/$CID/$I/URL.txt 2>/dev/null | sed -n 2p)
						if [[ "$URL" != "" ]]; then
							echo "$URL" > "$CACHE_FILE"
							echo "$URL" | grep "$GREP"
						else
							>&2 echo "Error: $I not resolved"
						fi
					fi
				fi
			done
			>&2 echo ""
		fi
		return
	fi
	#while read line
	#do
	#	echo "$line"
	#done < "${1:-/dev/stdin}"
	if [[ $FIL == *.json ]]; then
		type -P jq &>/dev/null && ISINST=1 || ISINST=0
		if [ $ISINST -eq 0 ]
		then
			>&2 echo "Error: jq is not installed (seeing https://stedolan.github.io/jq/download/)"
			exit 127
		fi
		if [[ "$BASE" != "" ]]; then
			>&2 echo "Attribute --base is only supported for html files"
			exit 1
		fi
		cat $FIL | jq --raw-output '.. | .url? | strings' | grep "$GREP" | awk '!a[$0]++; fflush()'
	elif [[ $FIL == *.htm* ]]; then
		type -P htmlq &>/dev/null && ISINST=1 || ISINST=0
		if [ $ISINST -eq 0 ]
		then
			>&2 echo "Error: htmlq is not installed (seeing https://github.com/mgdm/htmlq/)"
			exit 127
		fi
		if [[ "$BASE" != "" ]]; then
			cat $FIL | htmlq --base="$BASE" --attribute href a | grep "$GREP" | awk '!a[$0]++; fflush()'
		else
			cat $FIL | htmlq --detect-base --attribute href a | grep "$GREP" | awk '!a[$0]++; fflush()'
		fi
	else
		if [[ "$BASE" != "" ]]; then
			>&2 echo "Attribute --base is only supported for html files"
			exit 1
		fi
		grep "$GREP" $FIL | awk '!a[$0]++; fflush()'
	fi
}

describe "remove" <<HEREDOC
Usage:
  ${_ME} remove <URL>

Description:
  Remove all saved versions of web page by URL
HEREDOC
remove() {
	URL="$1"
	if [[ "$URL" == "" ]]; then
		>&2 echo "This subcommand requires URL as a parameter"
		return 1
	fi
	HASH=$(hash "$URL")
	if [[ "$HASH" != "" ]]; then
		MFS_ADDR="/SaveWeb/pages/$HASH"
		ipfs files rm -r $MFS_ADDR
		return $?
	else
		return 1	
	fi
}

#describe "versions" <<HEREDOC
#Usage:
#  ${_ME} versions <URL>
#
#Description:
#  List saved versions of web page by URL
#HEREDOC
_versions() {
	URL="$1"
	if [[ "$URL" == "" ]]; then
		>&2 echo "This sub command requires URL as a parameter"
		return 1
	fi
	HASH=$(hash "$URL")
	if [[ "$HASH" != "" ]]; then
		for I in $(ipfs files ls /SaveWeb/pages/$HASH 2>/dev/null | sed 's/^/'"$HASH"'\//')
		do
			if [[ $I != *.* ]]; then
				echo $I
			fi
		done
	fi
}

describe "present" <<HEREDOC
Usage:
  ${_ME} present [<URL>]

Description:
  Present saved versions of web page by URL
HEREDOC
present() {
	if [[ "$1" == "urls" ]]; then
		if [[ "$2" != "" ]]; then
			ipfs files mkdir /SaveWeb 2>/dev/null
			ipfs files mkdir /SaveWeb/presents 2>/dev/null
			DT=$(export TZ=GMT ; date '+%Y%m%dGMT%H%M%S')
			MFS_ADDR="/SaveWeb/presents/present-$DT"
			ipfs files mkdir $MFS_ADDR 2>/dev/null
			COUNT=0
			for I in $("$0" "$@" 2>/dev/null)
			do
				HASH=$(hash "$I")
				ipfs files cp /SaveWeb/pages/$HASH $MFS_ADDR/$HASH
				if [ $? -eq 0 ]; then
					((COUNT++))
				fi
			done
			CID="$(ipfs files stat --hash $MFS_ADDR)"
			if [[ "$CID" != "" && $COUNT -ne 0 ]]; then
				GATEWAY=$(ipfs config Addresses.Gateway)
				if [ $? -eq 0 ]; then
					>&2 echo "Open http://127.0.0.1:${GATEWAY##*/}/ipfs/$CID"
					>&2 echo " in a browser on the local machine"
					>&2 echo ""
				fi
				echo "/ipfs/$CID"
				>&2 echo ""
				STAT=$", NumURLs: $COUNT"
				ipfs dag stat $CID | awk -v SUFFIX="$STAT" '{print $0 SUFFIX}' 1>&2
				return 0
			fi
		else
			present
			return $?
		fi
		>&2 echo "Run 'sw save ${@@Q}'"
		return 1
	fi
	URL="$1"
	HASH=$(hash "$URL" 2>/dev/null)
	MFS_ADDR="/SaveWeb/pages/$HASH"
	CID="$(ipfs files stat --hash $MFS_ADDR)"
	if [[ "$CID" != "" ]]; then
		if [[ "$HASH" == "" ]]; then
			>&2 echo "There is a content identifier of the SaveWeb Library,"
			>&2 echo " sharing (or using with public gateways) is not safe"
			>&2 echo ""
		fi
		GATEWAY=$(ipfs config Addresses.Gateway)
		if [ $? -eq 0 ]; then
			>&2 echo "Open http://127.0.0.1:${GATEWAY##*/}/ipfs/$CID"
			>&2 echo " in a browser on the local machine"
			>&2 echo ""
		fi
		if [[ "$1" != "" ]]; then
			REPROVIDING=$(ipfs config Reprovider.Strategy)
			if [[ "$REPROVIDING" != "all" ]]; then
				>&2 echo "If you need to publish or view from an other machine,"
				>&2 echo " run 'ipfs pin add $CID'"
				if [[ "$REPROVIDING" == "roots" ]]; then
					>&2 echo " and 'ipfs config Reprovider.Strategy pinned'"
				fi
				>&2 echo ""
			fi
		fi
		echo "/ipfs/$CID"
		>&2 echo ""
		STAT=""
		COUNT=0
		if [[ $HASH != */* ]]; then
			for I in $(ipfs files ls /SaveWeb/pages/$HASH); do
				if [[ $I != *.* ]]; then
					((COUNT++))
				fi
			done
			if [[ "$HASH" == "" ]]; then
				STAT=$", NumURLs: $COUNT"
			else
				STAT=$", NumVersions: $COUNT"
			fi
		fi
		ipfs dag stat $CID | awk -v SUFFIX="$STAT" '{print $0 SUFFIX}' 1>&2
	else
		>&2 echo "Run 'sw save ${@@Q}'"
		exit 1
	fi
}

describe "history" <<HEREDOC
Usage:
  ${_ME} history

Description:
  List URLs which were attempted to be saved
HEREDOC
history() {
	FN="$HOME/.saveweb/history.txt"
	COUNT=$(cat $FN 2>/dev/null | wc -l)
	if [ $COUNT -ne 0 ]; then
		>&2 echo "There is a list of URLs which was attempted to be saved or imported:"
		cat $FN
		>&2 echo ""
		>&2 echo "NumEntries: $COUNT"
	else
		>&2 echo "There are no URLs which was attempted to be saved (see the './save' command) or imported (see the './import' command)"
	fi
}

###############################################################################
# Run Program
###############################################################################

# Call the `_main` function after everything has been defined.
_main
