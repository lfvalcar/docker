#!/bin/bash
# Script de inicio del servicio DHCP

# Variables necesarias para la configuración del servicio DHCP
# $IFACE = Interfaz que usará el serivicio para escuchar las peticiones 

set -e

# Función de configuración del servicio DHCP
configDHCP(){
    if [ ! -f /etc/default/isc-dhcp-server ]
    then
        return 1 # Error inesperado
    else
        # Definir las interfaces que participan el servicio DHCP
        sed -i "s/INTERFACESv4=""/INTERFACESv4="$IFACE"/g" /etc/default/isc-dhcp-server
    fi

    if [ $(grep -c dhcpd /etc/passwd) -eq 1 ]
    then
        return 1 # Error inesperado
    else
        useradd -r -s /usr/sbin/nologin -d /var/run dhcpd # Crear usuario dhcpd
    fi

    # Comprobar que existen los archivos de las concesiones
    if [ ! -f /var/lib/dhcp/dhcpd.leases ]
    then
        # Crear los archivos de las concesiones
        touch /var/lib/dhcp/dhcpd.leases
        touch /var/lib/dhcp/dhcpd.leases~
    else
        # Otorgar la propiedad de los archivos al usuario dhcpd
        chown dhcpd:dhcpd /var/lib/dhcp -R
        return 0
    fi
}

main(){ # Función principal de configuración del servicio DNS
    configDHCP
    resultadoConfigDHCP=$?
    if [ $resultadoConfigDHCP -eq 0 ]
    then
        # Ejecución del servicio
        /usr/sbin/dhcpd -f --no-pid -cf /etc/dhcp/dhcpd.conf \
        -lf /var/lib/dhcp/dhcpd.leases -user dhcpd -group dhcpd $IFACE
    fi
}

main