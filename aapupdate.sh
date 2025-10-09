#!/bin/bash

# Get the directory of the script and source common functions
parent_dir=$(dirname "$(readlink -f "$0")")
script_vars_dir="$parent_dir/script_vars"
# shellcheck source=common_functions.sh
source "$parent_dir/common_functions.sh"

# --- Main usage function ---
usage() {
    local casc_aap_version_context=$1
    local script_vars_file="$script_vars_dir/${casc_aap_version_context:-2.6}/vars.yml"

    echo "Usage: $0 <org> <env> [-a|--all] [-t|--tags <tags>]"
    echo ""

    if [[ ! -f "$script_vars_file" ]]; then
        echo "Warning: Tag definition file not found for version '$casc_aap_version_context'."
        exit 1
    fi
    
    echo "Specific Tags Supported:"
    yq '(.aapupdate_specific_tags | keys)[]' "$script_vars_file" | while read -r category; do
        echo "  $category:"
        tags=$(yq ".aapupdate_specific_tags[\"$category\"] | join(\", \")" "$script_vars_file")
        echo "    $tags" | fold -s -w 70 | sed 's/^/    /' | sed '1s/    //'
        echo ""
    done
    exit 1
}

# --- Initialize and Validate ---
# Pass "update" to build the correct yq keys, and pass all script arguments with "$@"
initialize_and_validate "update" "$@"

# --- Build and Execute Command ---
cd "$parent_dir" || { echo "Failed to change directory to $parent_dir"; exit 1; }

playbook_args=(
    "aapupdate.yml"
    "-e" "{orgs: $org, dir_orgs_vars: orgs_vars, env: $env}"
    "-e" "@orgs_vars/$org/env/$env/vault.yml"
    "-e" "@orgs_vars/$org/env/common/vault.yml"
)

if [ -n "$tags" ]; then
    playbook_args+=("--tags" "$tags")
fi

echo "Running playbook for AAP version: $casc_aap_version"
ansible-navigator run "${playbook_args[@]}" \
    --mode stdout \
    --pae false \
    --execution-environment-image "$execution_environment" \
    --execution-environment-volume-mounts "$(pwd):/home/user:Z"