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
