#!/bin/bash

# --- 1. CẤU HÌNH MÔI TRƯỜNG (Fix lỗi Composer & Git) ---
# SSM chạy không có $HOME, ta phải gán thủ công để Composer có chỗ lưu cache
export HOME="/root"
# Cho phép Composer chạy dưới quyền root mà không hỏi nhiều
export COMPOSER_ALLOW_SUPERUSER=1

PROJECT_DIR="/var/www/deploy-auto"

echo "Start Deploying..."

# --- 2. FIX LỖI GIT OWNERSHIP ---
# Ép Git tin tưởng thư mục này (Chạy lệnh này mỗi lần deploy để chắc chắn)
git config --global --add safe.directory $PROJECT_DIR

cd $PROJECT_DIR

# --- 3. CẬP NHẬT CODE ---
echo "Pulling Code..."
git fetch --all
git reset --hard origin/main

# --- 4. CHẠY COMPOSER ---
echo "Running Composer..."
# Cài đặt thư viện (Giờ đã có HOME=/root nên sẽ không lỗi nữa)
/usr/bin/composer install --no-dev --optimize-autoloader --no-interaction

# --- 5. LARAVEL COMMANDS ---
echo "Running Migrations..."
php artisan migrate --force

echo "Clearing Cache..."
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# --- 6. PHÂN QUYỀN (Rất quan trọng sau khi chạy bằng root) ---
echo "Setting Permissions..."
# Trả lại quyền sở hữu file cho ec2-user (vì nãy giờ ta chạy bằng root)
chown -R ec2-user:ec2-user $PROJECT_DIR

# Cấp quyền ghi cho folder storage
chmod -R 775 $PROJECT_DIR/storage
chmod -R 775 $PROJECT_DIR/bootstrap/cache

# --- 7. RELOAD NGINX ---
echo "Reloading Nginx..."
systemctl reload nginx

echo "Deploy Success!"