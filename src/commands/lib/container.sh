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
