#!/bin/bash

# Habilitar los sitios si no existen los enlaces simbólicos
if [ ! -L /etc/nginx/sites-enabled/nombre.com.conf ]; then
  ln -s /etc/nginx/sites-available/nombre.com.conf /etc/nginx/sites-enabled/
fi

if [ ! -L /etc/nginx/sites-enabled/www.apellidos.com.conf ]; then
  ln -s /etc/nginx/sites-available/www.apellidos.com.conf /etc/nginx/sites-enabled/
fi

# Recargar la configuración de Nginx
nginx -s reload

# Iniciar Nginx en primer plano
nginx -g 'daemon off;'