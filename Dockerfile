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
RUN mkdir /usr/src/roundcubemail/images
COPY images/DDBwebmail_Logo.svg /usr/src/roundcubemail/images/DDBwebmail.svg
RUN chmod +x /docker-ddb-entrypoint.sh
RUN { \
	echo "<?php"; \
	echo "    \$config['product_name'] = 'DDBwebmail';"; \
	echo "    \$config['skin_logo'] = array("; \
	echo "     'login[small]' => '../../images/DDBwebmail.svg',"; \
	echo "     'login' => '../../images/DDBwebmail.svg',"; \
	echo "     '*[small]' => '../../images/DDBwebmail.svg',"; \
	echo "   );"; \
} >> /usr/src/roundcubemail/config/config.inc.php
RUN rm -R /usr/src/roundcubemail/skins/larry /usr/src/roundcubemail/skins/classic
RUN mkdir /usr/src/roundcubemail/plugins/ident_switch
RUN git clone --branch 4.2 https://bitbucket.org/BoresExpress/ident_switch.git /usr/src/roundcubemail/plugins/ident_switch
RUN cd /usr/src/roundcubemail/ && composer require roundcube/plugin-installer
ENTRYPOINT ["/docker-ddb-entrypoint.sh"]
CMD ["apache2-foreground"]
