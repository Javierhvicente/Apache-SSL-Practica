#!/bin/bash
a2ensite nombre.conf

service apache2 reload

apache2ctl -D FOREGROUND