#!/bin/bash
# Script de inicio del servicio DNS

# Variables necesarias para la configuración del servicio DNS
# $dirZones = Directorio donde se almacenarán los archivos con los registros de las zonas

set -e

configDNS(){ # Función de configuración del servicio DNS
    # Comprobar de que el directorio de las zonas existe y si no crearlo
    if ! [ -d $dirZones ]; then
        mkdir $dirZones
    fi # ! [ -d $dirZones ]

    # Permisos
    chown bind:bind /var/cache/bind -R
    chgrp bind /etc/bind -R
    
    named-checkconf -z # Comprobar la configuración de todas las zonas
    resultadoNamed=$?

    if [ $resultadoNamed != 0 ] # Control de errores
    then
        return 1
    else 
        return 0
    fi
}

main(){ # Función principal de configuración del servicio DNS
    configDNS
    resultadoConfigDNS=$?
    if [ $resultadoConfigDNS -eq 0 ]
    then 
        /usr/sbin/named -f -c /etc/bind/named.conf -u bind # Ejecución del servicio
    fi
}

main