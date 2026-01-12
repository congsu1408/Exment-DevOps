#!/bin/bash

PROJECT_DIR="/var/www/deploy-auto"
echo "Start Deploying..."

# 1. Root chuẩn bị quyền cho thư mục
# Trả lại nhà cho khổ chủ ec2-user
chown -R ec2-user:ec2-user $PROJECT_DIR

cd $PROJECT_DIR

# --- 2. CHẠY CODE (Dùng quyền ec2-user) ---
# Vì đã chown ở trên, nên ec2-user chạy git thoải mái không cần safe.directory nữa

echo "Pulling Code (as ec2-user)..."
sudo -u ec2-user git fetch --all
sudo -u ec2-user git reset --hard origin/main

echo "Running Composer (as ec2-user)..."
sudo -u ec2-user /usr/bin/composer install --no-dev --optimize-autoloader --no-interaction

echo "Running Artisan Commands (as ec2-user)..."
sudo -u ec2-user php artisan migrate --force
sudo -u ec2-user php artisan optimize:clear
sudo -u ec2-user php artisan config:cache
sudo -u ec2-user php artisan route:cache
sudo -u ec2-user php artisan view:cache

# --- 3. CHẠY HỆ THỐNG (Dùng quyền root) ---

echo "Setting Final Permissions..."
chmod -R 775 $PROJECT_DIR/storage
chmod -R 775 $PROJECT_DIR/bootstrap/cache

echo "Reloading Nginx..."
systemctl reload nginx

echo "Deploy Success!"