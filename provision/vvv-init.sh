#!/usr/bin/env bash
# Provision WooCommerce Development

echo "\nSetting Up WooCommerce Development Environment\n"

# **
# Database
# **

# Create the database over again.
echo -e "\nCreating database 'woocommerce_development' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS woocommerce_development"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON woocommerce_development.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

# Nginx Logs
mkdir -p ${VVV_PATH_TO_SITE}/log
touch ${VVV_PATH_TO_SITE}/log/error.log
touch ${VVV_PATH_TO_SITE}/log/access.log

# If we delete public_html, let's just start over.
if [[ ! -d "${VVV_PATH_TO_SITE}/public_html" ]]; then

  echo "Creating directory public_html for WooCommerce Development...\n"
  mkdir -p ${VVV_PATH_TO_SITE}/public_html
  cd ${VVV_PATH_TO_SITE}/public_html

  # **
  # WordPress
  # **

  # Download WordPress
  echo "Downloading the latest version of WordPress into the public_html folder...\n"
  wp core download --locale=en_US --allow-root

  # Install WordPress.
  echo "Creating wp-config in public_html...\n"
  wp core config --dbname='woocommerce_development' --dbuser=wp --dbpass=wp --dbhost='localhost' --dbprefix=wp_ --locale=en_US --allow-root --extra-php <<PHP
// Match any requests made via xip.io.
if ( isset( \$_SERVER['HTTP_HOST'] ) && preg_match('/^(local.woocommerce.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(.xip.io)\z/', \$_SERVER['HTTP_HOST'] ) ) {
    define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
    define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );
}

define( 'WP_DEBUG', true );
define( 'WP_DEBUG_DISPLAY', false );
define( 'WP_DEBUG_LOG', true );
define( 'SCRIPT_DEBUG', true );
define( 'JETPACK_DEV_DEBUG', true );
PHP

  # Install into DB
  echo 'Installing WordPress...\n'
  wp core install --url=local.woocommerce.dev --title='WooCommerce' --admin_user=admin --admin_password=password --admin_email=changme@changeme.com --allow-root

  # Update Blog Description option
  echo 'Updating tagline...\n'
  wp option update blogdescription 'WooCommerce Development VVV' --allow-root

  # **
  # Your themes
  # **
  echo 'Installing themes...\n'
  wp theme install storefront --activate --allow-root

  # Delete unrequired themes
  echo "Deleting unrequired default themes..."
  wp theme delete twentyfifteen  --allow-root

  # **
  # # Create pages
  # **
  echo "Creating pages for the Storefront theme..."
  wp post create --post_type=page --post_title='Homepage' --post_status=publish --post_author=1 --allow-root
  wp post create --post_type=page --post_title='Blog' --post_status=publish --post_author=1 --allow-root

  # **
  # # Set homepage template for the storefront theme to the page post meta
  # **
  echo "Setting Storefront homepage template meta..."
  wp post meta set 3 _wp_page_template template-homepage.php --allow-root

  # **
  # # Enable a page to display as the frontpage of the site.
  # # Set the homepage as the frontpage of the site.
  # # Set the Blog page as the posts page for the site.
  # **
  echo "Setting Storefront pages as the WordPress Frontpage and Posts Page..."
  wp option update show_on_front page --allow-root
  wp option update page_on_front 3 --allow-root
  wp option update page_for_posts 4 --allow-root

  # **
  # # Create Menus
  # **
  echo "Create Custom WordPress Primary Menu..."
  wp menu create 'Primary Menu' --allow-root

  echo "Assign primary menu to the storefront themes primary location..."
  wp menu location assign primary-menu primary --allow-root

  echo "Adding basic menu items to the Primary Menu..."
  wp menu item add-custom primary-menu Home http://local.woocommerce.dev/ --allow-root
  wp menu item add-post primary-menu 4 --title='Blog' --allow-root

  # **
  # # Plugins
  # **

  echo 'Installing plugins...\n'
  wp plugin install wordpress-importer --activate --allow-root
  wp plugin install user-switching --activate --allow-root
  wp plugin install wp-mail-logging --allow-root
  wp plugin install wp-crontrol --activate --allow-root
  wp plugin install query-monitor --allow-root

  # Delete unrequired default plugins
  echo "Deleting unrequired default plugins..."
  wp plugin delete hello   --allow-root
  wp plugin delete akismet --allow-root


  git clone --recursive https://github.com/woocommerce/woocommerce.git    wp-content/plugins/woocommerce

  # **
  # Unit Data
  # **

  # Update the sites permalink structure
  echo 'Update permalink structure...\n'
  wp option update permalink_structure '/%postname%/' --allow-root
  wp rewrite flush --allow-root

  echo 'Finished Setting Up WooCommerce Development Environment, Enjoy!'

  cd ..

else

  cd ${VVV_PATH_TO_SITE}/public_html

  # Updates
  if $(wp core is-installed --allow-root); then

    # Update WordPress.
    echo "Updating WordPress for WooCommerce Development VVV...\n"
    wp core update --allow-root
    wp core update-db --allow-root

    # Update Plugins
    echo "Updating plugins for WooCommerce Development VVV...\n"
    wp plugin update --all --allow-root

    # **
    # Your themes
    # **
    echo "Updating themes for WooCommerce Development VVV...\n"
    wp theme update --all --allow-root

  fi

  cd ..

fi
