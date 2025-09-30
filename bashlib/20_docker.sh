#!/usr/bin/env bash
# Docker functions for ArmyknifeLabs

# Unset any existing functions to avoid conflicts
unset -f dps dex dlogs dstop dclean dcu dcd dcr dcl dbuild drun 2>/dev/null

# Docker ps with better formatting
dps() {
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