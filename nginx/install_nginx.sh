#!/bin/bash

# Variables
NGINX_VERSION="1.27.2"
DIR="$HOME/nginx-$NGINX_VERSION"
SYS_D="/lib/systemd/system/nginx.service"
NGINX_URL="http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"
DOWNLOAD_DIR="$HOME/Downloads"

# Banner
echo "============================"
echo "🌟 Mage Install: NGINX   🌟"
echo "============================"

# Functions
install_dependencies() {
    echo "Installing dependencies..."
    if sudo apt update && sudo apt install -y \
        libpcre3 \
        libpcre3-dev \
        zlib1g \
        zlib1g-dev \
        libssl-dev \
        wget; then
        echo "✅ Dependencies installed successfully."
    else
        echo "❌ Failed to install dependencies."
        exit 1
    fi
}

download_nginx() {
    if [ ! -d "$DOWNLOAD_DIR" ]; then
        mkdir -p "$DOWNLOAD_DIR"
    fi

    if [ ! -f "$DOWNLOAD_DIR/nginx-$NGINX_VERSION.tar.gz" ]; then
        echo "Downloading NGINX..."
        if wget -P "$DOWNLOAD_DIR" "$NGINX_URL"; then
            echo "✅ NGINX downloaded successfully."
        else
            echo "❌ Failed to download NGINX."
            exit 1
        fi
    else
        echo "✅ NGINX file already exists in $DOWNLOAD_DIR."
    fi
}

remove_existing_dir() {
    if [ -d "$DIR" ]; then
        read -p "The directory $DIR already exists. Do you want to delete it? (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            echo "Deleting existing directory..."
            rm -rf "$DIR" && echo "✅ Directory deleted." || echo "❌ Failed to delete directory."
        else
            echo "❌ Operation canceled."
            exit 1
        fi
    fi
}

setup_nginx() {
    echo "Unpacking NGINX..."
    if tar -zxvf "$DOWNLOAD_DIR/nginx-$NGINX_VERSION.tar.gz" -C "$HOME"; then
        echo "✅ NGINX unpacked successfully."
    else
        echo "❌ Failed to unpack NGINX."
        exit 1
    fi
    
    cd "$DIR" || exit

    echo "Configuring NGINX..."
    if ./configure \
        --sbin-path=/usr/bin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --with-pcre \
        --pid-path=/var/run/nginx.pid \
        --with-http_ssl_module; then
        echo "✅ NGINX configured successfully."
    else
        echo "❌ Failed to configure NGINX."
        exit 1
    fi

    echo "Compiling and installing NGINX..."
    if make && sudo make install; then
        echo "✅ NGINX installed successfully."
    else
        echo "❌ Failed to compile or install NGINX."
        exit 1
    fi
}

create_system_service() {
    echo "Setting up system service for NGINX..."
    if sudo bash -c "cat > $SYS_D" <<EOL
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/bin/nginx -t
ExecStart=/usr/bin/nginx
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOL
    then
        echo "✅ System service configured successfully."
    else
        echo "❌ Failed to configure system service."
        exit 1
    fi

    echo "Reloading daemons and enabling service..."
    if sudo systemctl daemon-reload && sudo systemctl enable nginx && sudo systemctl start nginx; then
        echo "✅ NGINX started and enabled successfully."
    else
        echo "❌ Failed to start or enable NGINX."
        exit 1
    fi
}

# Script execution
install_dependencies
download_nginx
remove_existing_dir
setup_nginx
create_system_service

echo "✨ NGINX installation and configuration completed successfully. ✨"
