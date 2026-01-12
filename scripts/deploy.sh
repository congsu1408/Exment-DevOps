#!/bin/bash

# --- 1. ENVIRONMENT SETUP (Fix Composer & Git issues) ---
# SSM runs without $HOME, so we set it manually so Composer has a place to store cache
export HOME="/root"
# Allow Composer to run as root without prompting
export COMPOSER_ALLOW_SUPERUSER=1

PROJECT_DIR="/var/www/deploy-auto"

echo "Start Deploying..."

# --- 2. FIX GIT OWNERSHIP ISSUE ---
# Mark this directory as trusted (run this each deploy to be safe)
git config --global --add safe.directory $PROJECT_DIR

cd $PROJECT_DIR

# --- 3. UPDATE CODE ---
echo "Pulling Code..."
git fetch --all
git reset --hard origin/main

# --- 4. RUN COMPOSER ---
echo "Running Composer..."
# Install dependencies (HOME=/root is set, so this should no longer error)
/usr/bin/composer install --no-dev --optimize-autoloader --no-interaction

# --- 5. LARAVEL COMMANDS ---
echo "Running Migrations..."
php artisan migrate --force

echo "Clearing Cache..."
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# --- 6. PERMISSIONS (Very important after running as root) ---
echo "Setting Permissions..."
# Restore file ownership to ec2-user (since we have been running as root)
chown -R ec2-user:ec2-user $PROJECT_DIR

# Grant write permissions for storage
chmod -R 775 $PROJECT_DIR/storage
chmod -R 775 $PROJECT_DIR/bootstrap/cache

# --- 7. RELOAD NGINX ---
echo "Reloading Nginx..."
systemctl reload nginx

echo "Deploy Success!"