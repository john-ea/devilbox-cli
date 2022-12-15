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
