#!/bin/bash
# Script de inicio del servicio LDAP

# Variables necesarias para la configuración del servicio LDAP
# $dirConfig = Directorio que contiene los scripts y archivos de configuración del 
#              servicio LDAP

# Variables opcionales para la configuración del servicio LDAP
# $dc1 = Subdominio
# $dc2 = Dominio
# $organization = Organización del dominio
# $initialLDIF - Archivo con una esquema inicial de ou,grupos,usuarios a añadir
# $adminLDAPasswd - Contraseña del usuario administrador del directorio

# Archivos opcionales para la configuración del servicio LDAP
# $initialLDIF = Archivo que contiene entradas ldif para rellenar

set -e

installSLAPD(){
    slapdConfig=$(cat <<EOF
slapd slapd/password1 password $adminLDAPassword
slapd slapd/internal/adminpw password $adminLDAPassword
slapd slapd/internal/generated_adminpw password $adminLDAPassword
slapd slapd/password2 password $adminLDAPassword
slapd slapd/purge_database boolean false
slapd slapd/domain string "$dc1.$dc2"
slapd slapd/invalid_config boolean true
slapd slapd/move_old_database boolean false
slapd shared/organization string $organization
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
slapd slapd/password_mismatch note
EOF
)

    # Se predefinen las configuraciones para la instalación silenciosa del paquete
    echo $slapdConfig | debconf-set-selections

    # Instalación de los paquetes
    apt update && apt-get install slapd ldap-utils -yq \
        # Limpiar caché de apt
        && apt clean -yq
}

configSLAPD(){
  # /etc/ldap/ldap.conf
  # LDAP BASE
  sed -i "s/#BASE	dc=example,dc=com/BASE	dc=${dc1},dc=${dc2}/" /etc/ldap/ldap.conf
  # LDAP URI
  sed -i "s/#URI	ldap:\/\/ldap.example.com ldap:\/\/ldap-provider.example.com:666/URI	ldap:\/\/${HOSTNAME}/" \
  /etc/ldap/ldap.conf

  # Se inicia el servicio slapd
  service slapd start
}

# Función principal
main(){
    # Se comprueba de que se ha definido todas la variables si no se establecen por defecto
    [ -z $dc1 ] && dc1='test' && echo 'Variable $dc1 no especificada, se utiliza el valor por defecto "test"'
    [ -z $dc2 ] && dc2='local' && echo 'Variable $dc2 no especificada, se utiliza el valor por defecto "local"'
    [ -z $organization ] && organization='TEST' && \
    echo 'Variable $organization no especificada, se utiliza el valor por defecto "TEST"'
    [ -z $adminLDAPasswd ] && adminLDAPasswd='admin' && \
    echo 'Variable $adminLDAPasswd no especificada, se utiliza el valor por defecto "admin"'
  
    # ¿Está slapd instalado?
    if [ ! -f /etc/ldap/ldap.conf ]; then
        echo 'slapd no está instalado, se instalará'
        installSLAPD
        echo 'slapd instalado'
    fi

    # ¿Está /etc/ldap/ldap.conf configurado?
    if [ $(grep -c '^#BASE' /etc/ldap/ldap.conf) -eq 1 ]; then
        echo '/etc/ldap/ldap.conf no está configurado, se configurará'
        configSLAPD
        echo 'slapd instalado y configurado con ssl/tls con éxito'
    fi

    # Implementación del archivo con el esquema inicial
    if [ ! -z $initialLDIF ] && [ -f "${dirConfig}/$initialLDIF" ]; then
        ldapadd -x -D "cn=admin,dc=${dc1},dc=${dc2}" -w $adminLDAPasswd \
        -f "${dirConfig}/$initialLDIF"
    fi

    # Mantener contenedor en ejecución
    tail -f /dev/null
}

main
