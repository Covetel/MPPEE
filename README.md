MPPEE
=====

Soporte MPPEE


CFengine
=====

Servidor
-----

* Agregar a los repositorios el repo:
```
deb http://cfengine.com/pub/apt wheezy main
```
* Ejecutar:
```
aptitude update
aptitude install cfengine-community
```
* Copiar el contenido del directorio cfengine en el directorio  /var/cfengine/masterfiles del servidor de Politicas.
* Ejecutar:
```
cf-agent --bootstrap [SERVER IP]
```
* Modificar en el archivo serverss\_hostname.txt las variables internal_dns y external_dns por el hostname de la maquina donde se instalará el servidor DNS interno y el DNS externo respectivamente.

Cliente
-----

* Agregar a los repositorios el repo:
```
deb http://cfengine.com/pub/apt wheezy main
```
* Ejecutar:
```
aptitude update
aptitude install cfengine-community
```
* Copiar el contenido del directorio cfengine en el directorio  /var/cfengine/masterfiles del servidor de Politicas.
* Ejecutar:
```
cf-agent --bootstrap [SERVER IP]
```
* En 5 minutos se ejecutará el demonio.
