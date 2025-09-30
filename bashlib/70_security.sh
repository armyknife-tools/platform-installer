#!/usr/bin/env bash
# Security functions for ArmyknifeLabs

# Generate secure password
genpass() {
    local length=${1:-20}
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

# Generate SSH key
genssh() {
    local email="$1"
    local keyname="${2:-id_ed25519}"
    if [ -z "$email" ]; then
        ak_error "Email required"
        return 1
    fi
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/$keyname"
}

# Check SSL certificate
checkssl() {
    local domain="$1"
    if [ -z "$domain" ]; then
        ak_error "Domain required"
        return 1
    fi
    echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | \
        openssl x509 -noout -dates
}

# Encrypt/decrypt with GPG
gpgenc() {
    local file="$1"
    gpg --encrypt --armor --output "$file.asc" "$file"
}

gpgdec() {
    local file="$1"
    gpg --decrypt "$file"
}

# Base64 encode/decode
b64e() { echo -n "${@}" | base64; }
b64d() { echo -n "${@}" | base64 -d; }

# Hash functions
sha256sum() { shasum -a 256 "${@}"; }
md5sum() { md5 "${@}"; }

# LastPass API key management
add-api-key() {
    local name="$1"
    local key="$2"
    local folder="${3:-API Keys}"

    # Check for required parameters
    if [ -z "$name" ] || [ -z "$key" ]; then
        echo "Usage: add-api-key <name> <key> [folder]"
        echo "Example: add-api-key 'OpenAI' 'sk-xxxxx' 'API Keys'"
        return 1
    fi

    # Check if lpass is installed
    if ! command -v lpass &> /dev/null; then
        ak_error "LastPass CLI is not installed. Run 'make install-security' to install it."
        return 1
    fi

    # Check if logged in to LastPass
    if ! lpass status &> /dev/null; then
        ak_info "Not logged in to LastPass. Please log in:"
        lpass login
        if [ $? -ne 0 ]; then
            ak_error "Failed to log in to LastPass"
            return 1
        fi
    fi

    # Create the secure note with the API key
    local note_content="API Key: $key
Service: $name
Added: $(date '+%Y-%m-%d %H:%M:%S')
Added by: $(whoami)@$(hostname)"

    # Add the secure note to LastPass
    echo "$note_content" | lpass add --non-interactive --notes "$folder/$name" &> /dev/null

    if [ $? -eq 0 ]; then
        ak_success "API key for '$name' has been securely stored in LastPass"
        ak_info "Access it with: lpass show '$folder/$name'"
    else
        ak_error "Failed to store API key in LastPass"
        return 1
    fi
}

# Retrieve API key from LastPass
get-api-key() {
    local name="$1"
    local folder="${2:-API Keys}"

    if [ -z "$name" ]; then
        echo "Usage: get-api-key <name> [folder]"
        echo "Example: get-api-key 'OpenAI' 'API Keys'"
        return 1
    fi

    # Check if lpass is installed
    if ! command -v lpass &> /dev/null; then
        ak_error "LastPass CLI is not installed. Run 'make install-security' to install it."
        return 1
    fi

    # Check if logged in
    if ! lpass status &> /dev/null; then
        ak_info "Not logged in to LastPass. Please log in:"
        lpass login
        if [ $? -ne 0 ]; then
            ak_error "Failed to log in to LastPass"
            return 1
        fi
    fi

    # Retrieve the API key
    local api_key=$(lpass show "$folder/$name" --notes 2>/dev/null | grep "^API Key:" | cut -d' ' -f3-)

    if [ -n "$api_key" ]; then
        echo "$api_key"
    else
        ak_error "API key '$name' not found in LastPass"
        return 1
    fi
}

# List all stored API keys
list-api-keys() {
    local folder="${1:-API Keys}"

    # Check if lpass is installed
    if ! command -v lpass &> /dev/null; then
        ak_error "LastPass CLI is not installed. Run 'make install-security' to install it."
        return 1
    fi

    # Check if logged in
    if ! lpass status &> /dev/null; then
        ak_info "Not logged in to LastPass. Please log in:"
        lpass login
        if [ $? -ne 0 ]; then
            ak_error "Failed to log in to LastPass"
            return 1
        fi
    fi

    ak_info "API Keys stored in LastPass:"
    lpass ls "$folder" 2>/dev/null | sed 's/.*\///' | sort
}

# 1Password API key management with environment variable references
add-1p-api-key() {
    local name="$1"
    local key="$2"
    local vault="${3:-Private}"

    # Check for required parameters
    if [ -z "$name" ] || [ -z "$key" ]; then
        echo "Usage: add-1p-api-key <name> <key> [vault]"
        echo "Example: add-1p-api-key 'OPENAI_API_KEY' 'sk-xxxxx' 'Development'"
        return 1
    fi

    # Check if op is installed
    if ! command -v op &> /dev/null; then
        ak_error "1Password CLI is not installed. Run 'make install-security' to install it."
        return 1
    fi

    # Check if logged in to 1Password
    if ! op account get &> /dev/null; then
        ak_info "Not logged in to 1Password. Please log in:"
        eval $(op signin)
        if [ $? -ne 0 ]; then
            ak_error "Failed to log in to 1Password"
            return 1
        fi
    fi

    # Create the secure item in 1Password
    op item create \
        --category="API Credential" \
        --title="$name" \
        --vault="$vault" \
        --fields="type=concealed,label=api_key,value=$key" \
        --fields="type=text,label=added_date,value=$(date '+%Y-%m-%d %H:%M:%S')" \
        --fields="type=text,label=added_by,value=$(whoami)@$(hostname)" &> /dev/null

    if [ $? -eq 0 ]; then
        # Get the reference for environment variable
        local reference=$(op item get "$name" --vault="$vault" --format json 2>/dev/null | \
            jq -r '.id' | \
            sed "s/^/op:\/\/$vault\/$name\/api_key/")

        ak_success "API key '$name' has been securely stored in 1Password"
        ak_info "To use as environment variable, add to your .bashrc or .env:"
        echo "export $name='$reference'"
        echo ""
        ak_info "Or use directly with op run:"
        echo "op run --env-file=.env -- your-command"
    else
        ak_error "Failed to store API key in 1Password"
        return 1
    fi
}

# Get API key from 1Password
get-1p-api-key() {
    local name="$1"
    local vault="${2:-Private}"

    if [ -z "$name" ]; then
        echo "Usage: get-1p-api-key <name> [vault]"
        echo "Example: get-1p-api-key 'OPENAI_API_KEY' 'Development'"
        return 1
    fi

    # Check if op is installed
    if ! command -v op &> /dev/null; then
        ak_error "1Password CLI is not installed. Run 'make install-security' to install it."
        return 1
    fi

    # Check if logged in
    if ! op account get &> /dev/null; then
        ak_info "Not logged in to 1Password. Please log in:"
        eval $(op signin)
        if [ $? -ne 0 ]; then
            ak_error "Failed to log in to 1Password"
            return 1
        fi
    fi

    # Retrieve the API key
    op item get "$name" --vault="$vault" --fields label=api_key 2>/dev/null
}

# List all 1Password API keys
list-1p-api-keys() {
    local vault="${1:-Private}"

    # Check if op is installed
    if ! command -v op &> /dev/null; then
        ak_error "1Password CLI is not installed. Run 'make install-security' to install it."
        return 1
    fi

    # Check if logged in
    if ! op account get &> /dev/null; then
        ak_info "Not logged in to 1Password. Please log in:"
        eval $(op signin)
        if [ $? -ne 0 ]; then
            ak_error "Failed to log in to 1Password"
            return 1
        fi
    fi

    ak_info "API Keys stored in 1Password vault '$vault':"
    op item list --vault="$vault" --categories="API Credential" --format json 2>/dev/null | \
        jq -r '.[].title' | sort
}

# Setup environment variables from 1Password
setup-1p-env() {
    local env_file="${1:-.env}"
    local vault="${2:-Private}"

    if ! command -v op &> /dev/null; then
        ak_error "1Password CLI is not installed"
        return 1
    fi

    ak_info "Creating $env_file with 1Password references..."

    # Get all API credentials from vault
    local items=$(op item list --vault="$vault" --categories="API Credential" --format json 2>/dev/null | \
        jq -r '.[].title')

    > "$env_file"  # Clear or create file

    for item in $items; do
        local reference="op://$vault/$item/api_key"
        echo "export $item='$reference'" >> "$env_file"
        ak_success "Added reference for $item"
    done

    ak_info "Environment file created. Use with: op run --env-file=$env_file -- your-command"
}

# Export functions
export -f genpass genssh checkssl gpgenc gpgdec b64e b64d sha256sum md5sum
export -f add-api-key get-api-key list-api-keys
export -f add-1p-api-key get-1p-api-key list-1p-api-keys setup-1p-env