#!/bin/bash
a2ensite nombre.conf
# Habilita ssl
a2enmod ssl

service apache2 reload

apache2ctl -D FOREGROUND