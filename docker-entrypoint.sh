#!/bin/bash

# Cambia los permisos y el propietario del archivo de registro
chmod 775 -R /var/www/html/
chown www-data:www-data -R /var/www/html/

chmod 775 -R /etc/glpi/
chmod 775 -R /var/log/glpi/
chmod 775 -R /var/lib/glpi/
chmod 775 -R /var/lib/glpi/_cache
chmod 775 -R /var/lib/glpi/_cache/templates

chown -R www-data:www-data /var/log/glpi/
chown -R www-data:www-data /etc/glpi/
#chmod 644 /var/log/glpi/php-errors.log
chown www-data:www-data -R /var/lib/glpi/

# Ejecuta el comando Symfony/GLPI después de que el contenedor se inicie
php bin/console locales:compile

TZ=${TZ:-America/Bogota}
APACHE_RUN_USER=${APACHE_RUN_USER:-'www-data'}

echo --------------------------------------------------
echo "Setting up Timezone: \"${TZ}\""
echo --------------------------------------------------
echo $TZ | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

set -ex
# echo "* * * * * php /var/www/html/glpi/front/cron.php &>/dev/null" > /etc/cron.d/crontab
# Inicia el servicio cron
service cron start

#php-fpm

# Ejecuta el script de supervisord para gestionar cron
#supervisord -c /etc/supervisor/conf.d/supervisord.conf

# Inicia el servidor web Apache
#apache2-foreground

exec "$@"

