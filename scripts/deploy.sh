#!/bin/bash

PROJECT_DIR="/var/www/deploy-auto"
echo "Start Deploying..."

# 1. Root chuẩn bị quyền cho thư mục trước
# Để đảm bảo ec2-user có thể ghi vào đây
chown -R ec2-user:ec2-user $PROJECT_DIR

# Fix lỗi git dubious cho cả root và ec2-user
git config --global --add safe.directory $PROJECT_DIR

cd $PROJECT_DIR

# --- 2. CHẠY CÁC LỆNH LIÊN QUAN ĐẾN CODE (Dùng quyền ec2-user) ---
# Dùng sudo -u ec2-user để mượn chìa khóa SSH của ec2-user

echo "Pulling Code (as ec2-user)..."
sudo -u ec2-user git fetch --all
sudo -u ec2-user git reset --hard origin/main

echo "Running Composer (as ec2-user)..."
# Chạy composer bằng ec2-user luôn để tránh lỗi warning "Do not run as root"
sudo -u ec2-user /usr/bin/composer install --no-dev --optimize-autoloader --no-interaction

echo "Running Artisan Commands (as ec2-user)..."
sudo -u ec2-user php artisan migrate --force
sudo -u ec2-user php artisan optimize:clear
sudo -u ec2-user php artisan config:cache
sudo -u ec2-user php artisan route:cache
sudo -u ec2-user php artisan view:cache

# --- 3. CHẠY CÁC LỆNH HỆ THỐNG (Dùng quyền root mặc định) ---

echo "Setting Final Permissions..."
# Đảm bảo storage ghi được
chmod -R 775 $PROJECT_DIR/storage
chmod -R 775 $PROJECT_DIR/bootstrap/cache

echo "Reloading Nginx..."
systemctl reload nginx

echo "Deploy Success!"