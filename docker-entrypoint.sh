#!/bin/bash
set -e

# Fix permissions for mounted volumes
mkdir -p /workspace/frappe-bench/logs /workspace/frappe-bench/sites
chown -R frappe:frappe /workspace/frappe-bench/logs /workspace/frappe-bench/sites 2>/dev/null || true

# Ensure vendored JS libraries exist (they are required for bench build)
cd /workspace/frappe-bench
FRAPPE_LIB_DIR="apps/frappe/frappe/public/js/lib"
if [ ! -d "$FRAPPE_LIB_DIR" ] || [ -z "$(ls -A "$FRAPPE_LIB_DIR" 2>/dev/null)" ]; then
  echo "Populating frappe/public/js/lib from upstream (version-15)..."
  tmp_dir=$(mktemp -d)
  git clone --depth 1 --branch version-15 https://github.com/frappe/frappe.git "$tmp_dir" >/dev/null 2>&1
  mkdir -p "$FRAPPE_LIB_DIR"
  cp -a "$tmp_dir/frappe/public/js/lib/." "$FRAPPE_LIB_DIR"/
  rm -rf "$tmp_dir"
  chown -R frappe:frappe "$FRAPPE_LIB_DIR"
fi

# Install node_modules if missing (needed when apps are mounted as volumes)
# This ensures all services have node_modules available
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
