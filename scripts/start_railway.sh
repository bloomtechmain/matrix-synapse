#!/bin/bash
set -e

# Always copy the clean template first to avoid recursive replacement issues
cp /data/homeserver.yaml.template /data/homeserver.yaml

# Update homeserver.yaml with Railway environment variables

echo "Injecting Railway Database Credentials..."

# 1. Database Configuration
# We search for the specific default values from our homeserver.yaml template
# to avoid accidentally replacing the listener port.
sed -i "s/host: postgres/host: $PGHOST/g" /data/homeserver.yaml
sed -i "s/port: 5432/port: $PGPORT/g" /data/homeserver.yaml
sed -i "s/user: synapse/user: $PGUSER/g" /data/homeserver.yaml
sed -i "s/password: postgres/password: $PGPASSWORD/g" /data/homeserver.yaml
sed -i "s/database: synapse/database: $PGDATABASE/g" /data/homeserver.yaml

# 2. Listener Configuration
# Railway provides a $PORT env var (usually random or 8080/3000).
# We must configure Synapse to listen on this port.
# If PORT is not set, default to 8008.
LISTENER_PORT=${PORT:-8008}
echo "Setting Synapse listener to port $LISTENER_PORT..."
sed -i "s/port: 8008/port: $LISTENER_PORT/g" /data/homeserver.yaml

# Force binding to 0.0.0.0 to ensure external access within the container network
# We insert 'bind_addresses' after the port line
sed -i "/port: $LISTENER_PORT/a \    bind_addresses: ['::', '0.0.0.0']" /data/homeserver.yaml

# 3. Domain and Server Name Configuration
if [ ! -z "$RAILWAY_PUBLIC_DOMAIN" ]; then
    echo "Configuring for domain: $RAILWAY_PUBLIC_DOMAIN"
    
    # Update public_baseurl
    sed -i "s|public_baseurl:.*|public_baseurl: \"https://$RAILWAY_PUBLIC_DOMAIN/\"|g" /data/homeserver.yaml
    
    # Update web_client_location
    sed -i "s|web_client_location:.*|web_client_location: \"https://$RAILWAY_PUBLIC_DOMAIN/\"|g" /data/homeserver.yaml
    
    # Update server_name
    # This changes the matrix ID to @user:your-app.railway.app
    sed -i "s/server_name: \"localhost\"/server_name: \"$RAILWAY_PUBLIC_DOMAIN\"/g" /data/homeserver.yaml
fi

# 4. CORS Configuration
# Allow all origins to ensure Element (hosted on a different domain) can connect.
# We replace the first localhost entry with a wildcard.
sed -i 's|  - "http://localhost:8080"|  - "*"|g' /data/homeserver.yaml

# 5. Suppress Warnings
if grep -q "suppress_key_server_warning" /data/homeserver.yaml; then
    sed -i "s/suppress_key_server_warning:.*/suppress_key_server_warning: true/g" /data/homeserver.yaml
else
    echo "suppress_key_server_warning: true" >> /data/homeserver.yaml
fi

echo "Configuration injection complete. Starting Synapse..."
exec /start.py
