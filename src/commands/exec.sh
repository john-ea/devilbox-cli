exec_command() {
    if ! is_running; then
        error "Devilbox containers are not running"
        return "$KO_CODE"
    fi

    $DOCKER_COMPOSE exec -u devilbox php bash -c "$@"
}
