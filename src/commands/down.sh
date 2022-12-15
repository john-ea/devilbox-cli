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
