FROM roundcube/roundcubemail:latest
MAINTAINER Michael Büchner <m.buechner@dnb.de>

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        git unzip \
    ; \
    \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer; \
    mv /usr/src/roundcubemail/composer.json-dist /usr/src/roundcubemail/composer.json; \
    \
    composer \
        --working-dir=/usr/src/roundcubemail/ \
        --prefer-dist --prefer-stable \
        --no-update --no-interaction \
        --optimize-autoloader --apcu-autoloader \
        require \
            johndoh/contextmenu \
    ; \
    composer \
        --working-dir=/usr/src/roundcubemail/ \
        --prefer-dist --no-dev \
        --no-interaction \
        --optimize-autoloader --apcu-autoloader \
        update;
COPY docker-ddb-entrypoint.sh /
RUN chmod +x /docker-ddb-entrypoint.sh
ENTRYPOINT ["/docker-ddb-entrypoint.sh"]
CMD ["apache2-foreground"]
