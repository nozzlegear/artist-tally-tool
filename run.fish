#! /usr/bin/env fish

function printErr -a msg
    set_color red
    echo "$msg" >&2
    set_color normal
end

# Check that an image name was passed in
if test (count $argv) -eq 0
    printErr "No image given, cannot run tally tool."
    set_color yellow
    echo "Usage: ./script.fish example.azurecr.io/image:version"
    exit 1
end

function log -a msg
    set timestamp (date -u "+%F T%TZ")
    echo "$msg"
end

# A function to format a list of secrets into `podman run` args
function formatSecrets 
    for secret in $argv
        echo "--secret=$secret,type=env"
    end
end

if ! set -q ARTIST_TALLY_ENV
    log "\$ARTIST_TALLY_ENV not set, defaulting to production environment."
    set ARTIST_TALLY_ENV "production"
end

# Set script variables
set IMAGE_NAME "$argv[1]"
set REQUIRED_PODMAN_SECRETS "ARTIST_TALLY_API_DOMAIN" \
    "ARTIST_TALLY_SWU_KEY" \
    "ARTIST_TALLY_SWU_TEMPLATE_ID" \
    "ARTIST_TALLY_CC_LIST" \
    "ARTIST_TALLY_EMAIL_DOMAIN"

# Check that all secrets are set
for secret in $REQUIRED_PODMAN_SECRETS
    if ! podman secret inspect "$secret" > /dev/null
        printErr "podman secret \"$secret\" is missing. You must manually set up secrets on the host before running this script."
        exit 1
    end
end

# Run the container, passing in secrets as environment variables
podman run \
    --rm \
    --env "ARTIST_TALLY_ENV=$ARTIST_TALLY_ENV" \
    (formatSecrets $REQUIRED_PODMAN_SECRETS) \
    "$IMAGE_NAME"
