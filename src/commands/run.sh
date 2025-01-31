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
