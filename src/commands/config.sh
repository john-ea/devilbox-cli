config_command () {
    if [[ $# -eq 0 ]] ; then
        get_all_variables
    else
        for arg in "$@"; do
            case $arg in
                -h=\*|--httpd=\*) get_all_choice_versions "Httpd" "$HTTPD_CONFIG"; shift;;
                -h=*|--httpd=*) set_choice_version "Httpd" "$HTTPD_CONFIG" "${arg#*=}"; shift;;
                -h|--httpd) get_current_choice_version "Httpd" "$HTTPD_CONFIG"; shift;;
                -p=\*|--php=\*) get_all_choice_versions "PHP" "$PHP_CONFIG"; shift;;
                -p=*|--php=*) set_choice_version "PHP" "$PHP_CONFIG" "${arg#*=}"; shift;;
                -p|--php) get_current_choice_version "PHP" "$PHP_CONFIG" ; shift;;
                -m=\*|--mysql=\*) get_all_choice_versions "MySql" "$MYSQL_CONFIG"; shift;;
                -m=*|--mysql=*) set_choice_version "MySql" "$MYSQL_CONFIG" "${arg#*=}"; shift;;
                -m|--mysql) get_current_choice_version "MySql" "$MYSQL_CONFIG"; shift;;
                -pg=\*|--pgsql=\*) get_all_choice_versions "PostgreSQL" "$PGSQL_CONFIG"; shift;;
                -pg=*|--pgsql=*) set_choice_version "PostgreSQL" "$PGSQL_CONFIG" "${arg#*=}"; shift;;
                -pg|--pgsql) get_current_choice_version "PostgreSQL" "$PGSQL_CONFIG"; shift;;
                -rd=\*|--redis=\*) get_all_choice_versions "Redis" "$REDIS_CONFIG"; shift;;
                -rd=*|--redis=*) set_choice_version "Redis" "$REDIS_CONFIG" "${arg#*=}"; shift;;
                -rd|--redis) get_current_choice_version "Redis" "$REDIS_CONFIG"; shift;;
                -mc=\*|--memcached=\*) get_all_choice_versions "Memcached" "$MEMCD_CONFIG"; shift;;
                -mc=*|--memcached=*) set_choice_version "Memcached" "$MEMCD_CONFIG" "${arg#*=}"; shift;;
                -mc|--memcached) get_current_choice_version "Memcached" "$MEMCD_CONFIG"; shift;;
                -mg=\*|--mongo=\*) get_all_choice_versions "MongoDB" "$MONGO_CONFIG"; shift;;
                -mg=*|--mongo=*) set_choice_version "MongoDB" "$MONGO_CONFIG" "${arg#*=}"; shift;;
                -mg|--mongo) get_current_choice_version "MongoDB" "$MONGO_CONFIG"; shift;;
                -r=*|--root=*) set_readable_config "Document root" "$DOCROOT_CONFIG" "${arg#*=}"; shift;;
                -r|--root) get_readable_current_config "Document root" "$DOCROOT_CONFIG"; shift;;
                -w=*|--www=*) set_readable_config "Projects path" "$WWWPATH_CONFIG" "${arg#*=}"; shift;;
                -w|--www) get_readable_current_config "Projects path" "$WWWPATH_CONFIG"; shift;;
                -v|--variables) get_all_variables; shift;;
                -v=*\*|--variable=*\*) local val=${arg#*=}; get_all_variable_versions "${val%%\**}"; shift;;
                -v=*\=*|--variable=*\=*) local val=${arg#*=}; set_variable_version "${val%%=*}" "${arg##*=}"; shift;;
                -v=*|--variable=*) get_current_variable_version "${arg#*=}"; shift;;
                -c=*|--containers=*) set_containers "${arg#*=}"; shift;;
                -c|--containers) get_containers; shift;;
                -cs\+=*|--composes\+=*) add_composes "${arg#*=}"; shift;;
                -cs\-=*|--composes\-=*) remove_composes "${arg#*=}"; shift;;
                -cs=*|--composes=*) set_composes "${arg#*=}"; shift;;
                -cs|--composes) get_composes; shift;;
            esac
        done
    fi
}
