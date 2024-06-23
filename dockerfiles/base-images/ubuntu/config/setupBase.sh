#!/bin/bash
# Script de inicio de la imagen base ubuntu

set -e

configAdminUser(){ # Función que crea el usuario administrador del sistema base
    # Comprobar de que el usuario no exista mirando en el registro de usuarios
    if [ $(grep -c ${adminUser} /etc/passwd) -eq 1 ]
    then
        echo "El usuario ${adminUser} existe"
        return 1 # Error inesperado
    else
        echo "Usuario ${adminUser} creado con éxito"
        # Crear el usuario administrador
        useradd -m -s /bin/bash -g sudo ${adminUser}
         # Establecer la contraseña para el usuario administrador
        echo "${adminUser}:${adminPassword}" | chpasswd
        echo "Contraseña de ${adminUser} establecida con éxito"
        passwd -l root # Bloquear la cuenta root 
        echo "Usuario root bloqueado con éxito"
        return 0 # Usuario administrador creado con éxito
    fi
}

configSSH(){ # Función de configuración del servicio SSH
    # Comprobar si existe el archivo de confguración del servicio SSH
    if [ ! -f /etc/ssh/sshd_config ]
    then
        echo 'El archivo /etc/ssh/sshd_config no existe'
        return 1 # Error inesperado
    else 
        # Denegar la conexión de ssh a root
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
        # En caso de bloqueo, un tiempo de espera de 15m para volver
        sed -i 's/#LoginGraceTime 2m/LoginGraceTime 15m/g' /etc/ssh/sshd_config
        # Un máximo de 5 conexiones activas ssh
        sed -i 's/#MaxSessions 10/MaxSessions 5/g' /etc/ssh/sshd_config
        # Un máximo de 3 intentos fallidos de autenticación
        sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/g' /etc/ssh/sshd_config
        
        if [ ! -d /var/run/sshd ] # Comprobar si existe el directorio /var/run/sshd
        then
            # Creamos el directorio para le demonio en ejecución del servicio SSH
            mkdir -v /var/run/sshd
        fi

        # Comprobar si existe el directorio .ssh en el home del usuario administrador
        if [ ! -d "/home/${adminUser}/.ssh" ]
        then
            if [ ! -d "/home/${adminUser}" ]
            then
                # Crear el directorio .ssh en el usuario administrador
                echo "No existe el home del usuario ${adminUser}"
                return 1
            fi 
            # Crear el directorio .ssh en el usuario administrador
            mkdir -v /home/${adminUser}/.ssh
        fi

        return 0 # Servicio SSH configurado con éxito
    fi
}

main(){ # Función principal
    [ -z $adminUser ] && adminUser='adminsrv' && \
    echo 'Variable $adminUser no especificada, se utiliza el valor por defecto "adminsrv"'
    [ -z $adminPassword ] && adminPassword='adminsrv' && \
    echo 'Variable $adminPassword no especificada, se utiliza el valor por defecto "adminsrv"'
    
    configAdminUser # Función creación de usuario administrador
    resultadoConfigAdminUser=$? # Resultado de la función anterior
    if [ $resultadoConfigAdminUser -eq 0 ] 
    then
        # Éxito
        configSSH # Función de configuración del servicio SSH
        resultadoConfigSSH=$? # Resultado de la función anterior
        if [ $resultadoConfigSSH -eq 0 ]
        then
            # Éxito
            service ssh start
        fi
    fi
}

main