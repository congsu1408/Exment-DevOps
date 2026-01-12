#!/bin/bash

# --- CONFIGURATION ---
# Path to the project directory on the server
PROJECT_DIR="/var/www/deploy-auto"

# --- START ---
echo "Start Deploying..."
cd $PROJECT_DIR

# 1. Pull the latest code from GitHub
# (git reset --hard forces the working tree to match GitHub exactly, discarding any local changes)
git fetch --all
git reset --hard origin/main

# 2. Install PHP dependencies (Composer)
# --no-dev: Do not install development/test dependencies
# --optimize-autoloader: Optimize the autoloader for performance
echo "Running Composer..."
composer install --no-dev --optimize-autoloader --no-interaction

# 3. Run Laravel/Exment commands
echo "Running Migrations & Cache..."
# Update database schema
php artisan migrate --force

# Clear and rebuild caches to pick up new configuration
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 4. Permissions (IMPORTANT)
# The web server (Nginx) needs write access to the storage directory
echo "Setting Permissions..."
# Set ownership for the current user (ec2-user)
sudo chown -R ec2-user:ec2-user $PROJECT_DIR
# Grant write permissions for storage and bootstrap/cache
sudo chmod -R 777 $PROJECT_DIR/storage
sudo chmod -R 777 $PROJECT_DIR/bootstrap/cache

# 5. Reload Nginx to ensure the new code is picked up
echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "Deploy Success!"