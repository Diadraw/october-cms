#!/bin/bash
set -e

# 1. Generate key ONLY if it's not already in the environment
# We do this without a .env file to avoid overwriting Dokploy variables
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "null" ]; then
    echo "APP_KEY is missing. You should add a 32-char string to Dokploy env variables."
    # We'll try to generate one for this session at least
    export APP_KEY=$(php -r 'echo "base64:".base64_encode(random_bytes(32));')
fi

# 2. Wait for DB to be ready using a direct PHP check (bypassing artisan config issues)
echo "Waiting for database connection ($DB_HOST)..."
MAX_RETRIES=30
COUNT=0
until php -r "new PDO('mysql:host=$DB_HOST;port=${DB_PORT:-3306}', '$DB_USERNAME', '$DB_PASSWORD');" > /dev/null 2>&1 || [ $COUNT -eq $MAX_RETRIES ]; do
  echo "Database is unavailable - sleeping ($COUNT/$MAX_RETRIES)"
  sleep 2
  ((COUNT++))
done

# 3. Run migrations
echo "Executing migrations..."
php artisan october:up --force

# 4. Execute the original image entrypoint
exec /opt/docker/bin/entrypoint.sh "$@"
