#!/bin/bash

PROJECT_DIR="/var/www/deploy-auto"
echo "Start Deploying..."

# 1. Root prepares permissions for the directory first
# To ensure ec2-user can write here
chown -R ec2-user:ec2-user $PROJECT_DIR

# Fix the Git "dubious ownership" issue for both root and ec2-user
git config --global --add safe.directory $PROJECT_DIR

cd $PROJECT_DIR

# --- 2. RUN CODE-RELATED COMMANDS (as ec2-user) ---
# Use sudo -u ec2-user to use ec2-user's SSH key

echo "Pulling Code (as ec2-user)..."
sudo -u ec2-user git fetch --all
sudo -u ec2-user git reset --hard origin/main

echo "Running Composer (as ec2-user)..."
# Run Composer as ec2-user to avoid the "Do not run as root" warning
sudo -u ec2-user /usr/bin/composer install --no-dev --optimize-autoloader --no-interaction

echo "Running Artisan Commands (as ec2-user)..."
sudo -u ec2-user php artisan migrate --force
sudo -u ec2-user php artisan optimize:clear
sudo -u ec2-user php artisan config:cache
sudo -u ec2-user php artisan route:cache
sudo -u ec2-user php artisan view:cache

# --- 3. RUN SYSTEM COMMANDS (as root by default) ---

echo "Setting Final Permissions..."
# Ensure storage is writable
chmod -R 775 $PROJECT_DIR/storage
chmod -R 775 $PROJECT_DIR/bootstrap/cache

echo "Reloading Nginx..."
systemctl reload nginx

echo "Deploy Success!"