#!/bin/bash

VERSION="0.4.2"
DATE="2022-12-15"
NAME="devilbox-cli"
DESCRIPTION="A simple and conveniant command line to manage devilbox from anywhere"
LINK="https://github.com/louisgab/devilbox-cli"

ENV_FILE=".env"

DOCKER_COMPOSE="docker compose"
DOCKER_COMPOSE_FILE="docker-compose.yml"
DOCKER_COMPOSE_OVERRIDE_FILE="docker-compose.override.yml"

DEVILBOX_COMPOSE_FILE_PATTERN="${DOCKER_COMPOSE_OVERRIDE_FILE}-"
DEVILBOX_COMPOSE_DIR="compose/"
DEVILBOX_MAIN_CONTAINERS="httpd php mysql pgsql redis memcd mongo"

PHP_CONFIG="PHP_SERVER="
HTTPD_CONFIG="HTTPD_SERVER="
MYSQL_CONFIG="MYSQL_SERVER="
PGSQL_CONFIG="PGSQL_SERVER="
REDIS_CONFIG="REDIS_SERVER="
MEMCD_CONFIG="MEMCD_SERVER="
MONGO_CONFIG="MONGO_SERVER="
DOCROOT_CONFIG="HTTPD_DOCROOT_DIR="
WWWPATH_CONFIG="HOST_PATH_HTTPD_DATADIR="

DEVILBOX_CONTAINERS_CONFIG="DEVILBOX_CONTAINERS="
COMPOSE_PATH_SEPARATOR_CONFIG="COMPOSE_PATH_SEPARATOR="
COMPOSE_FILE_CONFIG="COMPOSE_FILE="

## Basic wrappers around exit codes

OK_CODE=0
KO_CODE=1

was_success() {
    local exit_code=$?
    [ "$exit_code" -eq "$OK_CODE" ]
}

was_error() {
    local exit_code=$?
    [ "$exit_code" -eq "$KO_CODE" ]
}

die () {
    local exit_code=$1
    if [ ! -z "$exit_code" ]; then
        exit "$exit_code"
    else
        exit "$?"
    fi
}

## Functions used for fancy output

COLOR_DEFAULT=$(tput sgr0)
COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_YELLOW=$(tput setaf 3)
COLOR_BLUE=$(tput setaf 4)
# COLOR_PURPLE=$(tput setaf 5)
# COLOR_CYAN=$(tput setaf 6)
COLOR_LIGHT_GRAY=$(tput setaf 7)
COLOR_DARK_GRAY=$(tput setaf 0)

error() {
    local message=$1
    printf "%s %s\n" "${COLOR_RED}[✘]" "${COLOR_DEFAULT}$message" >&2
    die "$KO_CODE"
}

success() {
    local message=$1
    printf "%s %s\n" "${COLOR_GREEN}[✔]" "${COLOR_DEFAULT}$message"
}

info() {
    local message=$1
    printf "%s %s\n" "${COLOR_YELLOW}[!]" "${COLOR_DEFAULT}$message"
}

question() {
    local message=$1
    printf "%s %s\n" "${COLOR_BLUE}[?]" "${COLOR_DEFAULT}$message"
}

## Functions used for user interaction

has_confirmed() {
    local response=$1
    case "$response" in
        [yY][eE][sS]|[yY]) return "$OK_CODE";;
        *) return "$KO_CODE";;
    esac
}

ask() {
    local question=$1
    local response
    read -r -p "$(question "${question} [y/N] ")" response
    printf '%s' "$response"
    return "$OK_CODE"
}

confirm() {
    local question=$1
    if has_confirmed "$(ask "$question")"; then
        return "$OK_CODE"
    else
        return "$KO_CODE"
    fi
}

## Functions used to manipulate choices values in .env file

is_choice_existing () {
    local config=$1
    local choice=$2
    local search
    search=$(grep -Eo "^#*$config$choice$" "$ENV_FILE")
    if was_success && [ ! -z "$search" ] ;then
        return "$OK_CODE"
    else
        return "$KO_CODE"
    fi
}

get_current_choice () {
    local config=$1
    local current
    current=$(grep -Eo "^$config+[[:print:]]*" "$ENV_FILE" | sed "s/.*$config//g")
    if was_success && [ ! -z "$current" ] ;then
        printf "%s" "$current"
        return "$OK_CODE"
    else
        return "$KO_CODE"
    fi
}

is_choice_available() {
    local config=$1
    local choice=$2
    local current
    current=$(get_current_choice "$config")
    if was_success && [ "$choice" != "$current" ] ;then
        return "$OK_CODE"
    else
        return "$KO_CODE"
    fi
}

get_all_choices () {
    local config=$1
    local all
    all=$(grep -Eo "^#*$config+[[:print:]]*" "$ENV_FILE" | sed "s/.*$config//g")
    if was_success && [ ! -z "$all" ] ;then
        printf "%s\n" "$all"
        return "$OK_CODE"
    else
        return "$KO_CODE"
    fi
}

set_choice () {
    local config=$1
    local new=$2
    local current
    if ! is_choice_existing "$config" "$new" ||  ! is_choice_available "$config" "$new"; then
        return "$KO_CODE"
    fi
    current=$(get_current_choice "$config")
    if was_error; then
        return "$KO_CODE"
    fi
    sed -i -e "s/\(^#*$config$current\).*/#$config$current/" "$ENV_FILE"
    if was_error; then
        return "$KO_CODE"
    fi
    sed -i -e "s/\(^#*$config$new\).*/$config$new/" "$ENV_FILE"
    if was_error; then
        return "$KO_CODE"
    fi
    current=$(get_current_choice "$config")
    if was_success && [[ "$current" = "$new" ]]; then
        return "$OK_CODE"
    else
        return "$KO_CODE"
    fi
}

### READABLE VERSIONS

is_readable_choice_existing () {
    local type=$1
    local config=$2
    local choice=$3
    if is_choice_existing "$config" "$choice"; then
        success "$type version $choice is existing"
        return "$OK_CODE"
    else
        error "$type version $choice does not exists"
        return "$K0_CODE"
    fi
}

get_readable_current_choice () {
    local type=$1
    local config=$2
    local current
    current=$(get_current_choice "$config")
    if was_success; then
        info "$type current version is $current"
        return "$OK_CODE"
    else
        error "Couldnt retrieve current version of $type"
        return "$KO_CODE"
    fi
}

is_readable_choice_available() {
    local type=$1
    local config=$2
    local choice=$3
    if is_choice_available "$config" "$choice"; then
        success "$type version $choice is available"
        return "$OK_CODE"
    else
        error "$type is already using version $choice"
        return "$K0_CODE"
    fi
}

get_readable_all_choices () {
    local type=$1
    local config=$2
    local all
    all=$(get_all_choices "$config")
    if was_success; then
        info "$type available versions:"
        printf "%s\n" "$all"
        return "$OK_CODE"
    else
        error "Couldnt retrive available versions of $type"
        return "$KO_CODE"
    fi
}

set_readable_choice () {
    local type=$1
    local config=$2
    local new=$3
    if ! is_empty "$type" "$new"; then
        return "$KO_CODE"
    fi
    if ! is_readable_choice_existing "$type" "$config" "$new"; then
        return "$KO_CODE"
    fi
    if ! is_readable_choice_available "$type" "$config" "$new"; then
        return "$KO_CODE"
    fi
    if set_choice "$config" "$new"; then
        success "$type version updated to $new"
        return "$OK_CODE"
    else
        error "$type version change failed"
        return "$KO_CODE"
    fi
}

get_current_choice_version () {
    local type=$1
    local config=$2
    get_readable_current_choice "$type" "$config"
}

get_all_choice_versions () {
    local type=$1
    local config=$2
    get_readable_all_choices "$type" "$config"
}

set_choice_version () {
    local type=$1
    local config=$2
    local new=$3
    set_readable_choice "$type" "$config" "$new"
}

is_choice () {
    local config=$1
    local all=$(grep --max-count=2 -Ec "^[#]*$config+[[:print:]]*" "$ENV_FILE")
    if was_success && [[ $all -gt 1 ]] ; then
        return "$OK_CODE"
    else
        return "$KO_CODE"
    fi
}

is_empty () {
    local type=$1
    local choice=$2
    if [ ! -z "$choice" ] ; then
         return "$OK_CODE"
    else
        error "$type variable can't be empty"
        return "$K0_CODE"
    fi
}

## Functions used to manipulate composes in .env file

get_file_composes() {
    FILES=$DOCKER_COMPOSE_FILE
    FILES+=":$DOCKER_COMPOSE_OVERRIDE_FILE"

    for container in $(printf %s "${1//,/ }")
    do
        FILE="${DEVILBOX_COMPOSE_DIR}${DEVILBOX_COMPOSE_FILE_PATTERN}${container}"
        if [ -f "$FILE" ]; then
            FILES+=":${FILE}"
        fi
    done
    printf "%s\n" ${FILES}
    return "$OK_CODE"
}

get_composes_string() {
    local composes=$1
    local separator=$(get_config "$COMPOSE_PATH_SEPARATOR_CONFIG")
    local string=$(get_file_composes "$composes" | awk -v separator=${separator:-:} 'NR==1 {printf "%s", $0}; NR>1 {printf "%s%s", separator, $0}')
    if was_error; then
        return "$KO_CODE"
    fi
    printf %s "${string}"
    return "$OK_CODE"
}

get_default_composes() {
    local current=$(get_config "$COMPOSE_FILE_CONFIG")
    if was_success && [ -n "$current" ]; then
        printf %s "${current}"
    elif [ -n "$COMPOSE_FILE" ]; then
        printf %s "${COMPOSE_FILE}"
    else
        printf %s ""
    fi
}

parse_compose() {
    local compose=$(get_default_composes)
    local separator=$(get_config "$COMPOSE_PATH_SEPARATOR_CONFIG")

    printf %s "${compose//${separator:-:}/ }"
    return "$OK_CODE"
}

get_composes() {
    info "Stack Composes ready:"
    printf "%s\n" $(parse_compose)
    return "$OK_CODE"
}

add_composes() {
    local pattern="(${DEVILBOX_COMPOSE_DIR}${DEVILBOX_COMPOSE_FILE_PATTERN}${1//[ ,]/})$|(${DEVILBOX_COMPOSE_DIR}${DEVILBOX_COMPOSE_FILE_PATTERN}})$"
    current=$(get_config "$COMPOSE_FILE_CONFIG")
    current=$(printf "%s\n" ${current//:/ } | grep -Eo ".*${pattern}" | sed "s|${DEVILBOX_COMPOSE_DIR}${DEVILBOX_COMPOSE_FILE_PATTERN}| |g")
    set_composes "$current ${1}"
    return "$OK_CODE"
}

remove_composes() {
    local pattern="(${DOCKER_COMPOSE_FILE})$|(${DOCKER_COMPOSE_OVERRIDE_FILE})$|(${DEVILBOX_COMPOSE_DIR}${DEVILBOX_COMPOSE_FILE_PATTERN}${1//[ ,]/})$|(${DEVILBOX_COMPOSE_DIR}${DEVILBOX_COMPOSE_FILE_PATTERN}})$"
    current=$(get_config "$COMPOSE_FILE_CONFIG")
    current=$(printf "%s\n" ${current//:/ } | grep -Ev ".*${pattern}" | sed "s|${DEVILBOX_COMPOSE_DIR}${DEVILBOX_COMPOSE_FILE_PATTERN}| |g")
    set_composes $current
    return "$OK_CODE"
}

check_composes () {
   if ! is_variable_existing "$COMPOSE_PATH_SEPARATOR_CONFIG"; then
       sed -i -e "$ a \\\n${COMPOSE_PATH_SEPARATOR_CONFIG}" "$ENV_FILE"
       if was_error; then
           return "$KO_CODE"
       fi
   fi
   if ! is_variable_existing "$COMPOSE_FILE_CONFIG"; then
       sed -i -e "$ a ${COMPOSE_FILE_CONFIG}" "$ENV_FILE"
       if was_error; then
           return "$KO_CODE"
       fi
   fi

   return "$OK_CODE"
}

set_composes() {
    local composes=$(echo ${1} | xargs -n1 | uniq | xargs| sed "s| |,|g")
    composes=$(get_composes_string $composes)

    if ! check_composes; then
        return "$KO_CODE"
    fi

    set_readable_config "COMPOSE_FILE" "$COMPOSE_FILE_CONFIG" "$composes"
    return "$OK_CODE"
}

## Functions used to manipulate a config value in .env file

get_config () {
    local config=$1
    local current
    if ! is_variable_existing "$config"; then
        return "$KO_CODE"
    fi
    current=$(grep -Eo "^$config+[[:print:]]*" "$ENV_FILE" | sed "s/.*$config//g")
    if was_success ;then
        printf "%s" "$current"
        return "$OK_CODE"
    else
        return "$KO_CODE"
    fi
}

set_config () {
    local config=$1
    local new=$2
    local current
    current=$(get_config "$config")
    if was_error; then
        return "$KO_CODE"
    fi
    local safe_current=$(printf "%s" "$current" | sed 's/[^[:alnum:]]/\\&/g')
    local safe_new=$(printf "%s" "$new" | sed 's/[^[:alnum:]]/\\&/g')
    sed -i -e "s/\(^#*$config$safe_current\).*/$config$safe_new/" "$ENV_FILE"
    if was_error; then
        return "$KO_CODE"
    fi
    current="$(get_config "$config")"
    if was_success && [[ "$current" = "$new" ]]; then
        return "$OK_CODE"
    else
        return "$KO_CODE"
    fi
}

### READABLE VERSIONS

get_readable_current_config () {
    local type=$1
    local config=$2
    local current
    current=$(get_config "$config")
    if was_success; then
        info "$type current config is $current"
        return "$OK_CODE"
    else
        error "Couldnt retrieve current config of $type"
        return "$KO_CODE"
    fi
}

set_readable_config () {
    local type=$1
    local config=$2
    local new=$3
    if set_config "$config" "$new"; then
        success "$type config updated to $new"
        return "$OK_CODE"
    else
        error "$type config change failed"
        return "$KO_CODE"
    fi
}

## Functions used to manipulate containers in .env file

get_default_containers() {
    local current=$(get_config "$DEVILBOX_CONTAINERS_CONFIG")
    if was_success && [ -n "$current" ]; then
        printf %s "${current//,/ }"
    elif [ -n "$DEVILBOX_CONTAINERS" ]; then
        printf %s "${DEVILBOX_CONTAINERS}"
    else
        printf %s "httpd php mysql"
    fi
}

get_containers() {
    info "Stack Containers ready:"
    printf "%s\n" $(get_default_containers)
    return "$OK_CODE"
}

set_containers() {
    local containers=${1// /,}

    if ! is_variable_existing "$DEVILBOX_CONTAINERS_CONFIG"; then
        sed -i -e "$ a \\\n${DEVILBOX_CONTAINERS_CONFIG}" "$ENV_FILE"
        if was_error; then
            return "$KO_CODE"
        fi
    fi
    set_readable_config "DEVILBOX_CONTAINERS" "$DEVILBOX_CONTAINERS_CONFIG" "$containers"
    return "$OK_CODE"
}

is_running () {
    local all
    all=$($DOCKER_COMPOSE "ps" 2> /dev/null | grep "devilbox" | awk '{print $4}' | grep "running")
    if was_success; then
        return "$OK_CODE";
    else
        return "$KO_CODE";
    fi
}

## Functions used to manipulate variables values in .env file

get_current_variable_version () {
    local choice=${1^^}
    local config="${choice}="
    get_readable_current_value "$choice" "$config"
}

get_all_variable_versions () {
    local choice=${1^^}
    local config="${choice}="
    if ! is_choice "$config"; then
        get_readable_current_value "$choice" "$config"
    else
        get_readable_all_choices "$choice" "$config"
    fi
}

get_all_variables () {
    local config="="
    get_readable_variables "$config"
}

set_variable_version () {
    local choice=${1^^}
    local new=$2
    local config="${choice}="
    if ! is_choice "$config"; then
        set_readable_config "$choice" "$config" "$new"
    else
        set_readable_choice "$choice" "$config" "$new"
    fi
}

get_variables () {
    local config=$1
    local all
    all=$(grep -Eo "^[^#][[:print:]]*$config+[[:print:]]*" "$ENV_FILE")
    if was_success && [ ! -z "$all" ] ;then
        printf "%s\n" "$all"
        return "$OK_CODE"
    else
        return "$KO_CODE"
    fi
}

get_readable_variables () {
    local config=$1
    local all
    all=$(get_variables "$config")
    if was_success; then
        info "All available variables:"
        printf "%s\n" "$all"
        return "$OK_CODE"
    else
        error "Couldnt retrive available variables"
        return "$KO_CODE"
    fi
}

get_readable_current_value () {
    local type=$1
    local config=$2
    local current
    current=$(get_current_choice "$config")
    if was_success; then
        info "$type current value is $current"
        return "$OK_CODE"
    else
        error "Couldnt retrieve current value of $type"
        return "$KO_CODE"
    fi
}

is_variable_existing () {
    local config=$1
    local current=$(grep --max-count=1 -Ec "^*$config+[[:print:]]*" "$ENV_FILE")
    if was_success && [[ $current -gt 0 ]] ; then
        return "$OK_CODE"
    else
        return "$KO_CODE"
    fi
}

check_command () {
    ./check-config.sh
}

config_command () {
    if [[ $# -eq 0 ]] ; then
        get_all_variables
    else
        for arg in "$@"; do
            case $arg in
                -h=\*|--httpd=\*) get_all_choice_versions "Httpd" "$HTTPD_CONFIG"; shift;;
                -h=*|--httpd=*) set_choice_version "Httpd" "$HTTPD_CONFIG" "${arg#*=}"; shift;;
                -h|--httpd) get_current_choice_version "Httpd" "$HTTPD_CONFIG"; shift;;
                -p=\*|--php=\*) get_all_choice_versions "PHP" "$PHP_CONFIG"; shift;;
                -p=*|--php=*) set_choice_version "PHP" "$PHP_CONFIG" "${arg#*=}"; shift;;
                -p|--php) get_current_choice_version "PHP" "$PHP_CONFIG" ; shift;;
                -m=\*|--mysql=\*) get_all_choice_versions "MySql" "$MYSQL_CONFIG"; shift;;
                -m=*|--mysql=*) set_choice_version "MySql" "$MYSQL_CONFIG" "${arg#*=}"; shift;;
                -m|--mysql) get_current_choice_version "MySql" "$MYSQL_CONFIG"; shift;;
                -pg=\*|--pgsql=\*) get_all_choice_versions "PostgreSQL" "$PGSQL_CONFIG"; shift;;
                -pg=*|--pgsql=*) set_choice_version "PostgreSQL" "$PGSQL_CONFIG" "${arg#*=}"; shift;;
                -pg|--pgsql) get_current_choice_version "PostgreSQL" "$PGSQL_CONFIG"; shift;;
                -rd=\*|--redis=\*) get_all_choice_versions "Redis" "$REDIS_CONFIG"; shift;;
                -rd=*|--redis=*) set_choice_version "Redis" "$REDIS_CONFIG" "${arg#*=}"; shift;;
                -rd|--redis) get_current_choice_version "Redis" "$REDIS_CONFIG"; shift;;
                -mc=\*|--memcached=\*) get_all_choice_versions "Memcached" "$MEMCD_CONFIG"; shift;;
                -mc=*|--memcached=*) set_choice_version "Memcached" "$MEMCD_CONFIG" "${arg#*=}"; shift;;
                -mc|--memcached) get_current_choice_version "Memcached" "$MEMCD_CONFIG"; shift;;
                -mg=\*|--mongo=\*) get_all_choice_versions "MongoDB" "$MONGO_CONFIG"; shift;;
                -mg=*|--mongo=*) set_choice_version "MongoDB" "$MONGO_CONFIG" "${arg#*=}"; shift;;
                -mg|--mongo) get_current_choice_version "MongoDB" "$MONGO_CONFIG"; shift;;
                -r=*|--root=*) set_readable_config "Document root" "$DOCROOT_CONFIG" "${arg#*=}"; shift;;
                -r|--root) get_readable_current_config "Document root" "$DOCROOT_CONFIG"; shift;;
                -w=*|--www=*) set_readable_config "Projects path" "$WWWPATH_CONFIG" "${arg#*=}"; shift;;
                -w|--www) get_readable_current_config "Projects path" "$WWWPATH_CONFIG"; shift;;
                -v|--variables) get_all_variables; shift;;
                -v=*\*|--variable=*\*) local val=${arg#*=}; get_all_variable_versions "${val%%\**}"; shift;;
                -v=*\=*|--variable=*\=*) local val=${arg#*=}; set_variable_version "${val%%=*}" "${arg##*=}"; shift;;
                -v=*|--variable=*) get_current_variable_version "${arg#*=}"; shift;;
                -c=*|--containers=*) set_containers "${arg#*=}"; shift;;
                -c|--containers) get_containers; shift;;
                -cs\+=*|--composes\+=*) add_composes "${arg#*=}"; shift;;
                -cs\-=*|--composes\-=*) remove_composes "${arg#*=}"; shift;;
                -cs=*|--composes=*) set_composes "${arg#*=}"; shift;;
                -cs|--composes) get_composes; shift;;
            esac
        done
    fi
}

status_command () {
    $DOCKER_COMPOSE ps
}

enter_command () {
    if ! is_running; then
        error "Devilbox containers are not running"
        return "$KO_CODE"
    fi
    ./shell.sh
}

exec_command() {
    if ! is_running; then
        error "Devilbox containers are not running"
        return "$KO_CODE"
    fi

    $DOCKER_COMPOSE exec -u devilbox php bash -c "$@"
}

add_usage_command () {
    local command=$1
    local description=$2
    printf '%-35s\t %s\n' "$command" "${COLOR_DARK_GRAY}$description${COLOR_DEFAULT}"
}

add_usage_arg () {
    local arg=$1
    local description=$2
    printf '%-40s\t %s\n' "  ${COLOR_LIGHT_GRAY}$arg" "${COLOR_DARK_GRAY}$description${COLOR_DEFAULT}"
}

help_command () {
    printf "\n"
    printf "%s\n" "Usage: $0 <command> [--args]... "
    printf "\n"
    add_usage_command "check" "Check your .env file for potential errors"
    add_usage_command "c,config" "Show / Edit the current config"
    add_usage_arg "-h=*,--httpd=*" "Get all available HTTPD versions"
    add_usage_arg "-p=*,--php=*" "Get all available PHP versions"
    add_usage_arg "-m=*,--mysql=*" "Get all available MySQL versions"
    add_usage_arg "-pg=*,--pgsql=*" "Get all available PostgreSQL versions"
    add_usage_arg "-rd=*,--redis=*" "Get all available Redis versions"
    add_usage_arg "-mc=*,--memcached=*" "Get all available Memcached versions"
    add_usage_arg "-mg=*,--mongo=*" "Get all available MongoDB versions"
    add_usage_arg "-p,--php" "Get current PHP version"
    add_usage_arg "-h,--httpd" "Get current HTTPD version"
    add_usage_arg "-m,--mysql" "Get current MySQL version"
    add_usage_arg "-pg,--pgsql" "Get current PostgreSQL version"
    add_usage_arg "-rd,--redis" "Get current Redis version"
    add_usage_arg "-mc,--memcached" "Get current Memcached version"
    add_usage_arg "-mg,--mongo" "Get current MongoDB version"
    add_usage_arg "-r=<path>,--root=<path>" "Set the document root"
    add_usage_arg "-r,--root" "Get the current document root"
    add_usage_arg "-w=<path>,--www=<path>" "Set the path to projects"
    add_usage_arg "-w,--www" "Get the current path to projects"
    add_usage_arg "-h=<version>,--httpd=<version>" "Set a specific HTTPD version"
    add_usage_arg "-p=<version>,--php=<version>" "Set a specific PHP version"
    add_usage_arg "-m=<version>,--mysql=<version>" "Set a specific MySQL version"
    add_usage_arg "-pg=<version>,--pgsql=<version>" "Set a specific PostgreSQL version"
    add_usage_arg "-rd=<version>,--redis=<version>" "Set a specific Redis version"
    add_usage_arg "-mc=<version>,--memcached=<version>" "Set a specific Memcached version"
    add_usage_arg "-mg=<version>,--mongo=<version>" "Set a specific MongoDB version"
    add_usage_arg "-v,--variables" "Show all available variables"
    add_usage_arg "-v=<var>,--variable=<var>" "Get current variable value"
    add_usage_arg "-v=<var>*,--variable=<var>*" "Get all this variable versions"
    add_usage_arg "-v=<var>=<val>,--variable=<var>=<val>" "Set a specific variable value"
    add_usage_arg "-c,--containers" "Show containers"
    add_usage_arg "-c=<val>,--containers=<val>" "Set containers"
    add_usage_arg "-cs,--composes" "Show composes"
    add_usage_arg "-cs=<val>,--composes=<val>" "Set composes"
    add_usage_arg "-cs+=<val>,--composes+=<val>" "Add composes"
    add_usage_arg "-cs-=<val>,--composes-=<val>" "Remove composes"
    add_usage_command "s,status" "Show status the current stack"
    add_usage_command "e,enter" "Enter the devilbox shell"
    add_usage_command "x, exec '<command>'" "Execute a command inside the container without entering it"
    add_usage_command "h, help" "List all available commands"
    add_usage_command "mysql ['<query>']" "Launch a preconnected mysql shell, with optional query"
    add_usage_command "o,open" "Open the devilbox intranet"
    add_usage_arg "-h,--http" "Use non-https url"
    add_usage_command "restart" "Restart the devilbox docker containers"
    add_usage_arg "-s,--silent" "Hide errors and run in background"
    add_usage_command "r,run" "Run the devilbox docker containers"
    add_usage_arg "-s,--silent" "Hide errors and run in background"
    add_usage_command "s,stop" "Stop devilbox and docker containers"
    add_usage_arg "-r,--remove" "Stop and remove service containers"
    add_usage_command "d,down" "Stop all containers and removes containers, networks, volumes, and images created by up or start"
    add_usage_arg "-o,--orphans" "Remove containers for services not defined in the Compose file."
    add_usage_arg "-v,--volumes" "Remove named volumes declared in the volumes section of the Compose file and anonymous volumes attached to containers."
    add_usage_command "rm,remove" "Removes all containers"
    add_usage_arg "-f,--force" "Don't ask to confirm removal"
    add_usage_command "u,update" "Update devilbox and docker containers"
    add_usage_command "v, version" "Show version information"
    printf "\n"
}

mysql_command() {
    if ! is_running; then
        error "Devilbox containers are not running"
        return "$KO_CODE"
    fi

    if [ -z "$1" ]; then
        exec_command 'mysql -hmysql -uroot'
    else
        exec_command "mysql -hmysql -uroot -e '$1'"
    fi
}

open_http_intranet () {
    xdg-open "http://localhost/" 2> /dev/null >/dev/null
}

open_https_intranet () {
    xdg-open "https://localhost/" 2> /dev/null >/dev/null
}

open_command () {
    if ! is_running; then
        error "Devilbox containers are not running"
        return "$KO_CODE"
    fi
    if [[ $# -eq 0 ]] ; then
        open_https_intranet
    else
        for arg in "$@"; do
            case $arg in
                -h|--http) open_http_intranet; shift;;
            esac
        done
    fi
}

restart_command() {
    stop_command
    run_command "$@"
}

run_command () {
    if is_running; then
        error "Devilbox containers are already running"
        return "$KO_CODE"
    fi
    if [[ $# -eq 0 ]] ; then
        $DOCKER_COMPOSE up $(get_default_containers)
    else
        for arg in "$@"; do
            case $arg in
                -s|--silent) $DOCKER_COMPOSE up -d $(get_default_containers); shift;;
            esac
        done
    fi
}

stop_command () {
    if ! is_running; then
        error "Devilbox containers are not running"
        return "$KO_CODE"
    fi
    if [[ $# -eq 0 ]] ; then
        $DOCKER_COMPOSE stop
    else
        for arg in "$@"; do
            case $arg in
                -r|--remove) $DOCKER_COMPOSE stop; $DOCKER_COMPOSE rm -f; shift;;
            esac
        done
    fi
}

down_command () {
    if [[ $# -eq 0 ]] ; then
        $DOCKER_COMPOSE down
    else
        for arg in "$@"; do
            case $arg in
                -o|--orphans) $DOCKER_COMPOSE down --remove-orphans; shift;;
                -v|--volumes) $DOCKER_COMPOSE down --volumes; shift;;
            esac
        done
    fi
}

remove_command () {
    if is_running; then
        error "Devilbox containers are already running"
        return "$KO_CODE"
    fi
    if [[ $# -eq 0 ]] ; then
        $DOCKER_COMPOSE rm
    else
        for arg in "$@"; do
            case $arg in
                -f|--force) $DOCKER_COMPOSE rm -f; shift;;
            esac
        done
    fi
}

get_recent_devilbox_versions () {
    local versions
    versions=$(git fetch --tags && git describe --abbrev=0 --tags $(git rev-list --tags --max-count=10))
    if was_success; then
        info "Devilbox available versions:"
        printf "%s\n" "$versions"
        return "$OK_CODE"
    else
        error "Couldnt retrive available versions of devilbox"
        return "$KO_CODE"
    fi
}

latest_version () {
    local latest
    latest=$(git fetch --tags && git describe --abbrev=0 --tags $(git rev-list --tags --max-count=1))
    if was_success; then
        info "Devilbox latest version is $latest"
        return "$OK_CODE"
    else
        error "Couldnt retrieve latest version of devilbox"
        return "$KO_CODE"
    fi
}

set_devilbox_version () {
    local version=$1
    confirm "Did you backup your databases before?"
    if was_success ;then
        git fetch --tags && git checkout $version
        if was_success; then
            success "Devilbox updated to $version, please restart"
            return "$OK_CODE"
        else
            error "Couldnt update devilbox"
            return "$KO_CODE"
        fi
    fi
}

update_command () {
    if is_running; then
        error "Devilbox containers are running, please use devilbox stop"
        return "$KO_CODE"
    fi
    for arg in "$@"; do
        case $arg in
            -v=\*|--version=\*) get_recent_devilbox_versions; shift;;
            -v=*|--version=*) set_devilbox_version "${arg#*=}"; shift;;
            -v=latest|--version=latest) set_devilbox_version "$(latest_version)"; shift;;
            -d|--docker) sh update-docker.sh; shift;;
        esac
    done
}

version_command() {
    printf "\n"
    printf "%s\n" "$NAME v$VERSION ($DATE)"
    printf "%s\n" "${COLOR_LIGHT_GRAY}$DESCRIPTION${COLOR_DEFAULT}"
    printf "%s\n" "${COLOR_LIGHT_GRAY}$LINK${COLOR_DEFAULT}"
    printf "\n"
}

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep "\"$2\":" |                                                # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

safe_cd() {
    local path=$1
    local error_msg=$2
    if [[ ! -d "$path" ]]; then
        error "$error_msg"
    fi
    cd "$path" >/dev/null || error "$error_msg"
}

get_devilbox_path() {
    if [ -n "$DEVILBOX_PATH" ]; then
        printf %s "${DEVILBOX_PATH}"
    else
        printf %s "$HOME/.devilbox"
    fi
}

main () {
    safe_cd "$(get_devilbox_path)" "Devilbox not found, please make sure it is installed in your home directory or use DEVILBOX_PATH in your profile."
    if [[ $# -eq 0 ]] ; then
        version_command
        help_command
    else
        case $1 in
            check) shift; check_command;;
            c|config) shift; config_command "$@";;
            ps|status|--status) shift; status_command;;
            e|enter) shift; enter_command;;
            x|exec) shift; exec_command "$@";;
            h|help|-h|--help) shift; help_command;;
            mysql) shift; mysql_command "$@";;
            o|open) shift; open_command "$@";;
            restart) shift; restart_command "$@";;
            r|run|up) shift; run_command "$@";;
            s|stop) shift; stop_command "$@";;
            d|down) shift; down_command "$@";;
            rm|remove) shift; remove_command "$@";;
            u|update) shift; update_command "$@";;
            v|version|-v|--version) shift; version_command;;
            *) error "Unknown command $arg, see -h for help.";;
        esac
    fi
}

main "$@"

