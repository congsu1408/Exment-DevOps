#!/bin/bash

# --- CONFIG ---
BUCKET_NAME="my-exment-configs"
PROJECT_DIR="/var/www/deploy-auto"
TARGET_VERSION=$1 

# Validate input argument
if [ -z "$TARGET_VERSION" ]; then
    echo "Error: Version is required (e.g., prod-v1.0)."
    exit 1
fi

# S3 file paths
# Code is stored under builds/, .env is stored at bucket root
S3_CODE_PATH="s3://$BUCKET_NAME/builds/source-$TARGET_VERSION.zip"
S3_ENV_PATH="s3://$BUCKET_NAME/.env"

# Log configuration
LOG_FILE="/var/www/deploy-auto/storage/logs/laravel-$(date +%Y-%m-%d).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================================"
echo "[DEPLOY S3 ARTIFACT] Version: $TARGET_VERSION"
echo "Time: $(date)"
echo "========================================================"

# Create a temp directory for extraction
TEMP_DIR="/tmp/deploy-$TARGET_VERSION"
rm -rf $TEMP_DIR && mkdir -p $TEMP_DIR

# 1. DOWNLOAD SOURCE CODE FROM S3
echo "Step 1: Downloading Code from S3..."
if aws s3 cp "$S3_CODE_PATH" "$TEMP_DIR/source.zip"; then
    echo "-> Downloaded source code."
else
    echo "-> ERROR: Cannot find file $S3_CODE_PATH on S3."
    echo "-> Please check if GitHub Actions finished uploading."
    exit 1
fi

# 2. UNZIP
echo "Step 2: Unzipping..."
unzip -q "$TEMP_DIR/source.zip" -d "$TEMP_DIR/code"

# 3. DOWNLOAD .env FROM S3
echo "Step 3: Downloading .env..."
if aws s3 cp "$S3_ENV_PATH" "$TEMP_DIR/code/.env"; then
    echo "-> Downloaded .env configuration."
else
    echo "-> ERROR: Cannot find .env on S3."
    exit 1
fi

# 4. SYNC CODE (RSYNC)
# "Magic" step: only updates changed files, keeps storage intact
echo "Step 4: Syncing to Production..."
if [ ! -d "$PROJECT_DIR" ]; then mkdir -p "$PROJECT_DIR"; fi

# rsync: -a (archive), --delete (remove files not present in source), --exclude (skip storage)
rsync -a --delete --exclude='storage' "$TEMP_DIR/code/" "$PROJECT_DIR/"

# Create storage if missing (first deploy)
mkdir -p "$PROJECT_DIR/storage" "$PROJECT_DIR/bootstrap/cache"

# 5. CÀI ĐẶT & MIGRATE
cd $PROJECT_DIR
# Temporarily take ownership to run Composer
chown -R ec2-user:ec2-user . 

echo "Step 5: Running Composer..."
# Install fresh vendors (S3 artifact contains only clean source)
sudo -u ec2-user /usr/bin/composer install --no-dev --optimize-autoloader --no-interaction

echo "Step 6: Running Artisan..."
sudo -u ec2-user php artisan migrate --force
sudo -u ec2-user php artisan optimize:clear
sudo -u ec2-user php artisan config:cache
sudo -u ec2-user php artisan route:cache
sudo -u ec2-user php artisan view:cache

# 6. FINAL PERMISSIONS (IMPORTANT)
echo "Step 7: Finalizing Permissions..."
# Give Apache ownership of writable directories
chown -R apache:apache storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Give deploy log file ownership back to ec2-user
chown ec2-user:ec2-user "$LOG_FILE"

# Cleanup
rm -rf $TEMP_DIR

# Reload Nginx
systemctl reload nginx

echo "[DEPLOY SUCCESS] Version $TARGET_VERSION is now live!"