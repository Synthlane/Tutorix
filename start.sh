#!/bin/bash
set -e

# Ensure Python output is unbuffered for Docker logs
export PYTHONUNBUFFERED=1

cd /workspace/frappe-bench

# Update common_site_config.json with Docker settings
cat > sites/common_site_config.json <<EOF
{
 "background_workers": 1,
 "db_host": "mariadb",
 "db_port": "3306",
 "db_type": "mariadb",
 "developer_mode": true,
 "gunicorn_workers": 4,
 "ignore_csrf": 1,
 "redis_cache": "redis://redis-cache:6379",
 "redis_queue": "redis://redis-queue:6379",
 "redis_socketio": "redis://redis-socketio:6379",
 "serve_default_site": true,
 "socketio_port": 9000,
 "webserver_port": 8000
}
EOF

# Create site if it doesn't exist
if [ ! -d sites/tutorix.local ]; then
  echo "Creating new site: tutorix.local"
  bench new-site tutorix.local \
    --mariadb-root-password synthlane_root_pass \
    --admin-password ${ADMIN_PASSWORD:-admin} \
    --no-mariadb-socket \
    --force
  
  echo "Installing payments..."
  bench --site tutorix.local install-app payments
  
  echo "Installing lms..."
  bench --site tutorix.local install-app lms
else
  # Check if site can connect to database, if not, recreate it
  echo "Checking database connection for existing site..."
  if ! bench --site tutorix.local mariadb -e "SELECT 1" >/dev/null 2>&1; then
    echo "Database connection failed. Recreating site with correct credentials..."
    echo "WARNING: This will delete all site data. Press Ctrl+C within 5 seconds to cancel..."
    sleep 5
    rm -rf sites/tutorix.local
    bench new-site tutorix.local \
      --mariadb-root-password synthlane_root_pass \
      --admin-password ${ADMIN_PASSWORD:-admin} \
      --no-mariadb-socket \
      --force
    
    echo "Installing payments..."
    bench --site tutorix.local install-app payments
    
    echo "Installing lms..."
    bench --site tutorix.local install-app lms
  fi
fi

# Run migrations
echo "Running migrations..."
bench --site tutorix.local migrate

# Install node_modules if missing (needed when apps are mounted as volumes)
echo "Checking node_modules..."
if [ ! -d "apps/frappe/node_modules" ]; then
  echo "Installing node_modules for frappe..."
  cd apps/frappe && yarn install && cd ../..
fi
if [ -d "apps/lms" ] && [ ! -d "apps/lms/node_modules" ] && [ -f "apps/lms/package.json" ]; then
  echo "Installing node_modules for lms..."
  cd apps/lms && yarn install && cd ../..
fi
if [ -d "apps/lms/frontend" ] && [ ! -d "apps/lms/frontend/node_modules" ] && [ -f "apps/lms/frontend/package.json" ]; then
  echo "Installing node_modules for lms frontend..."
  cd apps/lms/frontend && yarn install && cd ../../..
fi

# Skip asset build - assets should already be built in Docker image
# Building assets in runtime causes OOM issues, so we skip it
echo "Skipping asset build (assets should be pre-built in Docker image)..."
echo "If assets are missing, they will be built on-demand by the watch service."

# Clear cache
echo "Clearing cache..."
bench --site tutorix.local clear-cache

# Start the application
echo "Starting Frappe..."
exec bench serve --port 8000

