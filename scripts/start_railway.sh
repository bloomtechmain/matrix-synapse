#!/bin/bash

# Update homeserver.yaml with Railway environment variables
# Railway provides PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE

echo "Injecting Railway Database Credentials..."

# We use sed to replace the hardcoded local values with environment variables provided by Railway
sed -i "s/host: postgres/host: $PGHOST/g" /data/homeserver.yaml
sed -i "s/port: 5432/port: $PGPORT/g" /data/homeserver.yaml
sed -i "s/user: synapse/user: $PGUSER/g" /data/homeserver.yaml
sed -i "s/password: postgres/password: $PGPASSWORD/g" /data/homeserver.yaml
sed -i "s/database: synapse/database: $PGDATABASE/g" /data/homeserver.yaml

# Also update the public_baseurl if RAILWAY_PUBLIC_DOMAIN is set
if [ ! -z "$RAILWAY_PUBLIC_DOMAIN" ]; then
    echo "Setting public_baseurl to https://$RAILWAY_PUBLIC_DOMAIN/"
    sed -i "s|public_baseurl:.*|public_baseurl: \"https://$RAILWAY_PUBLIC_DOMAIN/\"|g" /data/homeserver.yaml
fi

echo "Starting Synapse..."
exec /start.py