# Práctica despliegue Apache con SSL
## Introducción
Para esta práctica queremos crear un servidor web de nignx alojado en un contenedor de docker el cual trabaje con tres dominos. Cada dominio hará referencia a un localHost. Tendremos uno para nuestro nombre, otro para nuestro apellido y finalmente uno que sea seguro y trabaje con https y tenga una sección privada que trabaje con usuario y contraseña.

## Creación del primer dominio
Para desplegar los diferentes servidores haremos uso de un archivo docker-compose el cual nos ayudará ha realizar la configuración del servidor.
![imagen primer fragmento docker-compose](images/composepng.png)
Está sería la configuración del primer fragmento del docker-compose.
### web
Debajo de services tenemos el nombre del servicio que es web.
### Image and Container_name
La imagen de nginx que usaremos (ubuntu/nginx) y nginx_server el nombre del contenedor.
### Ports
 los puertos que estamos mapeando, en este caso el 80 de nuestra máquina al puerto 80 que es el de nginx.
### Volumes
 * **./hernandez_website/website:/var/www/html:** El contenido de la carpeta local hernandez_website/website en el host se montará en **/var/www/html** dentro del contenedor, que es la ubicación predeterminada donde nginx sirve los archivos HTML.
* **./hernandez_website/sites-available:/etc/nginx/sites-available:** La carpeta sites-available local se montará en el directorio donde nginx almacena las configuraciones de sitios disponibles en el contenedor.

* **./hernandez_website/scripts:/docker-entrypoint.d/** Los scripts locales en hernandez_website/scripts estarán disponibles dentro del contenedor en el directorio **/scripts**.

### Sites-available
En mi directorio sites-available tengo un fichero de configuración que crea un VirtualHost.

![archivo conf](images/apellidos.com.png)
Primero le indico que puede ser cualquier puerto pero que lo redireccione al 80 ya que es el de nginx. A continuación le indico la ruta donde va a estar el html que he mapeado anteriormente (/var/www/html). Luego le indico el nombre del dominio que es **www.apellidos.com**. Por último le indico la ruta del html del error 404 en caso de que no se encuentre la web.
### Restart
Indica que Docker siempre intentará reiniciar el contenedor si se detiene por cualquier motivo, lo que asegura que el servicio esté siempre en ejecución.

### EntryPoint
Define el script que se ejecutará como el comando principal cuando el contenedor se inicie. En este caso, el script **entrypoint.sh** ubicado en **/scripts** se ejecutará cuando se inicie el contenedor. El uso de entrypoint es para que el contenedor realice tareas adicionales (como configuraciones específicas) al iniciar, antes de ejecutar nginx.

![scriptApellido](images/entrypoint.png)

Este es el script que quiero que se ejecute. Lo primero que hace es habilitar el archivo de configuración que hemos creado para que sea utilizado por nginx. 

A continuación ejecuta el comando **nginx -s reload**, el cual recarga la configuración del servidor nginx sin detener el servicio. 

Por último,
El comando **nginx -g 'daemon off;'** se utiliza para iniciar nginx en primer plano (foreground) en lugar de hacerlo como un servicio en segundo plano (background). Esto significa que el proceso de nginx ocupará la consola en la que fue iniciado y no se "desvinculará" del terminal como lo haría normalmente.

### Habilitar nombre de domino en el archivo hosts
Para habilitar el nombre de dominio de nuestro archivo conf necesitamos añadirlo al archvio de windows hots. Para ello necesitamos ir al directorio **C:\Windows\System32\drivers\etc\** y abrir el archivo hots como administrador. Antes de nada se recomienda hacer una copia de seguridad del archivo. Una vez abierto el archivo deberemos dirigirnos a la parte inferior del archivo y escribir **IP nombre.dominio.com**. La ip será la ip de nuestro sistema y el nombre de dominio sera el de nuestro archivo conf, en mi caso **www.apellidos.com**

## Segundo dominio 
Este segundo dominio funciona de la misma manera, lo único que cambia es que en vez de ser mis apellidos será mi nombre.
En este caso el dominio es **nombre.com**.

## Dominio con ssl
Como en los anteriores dominios empezaremos explicando el docker-compose. 

### Puertos
En este caso deberemos mapear el pueto 443 de ssl para poder crear la conexión https.

![ssl](images/composepng.png)

### Volumes
* **./javiHernandez_website/htpasswd/.htpasswd:/etc/nginx/.htpasswd**  El archivo .htpasswd contiene las credenciales de usuarios para la autenticación HTTP básica en Apache. Esto permite proteger directorios con usuario y contraseña.

* **./javiHernandez_website/certs:/etc/nginx/certs** Los certificados SSL locales se compartirán con Apache dentro del contenedor, de manera que se puedan usar para habilitar conexiones seguras SSL/TLS.


### htpasswd
Para crear un usuario y contraseña con el que poder acceder a nuestro dominio de una forma segura, deberemos de crear un directorio **htpasswd** que contenga un archivo **.htpasswd**. Dentro de este archivo deberemos escribir el nombre de usuario : y la contraseña cifrada. En este caso el usuario es **javier:Hernandez**. Para el cifrado de contraseña he usado [Bcrypt](https://bcrypt-generator.com).

### Sites-available
En este caso hemos creado un archivo de configuración el cual tiene dos virtual host, uno para el dominio y otro que lo redirecciona con SSL.

![confSSL](images/nombreSSL.png)
El primer virtual host crea el nombre de dominio el cual es **nombre.com** el cual se encuentra en el puerto **80** y lo redirecciona al virtualHost con SSL.

Siguiendo con la configuración del SSL, empezamos activando el puerto 443 de SSL. 
* **SSLCertificateFile /etc/apache2/certs/nombre.com.crt** indica la ruta donde se va a guardar el archivo del certificado SSL que crearemos a continuación.
* **SSLCertificateKeyFile /etc/apache2/certs/nombre.com.key** indica la ruta donde se guardará la key que generaremos a continuación con el certificado.
* **ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
    ssl_prefer_server_ciphers on;**
    Habilita los protocolos seguros de SSL.

Luego seguiremos con la configuración de la protección del directorio. En este caso queremos proteger el directorio privado por eso le indicamos la ruta **location /privado**
* **aut_basic** establece una autenticación básica. Esto significa que el servidor solicitará al usuario un nombre de usuario y una contraseña que se enviarán en texto base64 (no cifrado). Para asegurar que esta autenticación sea segura, debe estar acompañada de SSL/TLS (HTTPS), que cifra la transmisión.

* **auth_basic "Acceso Restringido"** este es el mensaje que aparecerá en el cuadro para introducir las credenciales.
* **auth_basic_user_file /etc/nginx/.htpasswd** especifíca la ubicación del archivo **.htpasswd**.

### Creación de certificado y key
Para crear un certificado SSL y la key que indicamos en el archivo de configuración, hemos usado [OpenSSL](https://slproweb.com/products/Win32OpenSSL.html). Usando su terminal una vez nos colocamos en la ruta donde van a ir los certificados ejecutamos el siguiente comando.

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nombre.key -out nombre.com.crt
Una vez ejecutado el domino nos hará documentar el Pais, cuidad, nombre de la empresa, correo...
Una vez creado el certificado y la key estaría todo listo.

![consolaSSL](images/ConsolaSSL.png)


## Ejecución
Para levantar los contenedores y Apache pueda trabajar deberemos usar el comando **docker-compose up -d**.

Para entrar a la web de mis apellidos debremos buscar por **www.apellidos.com**. 

![apellidos](images/apellidos.com.Web.png)

Para entrar a la web de mi nombre deberemos de buscar por **nombre.com**.

![nombre](images/nombreWeb.png)

Para entrar a la web protegida con usuario y contraseña deberemos buscar por **nombre.com/privado**.

![alerta](images/alerta.png)

Al buscar esta web nos saldrá un aviso de que no es un sitio seguro, esto es debido a que el certificado es uno no oficial y no esta verificado por una entidad de certificados oficiales. Por lo que deberemos clickar en configuración avanzada y entrar al sitio web.

![registro](images/registro.png)

A continuación metemos los credenciales válidos del archivo **.htpasswd** en este caso **javier:Hernandez**.

![sitioPrivado](images/seguro.png)

