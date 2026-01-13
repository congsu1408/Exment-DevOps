#!/bin/bash

# 1.1.7

# Read environment argument from invocation (e.g., bash deploy.sh test)
ENV_TYPE=$1

echo "Starting Deployment Process..."

# --- DYNAMIC CONFIGURATION BY ENVIRONMENT ---
if [ "$ENV_TYPE" == "prod" ]; then
    PROJECT_DIR="/var/www/deploy-auto"
    BRANCH="main"
    echo "Target Environment: PRODUCTION"
    echo "Directory: $PROJECT_DIR"
    echo "Branch: $BRANCH"

elif [ "$ENV_TYPE" == "test" ]; then
    PROJECT_DIR="/var/www/test/deploy-auto"
    BRANCH="dev"
    echo "Target Environment: TEST"
    echo "Directory: $PROJECT_DIR"
    echo "Branch: $BRANCH"

else
    echo "Error: Invalid environment. Usage: bash deploy.sh [prod|test]"
    exit 1
fi

# 1. Prepare directory ownership as root
# Hand ownership back to ec2-user so Git can operate smoothly
if [ -d "$PROJECT_DIR" ]; then
    chown -R ec2-user:ec2-user $PROJECT_DIR
else
    echo "Directory $PROJECT_DIR does not exist. Please create it manually first."
    exit 1
fi

cd $PROJECT_DIR

# --- 2. RUN CODE COMMANDS (as ec2-user) ---

echo "Pulling Code from branch $BRANCH..."
# Discard local changes and pull the latest code
sudo -u ec2-user git fetch --all
sudo -u ec2-user git reset --hard origin/$BRANCH

echo "Running Composer..."
sudo -u ec2-user /usr/bin/composer install --no-dev --optimize-autoloader --no-interaction

echo "Running Artisan Commands..."
# Note: Artisan will use the .env file in the current directory
sudo -u ec2-user php artisan migrate --force
sudo -u ec2-user php artisan optimize:clear
sudo -u ec2-user php artisan config:cache
sudo -u ec2-user php artisan route:cache
sudo -u ec2-user php artisan view:cache

# --- 3. RUN SYSTEM COMMANDS (as root) ---

echo "Setting Final Permissions (Fix Log/Cache Error)..."
# Set 777 on storage so both Nginx and Artisan can write
chmod -R 777 $PROJECT_DIR/storage
chmod -R 777 $PROJECT_DIR/bootstrap/cache

echo "Reloading Nginx..."
systemctl reload nginx

echo "Deploy Success to $ENV_TYPE!"