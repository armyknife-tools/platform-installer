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

# Age encryption for API keys - secure local storage
age-encrypt-key() {
    local name="$1"
    local key="$2"
    local recipient="${3:-$USER@$(hostname)}"
    local output_dir="${ARMYKNIFE_DIR:-$HOME/.armyknife}/encrypted-keys"

    if [ -z "$name" ] || [ -z "$key" ]; then
        echo "Usage: age-encrypt-key <name> <key> [recipient]"
        echo "Example: age-encrypt-key 'OPENAI_API_KEY' 'sk-xxxxx'"
        return 1
    fi

    # Check if age is installed
    if ! command -v age &> /dev/null; then
        ak_error "age is not installed. Run 'make install-security' to install it."
        return 1
    fi

    # Create directory for encrypted keys
    mkdir -p "$output_dir"
    local output_file="$output_dir/${name}.age"

    # Create metadata file
    local metadata="Name: $name
Encrypted: $(date '+%Y-%m-%d %H:%M:%S')
User: $(whoami)@$(hostname)
---
$key"

    # Generate age key if it doesn't exist
    local age_key_file="$HOME/.config/age/keys.txt"
    if [ ! -f "$age_key_file" ]; then
        ak_info "Generating age identity key..."
        mkdir -p "$(dirname "$age_key_file")"
        age-keygen -o "$age_key_file" 2>/dev/null
        chmod 600 "$age_key_file"
        ak_success "Age key generated at $age_key_file"
    fi

    # Encrypt the API key
    echo "$metadata" | age -r "$(age-keygen -y < "$age_key_file")" -o "$output_file"

    if [ $? -eq 0 ]; then
        chmod 600 "$output_file"
        ak_success "API key '$name' encrypted and stored at $output_file"
        ak_info "Decrypt with: age-decrypt-key '$name'"

        # Also create a backup encrypted with passphrase
        local backup_file="$output_dir/${name}.backup.age"
        echo "$metadata" | age -p -o "$backup_file" 2>/dev/null
        ak_info "Backup created with passphrase at $backup_file"
    else
        ak_error "Failed to encrypt API key"
        return 1
    fi
}

# Decrypt age-encrypted API key
age-decrypt-key() {
    local name="$1"
    local output_dir="${ARMYKNIFE_DIR:-$HOME/.armyknife}/encrypted-keys"
    local input_file="$output_dir/${name}.age"

    if [ -z "$name" ]; then
        echo "Usage: age-decrypt-key <name>"
        echo "Example: age-decrypt-key 'OPENAI_API_KEY'"
        return 1
    fi

    if [ ! -f "$input_file" ]; then
        ak_error "Encrypted key file not found: $input_file"
        return 1
    fi

    # Check if age is installed
    if ! command -v age &> /dev/null; then
        ak_error "age is not installed. Run 'make install-security' to install it."
        return 1
    fi

    local age_key_file="$HOME/.config/age/keys.txt"
    if [ ! -f "$age_key_file" ]; then
        ak_error "Age identity key not found. Cannot decrypt."
        return 1
    fi

    # Decrypt and extract just the key value
    age -d -i "$age_key_file" "$input_file" 2>/dev/null | tail -n1
}

# List all age-encrypted keys
list-age-keys() {
    local output_dir="${ARMYKNIFE_DIR:-$HOME/.armyknife}/encrypted-keys"

    if [ ! -d "$output_dir" ]; then
        ak_info "No encrypted keys found"
        return 0
    fi

    ak_info "Age-encrypted API keys:"
    for file in "$output_dir"/*.age; do
        if [ -f "$file" ]; then
            basename "$file" .age | grep -v ".backup"
        fi
    done | sort | uniq
}

# Create encrypted backup of all API keys
backup-api-keys() {
    local backup_file="${1:-$HOME/api-keys-backup-$(date +%Y%m%d-%H%M%S).tar.age}"
    local temp_dir=$(mktemp -d)

    ak_info "Creating encrypted backup of all API keys..."

    # Export from LastPass if available
    if command -v lpass &> /dev/null && lpass status &> /dev/null 2>&1; then
        ak_info "Exporting from LastPass..."
        lpass export --color=never > "$temp_dir/lastpass-export.csv" 2>/dev/null
    fi

    # Export from 1Password if available
    if command -v op &> /dev/null && op account get &> /dev/null 2>&1; then
        ak_info "Exporting from 1Password..."
        op item list --format json > "$temp_dir/1password-export.json" 2>/dev/null
    fi

    # Include age-encrypted keys
    if [ -d "${ARMYKNIFE_DIR:-$HOME/.armyknife}/encrypted-keys" ]; then
        cp -r "${ARMYKNIFE_DIR:-$HOME/.armyknife}/encrypted-keys" "$temp_dir/"
    fi

    # Create tarball and encrypt with age
    tar -czf - -C "$temp_dir" . | age -p -o "$backup_file"

    # Cleanup
    rm -rf "$temp_dir"

    if [ -f "$backup_file" ]; then
        ak_success "Backup created at $backup_file"
        ak_info "This backup is encrypted with a passphrase"
        ak_info "Restore with: restore-api-keys '$backup_file'"
    else
        ak_error "Failed to create backup"
        return 1
    fi
}

# Hybrid approach: Store in password manager AND create age-encrypted backup
secure-api-key() {
    local name="$1"
    local key="$2"
    local provider="${3:-1p}"  # Default to 1Password

    if [ -z "$name" ] || [ -z "$key" ]; then
        echo "Usage: secure-api-key <name> <key> [provider]"
        echo "Example: secure-api-key 'OPENAI_API_KEY' 'sk-xxxxx' '1p'"
        echo "Providers: 1p (1Password), lp (LastPass)"
        return 1
    fi

    ak_info "Securing API key with multiple layers..."

    # Store in password manager
    if [ "$provider" = "1p" ]; then
        add-1p-api-key "$name" "$key" "API Keys"
    elif [ "$provider" = "lp" ]; then
        add-api-key "$name" "$key" "API Keys"
    fi

    # Also create age-encrypted backup
    age-encrypt-key "$name" "$key"

    ak_success "API key secured with $provider and age encryption"
    ak_info "Access methods:"
    echo "  1. Password manager: get-${provider}-api-key '$name'"
    echo "  2. Age decryption: age-decrypt-key '$name'"
    echo "  3. Environment variable (1Password): op://API Keys/$name/api_key"
}

# Export functions
export -f genpass genssh checkssl gpgenc gpgdec b64e b64d sha256sum md5sum
export -f add-api-key get-api-key list-api-keys
export -f add-1p-api-key get-1p-api-key list-1p-api-keys setup-1p-env
export -f age-encrypt-key age-decrypt-key list-age-keys backup-api-keys secure-api-key