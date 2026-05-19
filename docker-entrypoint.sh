#!/bin/bash
set -e

# Generate key if it's missing in .env
if ! grep -q "APP_KEY=base64" .env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Wait for DB to be ready
echo "Waiting for database connection..."
until php artisan db:monitor --type=mysql > /dev/null 2>&1; do
  echo "Database is unavailable - sleeping"
  sleep 2
done

echo "Database is up - executing migrations..."
php artisan october:up

# Execute the original image entrypoint
exec /opt/docker/bin/entrypoint.sh "$@"
