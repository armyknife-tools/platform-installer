#!/usr/bin/env bash
# Docker functions for ArmyknifeLabs

# Guard to prevent double sourcing
if [ -z "${ARMYKNIFE_DOCKER_LOADED}" ]; then
export ARMYKNIFE_DOCKER_LOADED=1

# Unalias conflicting aliases from oh-my-bash or other plugins
unalias dps 2>/dev/null || true

# Docker ps with better formatting
function dps {
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" "${@}"
}

# Docker exec into container
dex() {
    local container="$1"
    shift
    docker exec -it "$container" ${@:-/bin/bash}
}

# Docker logs with follow
dlogs() {
    docker logs -f "${@}"
}

# Stop all running containers
dstop() {
    local containers=$(docker ps -q)
    if [ -n "$containers" ]; then
        docker stop $containers
    else
        ak_log "No running containers"
    fi
}

# Remove all stopped containers
dclean() {
    docker container prune -f
    docker image prune -f
}

# Docker compose shortcuts
dcu() { docker-compose up "${@}"; }
dcd() { docker-compose down "${@}"; }
dcr() { docker-compose restart "${@}"; }
dcl() { docker-compose logs -f "${@}"; }

# Build Docker image
dbuild() {
    local tag="${1:-latest}"
    docker build -t "$tag" .
}

# Run Docker container with common options
drun() {
    local image="$1"
    shift
    docker run -it --rm "$image" "${@}"
}

# Export functions
export -f dps dex dlogs dstop dclean dcu dcd dcr dcl dbuild drun

fi # End of guard