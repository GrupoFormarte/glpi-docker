FROM php:7.4-apache

# Environments
ENV TZ=America/Bogota
ENV WORKDIR=/var/www/html/
ENV DisplayErrors=Off

# Install php dependencies
RUN docker-php-ext-install pdo pdo_mysql mysqli

# Enable the OPcache extension
RUN docker-php-ext-enable opcache

# Instala software necesario
RUN apt-get update && apt-get install -y gettext cron git

# Instala el paquete Supervisor
RUN apt-get update && apt-get install -y supervisor

# Instala la extensión intl
# Instala las bibliotecas ICU y otras dependencias
RUN set -ex \
    && apt-get update && apt-get install -y libicu-dev libzip-dev \
    && docker-php-ext-install intl zip
RUN apt-get update && apt-get install -y libldap2-dev
RUN docker-php-ext-install ldap
# Install and enable the exif extension
RUN docker-php-ext-install exif

# Instala la extensión GD y otras dependencias
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Install and enable the bz2 extension
RUN apt-get update && apt-get install -y libbz2-dev \
    && docker-php-ext-install bz2

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Iniciar el servicio de Cron
#RUN service cron start
#RUN service cron enable

# Copia los archivos de configuración
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY crontab /etc/cron.d/crontab
# Agrega la tarea cron al final del Dockerfile
RUN echo '* * * * * /usr/local/bin/php /var/www/html/front/cron.php &>/dev/null' > /etc/cron.d/crontab
CMD cron -f & /usr/local/bin/php /var/www/html/front/cron.php & tail -f /dev/null
# Dale permisos adecuados al archivo
RUN chmod 0644 /etc/cron.d/crontab

# Copia el script de entrada del contenedor
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Habilita la visualización de errores de PHP en el entorno de desarrollo (opcional)
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" && \
    sed -i 's/display_errors = Off/display_errors = ${DisplayErrors}/' "$PHP_INI_DIR/php.ini"

# Aumenta la asignación de memoria a 256 MB
RUN echo "memory_limit = 256M" >> "$PHP_INI_DIR/php.ini"

# Write permissions on "files" directory
RUN mkdir -p /var/log/glpi
RUN mkdir -p /var/lib/glpi
RUN mkdir -p /etc/glpi

#COPY logs/ /var/log/glpi/
RUN  chmod -R 775 /var/log/glpi/ && \
	 chown www-data:www-data /var/log/glpi/

RUN  chmod -R 775 /var/lib/glpi/ && \
         chown www-data:www-data /var/lib/glpi/

RUN  chmod -R 775 /etc/glpi/ && \
         chown www-data:www-data /etc/glpi/

# Cambia el propietario de la carpeta /var/www/html para el usuario www-data
RUN chown -R www-data:www-data /var/www/html/

# Define el directorio de trabajo
WORKDIR ${WORKDIR}

EXPOSE 80
#EXPOSE 587
EXPOSE 389
EXPOSE 636

# Apache Configuration
RUN a2enmod rewrite
RUN a2enmod headers

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
#RUN docker-php-ext-install opcache && \
#    { \
#        echo 'opcache.memory_consumption=128'; \
#        echo 'opcache.interned_strings_buffer=8'; \
#        echo 'opcache.max_accelerated_files=4000'; \
#        echo 'opcache.revalidate_freq=2'; \
#        echo 'opcache.fast_shutdown=1'; \
#        echo 'opcache.enable_cli=1'; \
#    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Ejecuta el script de entrada
ENTRYPOINT ["/docker-entrypoint.sh"]

# CMD por defecto para el contenedor (puede variar según tus necesidades)
CMD ["apache2-foreground"]
