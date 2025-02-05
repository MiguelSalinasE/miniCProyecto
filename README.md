# Compilador mini-C
 Compilador desarrollado para una versión simplificada de C utilizando Flex y Bison.
# Descripción del proyecto
 El sistema está compuesto por un analizador léxico desarrollado con la herramienta Flex y un analizador sintáctico y semántico implementado con Bison. Para más información sobre el diseño e implementación, se puede consultar la memoria del proyecto (fichero MemoriaCompiladores.pdf).
# Manual de Usuario
# Compilación y Ejecución del Proyecto

Se ha creado un archivo `Makefile` para facilitar la compilación de los archivos del proyecto. Para compilar, simplemente ejecuta:

```sh
make
```

## Ejecución de un Fichero

Para ejecutar un fichero, puedes utilizar el siguiente comando:

```sh
make run
```

Si deseas cambiar el fichero que se ejecuta, es necesario modificar el archivo `Makefile` antes de volver a ejecutar el comando.

El resultado de la compilación se almacena en el fichero generado y se muestra por pantalla, con el nombre:

```
codigoEnsamblador.s
```

## Ejecución Directa

También existe la posibilidad de compilar y ejecutar un fichero directamente con el siguiente comando:

```sh
./miniC fichero.mc
```

Si deseas guardar la salida en un archivo específico, puedes redirigir la salida de la siguiente manera:

```sh
./miniC fichero.mc > salidaMIPS.s
```

## Información del Proyecto

Este proyecto ha sido desarrollado para la asignatura **Compiladores** de la **Universidad de Murcia**, durante el periodo de **febrero a mayo de 2022**.

