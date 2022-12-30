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
