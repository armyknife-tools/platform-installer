#!/usr/bin/env bash
# Kubernetes functions for ArmyknifeLabs

# Unset any existing functions to avoid conflicts
unset -f kpods kdesc klogs kexec kpf kall kctx kns kevents kscale 2>/dev/null

# Kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
alias kgi='kubectl get ingress'
alias kgn='kubectl get nodes'

# Get pods with better formatting
kpods() {
    kubectl get pods "${@}" -o wide
}

# Describe resource
kdesc() {
    local type="$1"
    local name="$2"
    kubectl describe "$type" "$name"
}

# Get logs
klogs() {
    local pod="$1"
    shift
    kubectl logs -f "$pod" "${@}"
}

# Execute into pod
kexec() {
    local pod="$1"
    shift
    kubectl exec -it "$pod" -- ${@:-/bin/bash}
}

# Port forward
kpf() {
    local pod="$1"
    local ports="$2"
    kubectl port-forward "$pod" "$ports"
}

# Get all resources in namespace
kall() {
    kubectl get all "${@}"
}

# Switch context
kctx() {
    local context="$1"
    if [ -z "$context" ]; then
        kubectl config get-contexts
    else
        kubectl config use-context "$context"
    fi
}

# Switch namespace
kns() {
    local namespace="$1"
    if [ -z "$namespace" ]; then
        kubectl get namespaces
    else
        kubectl config set-context --current --namespace="$namespace"
    fi
}

# Get events
kevents() {
    kubectl get events --sort-by='.lastTimestamp' "${@}"
}

# Scale deployment
kscale() {
    local deployment="$1"
    local replicas="$2"
    kubectl scale deployment "$deployment" --replicas="$replicas"
}

# Export functions
export -f kpods kdesc klogs kexec kpf kall kctx kns kevents kscale