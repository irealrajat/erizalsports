# WooCommerce VPS

Docker-based WooCommerce/WordPress deployment designed for a VPS with an existing host-level Caddy installation.

## Architecture

Internet
    |
    v
Caddy :80/:443
    |
    v
127.0.0.1:8080
    |
    v
WordPress / WooCommerce
    |
    v
MySQL

Caddy remains installed directly on the VPS.

Docker does NOT use ports 80 or 443.

MySQL is not exposed publicly.


## Requirements

- Linux VPS
- Docker
- Docker Compose
- Caddy
- Domain name
- DNS A record pointing to VPS
- Ports 80 and 443 accessible to Caddy


## Installation

Clone the repository:

    git clone YOUR_REPOSITORY_URL

Enter the directory:

    cd woocommerce-vps

Create environment file:

    cp .env.example .env

Edit it:

    nano .env

Set:

    DOMAIN=shop.example.com

    WORDPRESS_PORT=8080

    MYSQL_DATABASE=wordpress
    MYSQL_USER=wordpress
    MYSQL_PASSWORD=YOUR_PASSWORD
    MYSQL_ROOT_PASSWORD=YOUR_ROOT_PASSWORD

Run:

    sudo ./scripts/install.sh


## DNS

Create an A record:

    shop.example.com -> YOUR_VPS_IP

Wait for DNS propagation.

Then open:

    https://shop.example.com


## Useful Commands

Check containers:

    docker compose ps

View WordPress logs:

    sudo ./scripts/logs.sh wordpress

View MySQL logs:

    sudo ./scripts/logs.sh db

Restart:

    docker compose restart

Stop:

    docker compose stop

Start:

    docker compose start

Update:

    sudo ./scripts/update.sh

Backup:

    sudo ./scripts/backup.sh


## Data

WordPress files are stored in:

    woocommerce_wordpress_data

MySQL data is stored in:

    woocommerce_mysql_data

These are Docker named volumes and survive container recreation.


## Backups

Backups contain:

    database.sql.gz
    wordpress.tar.gz
    backup-info.txt

Backups are stored according to:

    BACKUP_DIR

in .env.


## Security

Never commit .env.

The repository only contains .env.example.

The following are intentionally NOT exposed:

    MySQL 3306
    WordPress 8080

WordPress is bound to:

    127.0.0.1

Caddy is the public entry point.


## Caddy

The installer creates:

    /etc/caddy/sites-enabled/shop.example.com.caddy

Example:

    shop.example.com {
        reverse_proxy 127.0.0.1:8080
    }

The main Caddyfile imports:

    /etc/caddy/sites-enabled/*


## Updating

Run:

    sudo ./scripts/update.sh

A backup is created before the Docker update.


## Restore

Find the backup directory:

    ls /opt/woocommerce-backups

Restore:

    sudo ./scripts/restore.sh /opt/woocommerce-backups/YYYY-MM-DD_HH-MM-SS


## Important

Do not delete Docker volumes unless you have a verified backup.

Deleting the MySQL volume permanently deletes the database.