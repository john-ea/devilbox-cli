version_command() {
    printf "\n"
    printf "%s\n" "$NAME v$VERSION ($DATE)"
    printf "%s\n" "${COLOR_LIGHT_GRAY}$DESCRIPTION${COLOR_DEFAULT}"
    printf "%s\n" "${COLOR_LIGHT_GRAY}$LINK${COLOR_DEFAULT}"
    printf "\n"
}

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep "\"$2\":" |                                                # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}
