#!/bin/bash
set -e

# Update homeserver.yaml with Railway environment variables
# Railway provides PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE

echo "Injecting Railway Database Credentials..."
echo "PGHOST: $PGHOST"
echo "PGPORT: $PGPORT"
echo "PGUSER: $PGUSER"
echo "PGDATABASE: $PGDATABASE"

# Check if PGHOST is set, otherwise fail early
if [ -z "$PGHOST" ]; then
    echo "Error: PGHOST environment variable is not set!"
    exit 1
fi

# We use sed to replace the hardcoded local values with environment variables provided by Railway
# We use regex to be flexible with whitespace
sed -i "s/host: .*/host: $PGHOST/g" /data/homeserver.yaml
sed -i "s/port: .*/port: $PGPORT/g" /data/homeserver.yaml
sed -i "s/user: .*/user: $PGUSER/g" /data/homeserver.yaml
sed -i "s/password: .*/password: $PGPASSWORD/g" /data/homeserver.yaml
sed -i "s/database: .*/database: $PGDATABASE/g" /data/homeserver.yaml

# Also update the public_baseurl if RAILWAY_PUBLIC_DOMAIN is set
if [ ! -z "$RAILWAY_PUBLIC_DOMAIN" ]; then
    echo "Setting public_baseurl to https://$RAILWAY_PUBLIC_DOMAIN/"
    # Update public_baseurl
    sed -i "s|public_baseurl:.*|public_baseurl: \"https://$RAILWAY_PUBLIC_DOMAIN/\"|g" /data/homeserver.yaml
    # Update web_client_location as well (optional, but good practice)
    sed -i "s|web_client_location:.*|web_client_location: \"https://$RAILWAY_PUBLIC_DOMAIN/\"|g" /data/homeserver.yaml
fi

# Suppress the key server warning as requested
if grep -q "suppress_key_server_warning" /data/homeserver.yaml; then
    sed -i "s/suppress_key_server_warning:.*/suppress_key_server_warning: true/g" /data/homeserver.yaml
else
    echo "suppress_key_server_warning: true" >> /data/homeserver.yaml
fi

echo "Configuration injection complete. Starting Synapse..."
exec /start.py