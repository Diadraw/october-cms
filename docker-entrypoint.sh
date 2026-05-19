#!/bin/bash
set -e

# Create .env file if it doesn't exist (required for key:generate)
if [ ! -f .env ]; then
    echo "Creating .env file from environment variables..."
    touch .env
fi

# Generate key if APP_KEY is not set in the environment or .env
if [ -z "$APP_KEY" ] && ! grep -q "APP_KEY=base64" .env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Wait for DB to be ready
echo "Waiting for database connection..."
# Using a simpler check that doesn't rely on specific artisan commands if they are broken
MAX_RETRIES=30
COUNT=0
until php artisan db:monitor --type=mysql > /dev/null 2>&1 || [ $COUNT -eq $MAX_RETRIES ]; do
  echo "Database is unavailable - sleeping"
  sleep 2
  ((COUNT++))
done

echo "Executing migrations..."
php artisan october:up --force

# Execute the original image entrypoint
exec /opt/docker/bin/entrypoint.sh "$@"
