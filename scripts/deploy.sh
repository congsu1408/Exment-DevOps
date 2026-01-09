#!/bin/bash

# --- CẤU HÌNH ---
# Đường dẫn thư mục code trên server (bạn vừa clone vào đây)
PROJECT_DIR="/var/www/deploy-auto"

# --- BẮT ĐẦU ---
echo "Start Deploying..."
cd $PROJECT_DIR

# 1. Cập nhật code mới nhất từ GitHub
# (Lệnh git reset --hard sẽ ép code giống hệt GitHub, bỏ qua các thay đổi file rác nếu có)
git fetch --all
git reset --hard origin/main

# 2. Cài đặt thư viện PHP (Composer)
# --no-dev: Không cài thư viện test cho nhẹ
# --optimize-autoloader: Tăng tốc độ load class
echo "Running Composer..."
composer install --no-dev --optimize-autoloader --no-interaction

# 3. Chạy các lệnh của Laravel/Exment
echo "Running Migrations & Cache..."
# Update cấu trúc Database
php artisan migrate --force

# Xóa và tạo lại cache để nhận config mới
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 4. Phân quyền (QUAN TRỌNG)
# Webserver (Nginx) cần quyền ghi vào thư mục storage
echo "Setting Permissions..."
# Set quyền sở hữu cho user hiện tại (ec2-user)
sudo chown -R ec2-user:ec2-user $PROJECT_DIR
# Cấp quyền ghi cho folder storage và bootstrap/cache
sudo chmod -R 777 $PROJECT_DIR/storage
sudo chmod -R 777 $PROJECT_DIR/bootstrap/cache

# 5. Reload Nginx để chắc chắn code mới được nhận
echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "Deploy Success!"