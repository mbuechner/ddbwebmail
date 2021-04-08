FROM roundcube/roundcubemail:1.4.x-apache
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
RUN echo "LISTEN 8080" > /etc/apache2/ports.conf
RUN { \
		echo "<VirtualHost *:8080>"; \
		echo "  ServerAdmin m.buechner@dnb.de"; \
		echo "  DocumentRoot /var/www/html"; \
		echo "  ErrorLog /dev/stderr"; \
		echo "  CustomLog /dev/stdout combined"; \
		echo "</VirtualHost>"; \
	} > /etc/apache2/sites-enabled/000-default.conf
COPY docker-ddb-entrypoint.sh /
RUN mkdir /usr/src/roundcubemail/images
COPY images/DDBwebmail_Logo.svg /usr/src/roundcubemail/images/DDBwebmail.svg
RUN chmod +x /docker-ddb-entrypoint.sh
RUN { \
	echo "<?php"; \
	echo "   \$config['product_name'] = 'DDBwebmail';"; \
	echo "   \$config['cipher_method'] = 'AES-256-CBC';"; \
        echo "   \$config['date_format'] = 'd.m.Y';"; \
        echo "   \$config['mail_read_time'] = -1;"; \
        echo "   \$config['htmleditor'] = 4;"; \
        echo "   \$config['autoexpand_threads'] = 2;"; \
        echo "   \$config['check_all_folders'] = true;"; \
        echo "   \$config['newmail_notifier_basic'] = true;"; \
        echo "   \$config['newmail_notifier_desktop'] = true;"; \
        echo "   \$config['attachment_reminder'] = true;"; \
        echo "   \$config['reply_mode'] = 1;"; \
        echo "   \$config['show_sig'] = 2;"; \
	echo "   \$config['skin_logo'] = array("; \
	echo "     'elastic:*' => '../../images/DDBwebmail.svg',"; \
	echo "     'elestic:*[small]' => '../../images/DDBwebmail.svg',"; \
        echo "     '[favicon]' => '../../images/DDBwebmail.svg',"; \
	echo "   );"; \
} >> /usr/src/roundcubemail/config/config.inc.php
RUN rm -R /usr/src/roundcubemail/skins/larry /usr/src/roundcubemail/skins/classic
RUN mkdir /usr/src/roundcubemail/plugins/ident_switch
RUN git clone --branch 4.3.5 https://bitbucket.org/BoresExpress/ident_switch.git /usr/src/roundcubemail/plugins/ident_switch
RUN cd /usr/src/roundcubemail/ && composer require roundcube/plugin-installer roundcube/filters:dev-filters-2.2.1
RUN touch /usr/local/etc/php/conf.d/roundcube-override.ini /usr/local/etc/php/conf.d/roundcube-override.ini
RUN chgrp -R 0 /usr/local/etc/php/conf.d/roundcube-override.ini /usr/local/etc/php/conf.d/roundcube-override.ini
RUN chmod -R g=u /usr/local/etc/php/conf.d/roundcube-override.ini /usr/local/etc/php/conf.d/roundcube-override.ini
ENTRYPOINT ["/docker-ddb-entrypoint.sh"]
CMD ["apache2-foreground"]
