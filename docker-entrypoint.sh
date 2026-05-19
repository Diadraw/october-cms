#!/bin/bash
set -e

# 1. Create .env file if it doesn't exist and ensure APP_KEY placeholder exists
if [ ! -f .env ]; then
    echo "Creating .env file..."
    touch .env
fi

if ! grep -q "APP_KEY=" .env; then
    echo "Adding APP_KEY placeholder to .env..."
    echo "APP_KEY=" >> .env
fi

# 2. Generate key if not already set
# We check both the environment variable and the file content
if { [ -z "$APP_KEY" ] || [ "$APP_KEY" = "null" ]; } && ! grep -q "APP_KEY=base64" .env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# 3. Wait for DB to be ready
echo "Waiting for database connection..."
MAX_RETRIES=30
COUNT=0
until php artisan db:monitor --type=mysql > /dev/null 2>&1 || [ $COUNT -eq $MAX_RETRIES ]; do
  echo "Database is unavailable - sleeping ($COUNT/$MAX_RETRIES)"
  sleep 2
  ((COUNT++))
done

# 4. Run migrations
echo "Executing migrations..."
php artisan october:up --force

# 5. Execute the original image entrypoint
exec /opt/docker/bin/entrypoint.sh "$@"
