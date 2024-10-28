#!/bin/bash
a2ensite apellidos.conf

service apache2 reload

apache2ctl -D FOREGROUND