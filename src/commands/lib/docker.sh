is_running () {
    local all
    all=$($DOCKER_COMPOSE "ps" 2> /dev/null | grep "devilbox" | awk '{print $4}' | grep "running")
    if was_success; then
        return "$OK_CODE";
    else
        return "$KO_CODE";
    fi
}
