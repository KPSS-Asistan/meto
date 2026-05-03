#!/bin/bash

# 1. Install dependencies (Node.js, PM2)
echo "Installing Node.js and PM2..."
sudo apt update
sudo apt install -y curl

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2

# 2. Setup Backend
echo "Starting backend..."
cd ../server
npm install --production
pm2 start server.js --name kpss-backend

# 3. Setup Frontend
echo "Starting frontend..."
cd ../client
npm install --production
# Starts the frontend on port 8001 using the script in package.json
pm2 start npm --name kpss-frontend -- start

# 4. Save PM2 state
echo "Saving PM2 state..."
pm2 save
sudo pm2 startup

echo "All components started!"
pm2 status
