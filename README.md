# Tutorix LMS - Setup and Development Guide

This guide will help you set up and run the Tutorix Learning Management System (LMS) built on Frappe Framework.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup Instructions](#detailed-setup-instructions)
- [Running the Application](#running-the-application)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)

## Prerequisites

Before you begin, ensure you have the following installed on your system:

### Required Software

1. **Docker** (version 20.10 or higher)
   - Download from: https://www.docker.com/products/docker-desktop
   - Verify installation: `docker --version`

2. **Docker Compose** (version 2.0 or higher)
   - Usually included with Docker Desktop
   - Verify installation: `docker compose version`

3. **Git**
   - Download from: https://git-scm.com/downloads
   - Verify installation: `git --version`

### System Requirements

- **RAM**: Minimum 4GB (8GB recommended)
- **Disk Space**: At least 10GB free space
- **Operating System**: 
  - macOS (10.15+)
  - Linux (Ubuntu 20.04+, Debian 11+, or similar)
  - Windows 10/11 (with WSL2)

> **Important Note for Mac Users**: The project uses Docker containers running Linux. Node modules installed on Mac will not work inside Linux containers. All builds must happen inside the Docker containers.

## Quick Start

If you're new to the project, follow these steps:

```bash
# 1. Clone the repository
git clone <repository-url>
cd Tutorix

# 2. Start all services
docker compose up -d

# 3. Wait for services to initialize (first time may take 5-10 minutes)
docker compose logs -f backend

# 4. Access the application
# Open your browser and navigate to:
# http://localhost:8000
```

**Default Credentials:**
- **Username**: `Administrator`
- **Password**: `admin`

## Detailed Setup Instructions

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd Tutorix
```

### Step 2: Review Docker Configuration

The project uses Docker Compose to manage multiple services:

- **MariaDB**: Database server (port 3306)
- **Redis Cache**: Caching layer (port 13001)
- **Redis Queue**: Background job queue (port 11001)
- **Redis SocketIO**: WebSocket support (port 13002)
- **Backend**: Frappe application server (port 8000)
- **Nginx**: Web server and reverse proxy (port 80)
- **Scheduler**: Background task scheduler
- **Worker**: Background job worker
- **SocketIO**: WebSocket server (port 9000)
- **Watch**: File watcher for development
- **Reload Watcher**: Auto-reload on file changes

### Step 3: Start Docker Services

```bash
# Start all services in detached mode
docker compose up -d

# View logs to monitor startup
docker compose logs -f
```

### Step 4: Wait for Initial Setup

On first run, Docker will:
1. Pull required images
2. Create and configure the database
3. Install Frappe and LMS apps
4. Build frontend assets
5. Set up the site

This process can take **5-10 minutes** on first run. Monitor progress with:

```bash
docker compose logs -f backend
```

Look for messages like:
- `Creating new site: tutorix.local`
- `Installing lms...`
- `Starting Frappe...`

### Step 5: Access the Application

Once services are running:

1. **Web Interface**: http://localhost:8000
2. **Admin Panel**: http://localhost:8000/app
3. **API**: http://localhost:8000/api

**Default Login:**
- Username: `Administrator`
- Password: `admin`

## Running the Application

### Start Services

```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d backend

# Start with logs visible
docker compose up
```

### Stop Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes (⚠️ deletes data)
docker compose down -v
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f nginx
docker compose logs -f scheduler
```

### Restart Services

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart backend
```

## Development Workflow

### Frontend Development

The frontend is built with Vue.js and Vite. Changes are automatically detected:

```bash
# View frontend build logs
docker compose logs -f watch

# Rebuild frontend manually (if needed)
docker compose exec backend bash -c 'export NODE_OPTIONS="--max-old-space-size=4096" && cd /workspace/frappe-bench/apps/lms/frontend && yarn build'
```

### Backend Development

Backend changes (Python files) are automatically reloaded. No restart needed.

### Database Migrations

When database schema changes are made:

```bash
# Run migrations
docker compose exec backend bench --site tutorix.local migrate
```

### Clear Cache

If you encounter caching issues:

```bash
# Clear application cache
docker compose exec backend bench --site tutorix.local clear-cache

# Restart services
docker compose restart backend
```

### Rebuild Assets

If frontend assets are missing or outdated:

```bash
# Rebuild all assets
docker compose exec backend bash -c 'export NODE_OPTIONS="--max-old-space-size=4096" && cd /workspace/frappe-bench && bench build --apps lms'
```

## Troubleshooting

### Issue: Services Won't Start

**Solution:**
```bash
# Check Docker is running
docker ps

# Check for port conflicts
# Ensure ports 80, 8000, 3306, 11001, 13001, 13002, 9000 are available

# View error logs
docker compose logs
```

### Issue: Database Connection Errors

**Solution:**
```bash
# Check MariaDB is running
docker compose ps mariadb

# Restart database
docker compose restart mariadb

# Wait for database to be ready
docker compose logs -f mariadb
```

### Issue: Frontend Assets Not Loading (404 errors)

**Common on Mac**: This happens when macOS `node_modules` are mounted into Linux containers.

**Solution:**
```bash
# Remove host-side node_modules (they're platform-specific)
rm -rf apps/frappe/node_modules
rm -rf apps/lms/node_modules
rm -rf apps/lms/frontend/node_modules

# Restart services
docker compose down
docker compose up -d

# Rebuild assets inside container
docker compose exec backend bash -c 'export NODE_OPTIONS="--max-old-space-size=4096" && cd /workspace/frappe-bench/apps/lms/frontend && yarn build'
```

### Issue: Out of Memory (OOM) Errors

**Solution:**
The project already includes increased Node.js memory limits. If you still encounter issues:

```bash
# Check available memory
docker stats

# Increase Docker Desktop memory allocation:
# Docker Desktop -> Settings -> Resources -> Memory (set to 8GB+)
```

### Issue: Site Not Found

**Solution:**
```bash
# Check if site exists
docker compose exec backend bench --site tutorix.local list-apps

# Recreate site (⚠️ deletes data)
docker compose exec backend bash -c 'rm -rf /workspace/frappe-bench/sites/tutorix.local && bench new-site tutorix.local --mariadb-root-password synthlane_root_pass --admin-password admin --no-mariadb-socket --force && bench --site tutorix.local install-app payments && bench --site tutorix.local install-app lms'
```

### Issue: Cannot Access Application

**Solution:**
```bash
# Check if services are running
docker compose ps

# Check nginx logs
docker compose logs nginx

# Verify port 80 is not in use
# On Mac/Linux: lsof -i :80
# On Windows: netstat -ano | findstr :80

# Try accessing directly via backend
# http://localhost:8000 (bypasses nginx)
```

### Issue: Logo or Assets Not Updating

**Solution:**
```bash
# Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)

# Rebuild frontend
docker compose exec backend bash -c 'export NODE_OPTIONS="--max-old-space-size=4096" && cd /workspace/frappe-bench/apps/lms/frontend && yarn build'

# Clear browser cache
```

## Project Structure

```
Tutorix/
├── apps/
│   ├── frappe/          # Frappe Framework core
│   ├── lms/             # LMS application
│   │   ├── frontend/    # Vue.js frontend
│   │   └── lms/         # Python backend
│   └── payments/        # Payments app
├── config/              # Configuration files
├── sites/               # Site data and configuration
├── docker-compose.yml   # Docker services configuration
├── Dockerfile           # Backend container image
├── docker-entrypoint.sh # Container initialization script
└── start.sh            # Backend startup script
```

## Environment Variables

You can customize the setup using environment variables:

```bash
# Set admin password
export ADMIN_PASSWORD=your_password

# Start services with custom password
docker compose up -d
```

## Database Access

To access the database directly:

```bash
# Connect to MariaDB
docker compose exec mariadb mysql -u synthlane_user -psynthlane_pass synthlane_db

# Or use bench command
docker compose exec backend bench --site tutorix.local mariadb
```

**Database Credentials:**
- Host: `mariadb` (from within containers) or `localhost` (from host)
- Port: `3306`
- Database: `synthlane_db`
- User: `synthlane_user`
- Password: `synthlane_pass`
- Root Password: `synthlane_root_pass`

## Useful Commands

```bash
# View all running containers
docker compose ps

# Execute command in backend container
docker compose exec backend <command>

# Access backend shell
docker compose exec backend bash

# View resource usage
docker stats

# Clean up unused Docker resources
docker system prune

# View container logs (last 100 lines)
docker compose logs --tail=100 backend
```

## Additional Resources

- **Frappe Framework Documentation**: https://frappeframework.com/docs
- **LMS Documentation**: Check `apps/lms/README.md`
- **Docker Documentation**: https://docs.docker.com/

## Support

If you encounter issues not covered in this guide:

1. Check the logs: `docker compose logs -f`
2. Review the troubleshooting section above
3. Check GitHub issues (if applicable)
4. Contact the development team

## Notes

- **First Run**: Initial setup takes 5-10 minutes as it downloads dependencies and builds assets
- **Mac Users**: Never install `node_modules` on the host. All builds happen inside containers
- **Port Conflicts**: Ensure ports 80, 8000, 3306, 11001, 13001, 13002, and 9000 are available
- **Data Persistence**: Site data is stored in Docker volumes. Use `docker compose down -v` to remove all data
- **Development Mode**: The application runs in developer mode by default, which enables hot-reloading and debug features

---

**Happy Coding! 🚀**

