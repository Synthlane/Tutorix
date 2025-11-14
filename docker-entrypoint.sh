#!/bin/bash
set -e

# Fix permissions for mounted volumes
mkdir -p /workspace/frappe-bench/logs /workspace/frappe-bench/sites
chown -R frappe:frappe /workspace/frappe-bench/logs /workspace/frappe-bench/sites 2>/dev/null || true

# Install node_modules if missing (needed when apps are mounted as volumes)
# This ensures all services have node_modules available
cd /workspace/frappe-bench
if [ ! -d "apps/frappe/node_modules" ]; then
  echo "Installing node_modules for frappe..."
  gosu frappe bash -c "cd apps/frappe && yarn install"
fi
if [ -d "apps/lms" ] && [ ! -d "apps/lms/node_modules" ] && [ -f "apps/lms/package.json" ]; then
  echo "Installing node_modules for lms..."
  gosu frappe bash -c "cd apps/lms && yarn install"
fi
if [ -d "apps/lms/frontend" ] && [ ! -d "apps/lms/frontend/node_modules" ] && [ -f "apps/lms/frontend/package.json" ]; then
  echo "Installing node_modules for lms frontend..."
  gosu frappe bash -c "cd apps/lms/frontend && yarn install"
fi

# Execute the command as frappe user
exec gosu frappe "$@"
