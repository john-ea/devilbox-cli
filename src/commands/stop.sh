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
