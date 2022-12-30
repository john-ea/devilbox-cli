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
