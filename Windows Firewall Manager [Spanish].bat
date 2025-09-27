@echo off
setlocal EnableDelayedExpansion

REM Variables globales para mantener la direccion actual
set "DIRECCION=IN"
set "DIRECCION_LOWER=in"

REM Verificar si se ejecuta como administrador
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Para Ejecutar este archivo se requiere permisos de administrador.
    echo.
    echo Para ejecutar como administrador:
    echo     ^|
    echo     ^|- Clic derecho en el archivo .bat
    echo     ^|- Seleccionar "Ejecutar como administrador"
    echo     ^|
    echo     ^|- O ejecutar CMD o Terminal como administrador primero
    echo.
    pause
    exit /b 1
)

:seleccionar_direccion_inicial
cls
echo.
echo                                         ADMINISTRADOR DE WINDOWS FIREWALL
echo                                     ----------------------------------------
echo.
echo ==========================================
echo        SELECCION DE DIRECCION INICIAL
echo ==========================================
echo.
echo [1] - Reglas de ENTRADA (IN)
echo [2] - Reglas de SALIDA (OUT)
echo.
set /p "eleccion_dir=Seleccione la direccion inicial [1-2]: "

if "!eleccion_dir!"=="1" (
    set "DIRECCION=IN"
    set "DIRECCION_LOWER=in"
    goto menu_principal
) else if "!eleccion_dir!"=="2" (
    set "DIRECCION=OUT"
    set "DIRECCION_LOWER=out"
    goto menu_principal
) else (
    echo.
    echo [ERROR] Opcion invalida. Solo puede ingresar 1 o 2.
    echo.
    pause
    goto seleccionar_direccion_inicial
)

:menu_principal
cls
echo.
echo                                         ADMINISTRADOR DE WINDOWS FIREWALL
echo                                     ----------------------------------------
echo.
echo ==========================================
echo             MENU PRINCIPAL
echo ==========================================
echo.
echo Direccion actual: !DIRECCION!
echo.
echo      ---- GESTION DE IPs ----
echo [1] - Bloquear IP
echo [2] - Desbloquear IP
echo [3] - Ver IPs bloqueadas
echo.
echo      ---- GESTION DE PUERTOS ----
echo [4] - Bloquear / Cerrar / Denegar Puerto
echo [5] - Desbloquear / Abrir / Permitir Puerto
echo [6] - Ver Puertos bloqueados
echo.
echo      ---- GESTION ADOBE ----
echo [7] - Bloquear Aplicaciones Adobe
echo [8] - Desbloquear Aplicaciones Adobe
echo.
echo      ---- CONFIGURACION ----
echo [9] - Cambiar direccion ^(reglas IN/OUT^)
echo [10] - Salir
echo.
set /p "opcion_menu=Ingrese su opcion [1-10]: "

if "!opcion_menu!"=="1" goto bloquear_ip
if "!opcion_menu!"=="2" goto desbloquear_ip
if "!opcion_menu!"=="3" goto ver_ips_bloqueadas
if "!opcion_menu!"=="4" goto bloquear_puerto
if "!opcion_menu!"=="5" goto desbloquear_puerto
if "!opcion_menu!"=="6" goto ver_puertos_bloqueados
if "!opcion_menu!"=="7" goto bloquear_adobe
if "!opcion_menu!"=="8" goto desbloquear_adobe
if "!opcion_menu!"=="9" goto cambiar_direccion
if "!opcion_menu!"=="10" exit

echo.
echo [ERROR] Opcion invalida. Solo puede ingresar valores del 1 al 10.
echo.
pause
goto menu_principal

:cambiar_direccion
cls
echo ==========================================================================
echo                    CAMBIAR DIRECCION DE REGLAS
echo ==========================================================================
echo.
echo Direccion actual: !DIRECCION!
echo.
echo [1] - Cambiar a reglas de ENTRADA (IN)
echo [2] - Cambiar a reglas de SALIDA (OUT)
echo [3] - Volver al menu principal
echo.
set /p "nueva_dir=Seleccione nueva direccion [1-3]: "

if "!nueva_dir!"=="1" (
    if "!DIRECCION!"=="IN" (
        echo.
        echo [INFO] Ya se encuentra en direccion ENTRADA ^(IN^)
        echo.
    ) else (
        set "DIRECCION=IN"
        set "DIRECCION_LOWER=in"
        echo.
        echo [INFO] Direccion cambiada a: ENTRADA ^(IN^)
        echo.
    )
    pause
    goto menu_principal
) else if "!nueva_dir!"=="2" (
    if "!DIRECCION!"=="OUT" (
        echo.
        echo [INFO] Ya se encuentra en direccion SALIDA ^(OUT^)
        echo.
    ) else (
        set "DIRECCION=OUT"
        set "DIRECCION_LOWER=out"
        echo.
        echo [INFO] Direccion cambiada a: SALIDA ^(OUT^)
        echo.
    )
    pause
    goto menu_principal
) else if "!nueva_dir!"=="3" (
    goto menu_principal
) else (
    echo.
    echo [ERROR] Opcion invalida.
    echo.
    pause
    goto cambiar_direccion
)

:bloquear_ip
cls
echo ==========================================================================
echo                       BLOQUEAR IP EN FIREWALL
echo ==========================================================================
echo Direccion actual: !DIRECCION!
echo.

REM Solicitar IP a bloquear
set "IP_OBJETIVO="
set /p "IP_OBJETIVO=Ingrese la IP a bloquear: "

if "!IP_OBJETIVO!"=="" (
    echo.
    echo [ERROR] Debe ingresar una IP valida.
    echo.
    pause
    goto menu_principal
)

REM Validar IP usando funcion reutilizable
call :validar_ip "!IP_OBJETIVO!"
if !errorlevel! neq 0 (
    pause
    goto menu_principal
)

REM Solicitar el nombre de la regla como opcion
echo.
set "comentario="
set /p "comentario=Ingrese el nombre de la regla (opcional): "

REM Validar nombre de regla si no esta vacio
if not "!comentario!"=="" (
    call :validar_nombre "!comentario!"
    if !errorlevel! neq 0 (
        pause
        goto menu_principal
    )
)

REM Crear el nombre de la regla con el formato original (SIN incluir IN/OUT)
set "nombreRegla=Bloquear IP - !IP_OBJETIVO!"
if not "!comentario!"=="" (
    set "nombreRegla=!nombreRegla! (!comentario!)"
)

echo.
echo ==========================================================================
echo Paso 1 - Verificando si la IP ya esta bloqueada
echo ==========================================================================
echo.

echo Ejecutando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! ^| findstr /C:"Bloquear IP - !IP_OBJETIVO!"
echo.

REM Verificar si la IP ya esta bloqueada EN LA DIRECCION ESPECIFICA usando filtro dir=
netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! | findstr /C:"Bloquear IP - !IP_OBJETIVO!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERROR] Verificacion completada:
    echo     ^|
    echo     ^|- La IP !IP_OBJETIVO! ya esta bloqueada
    echo     ^|- No se puede duplicar la regla
    echo.
    pause
    goto menu_principal
) else (
    echo [INFO] Verificacion completada:
    echo     ^|
    echo     ^|- La IP !IP_OBJETIVO! no existe en el firewall
    echo     ^|- Procediendo con el bloqueo
)

echo.
echo ==========================================================================
echo Paso 2 - Ejecutando bloqueo de IP
echo ==========================================================================
echo.

echo Ejecutando comando:
echo netsh advfirewall firewall add rule name="!nombreRegla!" dir=!DIRECCION_LOWER! action=block remoteip=!IP_OBJETIVO!
echo.

REM Ejecutar comando para bloquear la IP EN LA DIRECCION ESPECIFICA
netsh advfirewall firewall add rule name="!nombreRegla!" dir=!DIRECCION_LOWER! action=block remoteip=!IP_OBJETIVO! >nul 2>&1

if !errorlevel! equ 0 (
    echo [EXITO] Bloqueo completado:
    echo     ^|
    echo     ^|- IP: !IP_OBJETIVO! bloqueada correctamente
    echo     ^|- Direccion: !DIRECCION!
    echo     ^|- Nombre: "!nombreRegla!"
) else (
    echo [ERROR] Bloqueo fallido:
    echo     ^|
    echo     ^|- No se pudo bloquear la IP !IP_OBJETIVO!
    echo     ^|- Verifique permisos de administrador
)

echo.
pause
goto menu_principal

:desbloquear_ip
cls
echo ==========================================================================
echo                    DESBLOQUEAR IP EN FIREWALL
echo ==========================================================================
echo Direccion actual: !DIRECCION!
echo.

REM Solicitar IP a desbloquear
set "IP_OBJETIVO="
set /p "IP_OBJETIVO=Ingrese la IP a desbloquear: "

if "!IP_OBJETIVO!"=="" (
    echo.
    echo [ERROR] Debe ingresar una IP valida.
    echo.
    pause
    goto menu_principal
)

REM Validar IP usando funcion reutilizable
call :validar_ip "!IP_OBJETIVO!"
if !errorlevel! neq 0 (
    pause
    goto menu_principal
)

echo.
echo ==========================================================================
echo Paso 1 - Buscando regla de firewall para IP: !IP_OBJETIVO!
echo ==========================================================================
echo.

echo Ejecutando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! ^| findstr /C:"Bloquear IP - !IP_OBJETIVO!"
echo.

REM Verificar si existe alguna regla con la IP especifica EN LA DIRECCION ESPECIFICA
netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! | findstr /C:"Bloquear IP - !IP_OBJETIVO!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] Busqueda completada:
    echo     ^|
    echo     ^|- No se encontraron reglas para la IP !IP_OBJETIVO!
    echo     ^|- Verifique que la IP este bloqueada
    echo.
    pause
    goto menu_principal
)

REM Encontrar la regla exacta EN LA DIRECCION ESPECIFICA
set "ultimaRegla="
for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECCION_LOWER! ^| findstr /C:"Bloquear IP -"') do (
    set "linea=%%a"
    set "nombreRegla=!linea:*Bloquear IP - =!"
    if not "!nombreRegla!"=="!linea!" (
        set "nombreRegla=Bloquear IP - !nombreRegla!"
        for /f "tokens=* delims= " %%b in ("!nombreRegla!") do set "nombreRegla=%%b"
        set "reglaIP=!nombreRegla:Bloquear IP - =!"
        for /f "tokens=1 delims= " %%c in ("!reglaIP!") do set "soloIP=%%c"
        echo !soloIP! | findstr /C:"(" >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "tokens=1 delims=(" %%d in ("!soloIP!") do set "soloIP=%%d"
        )
        if "!soloIP!"=="!IP_OBJETIVO!" (
            set "ultimaRegla=!nombreRegla!"
        )
    )
)

echo [EXITO] Busqueda completada:
echo     ^|
echo     ^|- IP: !IP_OBJETIVO!
echo     ^|- Direccion: !DIRECCION!
echo     ^|- Nombre: "!ultimaRegla!"
echo.

echo ==========================================================================
echo Paso 2 - Ejecutando eliminacion de regla
echo ==========================================================================
echo.

echo Ejecutando comando:
echo netsh advfirewall firewall delete rule name="!ultimaRegla!"
echo.

REM Ejecutar comando para eliminar la regla
netsh advfirewall firewall delete rule name="!ultimaRegla!" >nul 2>&1

if !errorlevel! equ 0 (
    echo [EXITO] Eliminacion completada:
    echo     ^|
    echo     ^|- Regla eliminada correctamente
    echo     ^|- IP: !IP_OBJETIVO!
    echo     ^|- Direccion: !DIRECCION!
    echo     ^|- Nombre: "!ultimaRegla!"
) else (
    echo [ERROR] Eliminacion fallida:
    echo     ^|
    echo     ^|- No se pudo eliminar la regla
    echo     ^|- IP: !IP_OBJETIVO!
    echo     ^|- Nombre: "!ultimaRegla!"
    echo     ^|- [INFO] Verifique permisos de administrador
    echo.
    pause
    goto menu_principal
)

echo.
echo ==========================================================================
echo Paso 3 - Verificando eliminacion de regla
echo ==========================================================================
echo.

echo Ejecutando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! ^| findstr /C:"!IP_OBJETIVO!"
echo.

REM Verificar eliminacion EN LA DIRECCION ESPECIFICA
netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! | findstr /C:"!IP_OBJETIVO!" >nul 2>&1

if !errorlevel! neq 0 (
    echo [EXITO] Verificacion completada:
    echo     ^|
    echo     ^|- IP: !IP_OBJETIVO! eliminada correctamente
    echo     ^|- Direccion: !DIRECCION!
    echo     ^|- Nombre: "!ultimaRegla!"
) else (
    echo [ADVERTENCIA] Verificacion completada:
    echo     ^|
    echo     ^|- Aun existen reglas con la IP !IP_OBJETIVO!
    echo     ^|- Posiblemente hay reglas duplicadas
)

echo.
pause
goto menu_principal

:ver_ips_bloqueadas
cls
echo ==========================================================================
echo                     IPs BLOQUEADAS EN FIREWALL
echo ==========================================================================
echo Direccion actual: !DIRECCION!
echo.

echo Ejecutando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! ^| findstr /C:"Bloquear IP"
echo.

REM Verificar si hay reglas EN LA DIRECCION ESPECIFICA
netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! | findstr /C:"Bloquear IP -" >nul 2>&1

if !errorlevel! neq 0 (
    echo [INFO] Verificacion completada:
    echo     ^|
    echo     ^|- No hay IPs bloqueadas actualmente
    echo.
    pause
    goto menu_principal
)

echo ==========================================================================
echo                        LISTADO DE IPs BLOQUEADAS
echo ==========================================================================
echo.

set "contador=0"

for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECCION_LOWER! ^| findstr /C:"Bloquear IP -"') do (
    set "linea=%%a"
    set "nombreRegla=!linea:*Bloquear IP - =!"
    if not "!nombreRegla!"=="!linea!" (
        set "nombreRegla=Bloquear IP - !nombreRegla!"
        for /f "tokens=* delims= " %%b in ("!nombreRegla!") do set "nombreRegla=%%b"
        set "reglaIP=!nombreRegla:Bloquear IP - =!"
        for /f "tokens=1 delims= " %%c in ("!reglaIP!") do set "soloIP=%%c"
        echo !soloIP! | findstr /C:"(" >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "tokens=1 delims=(" %%d in ("!soloIP!") do set "soloIP=%%d"
        )
        set /a "contador+=1"
        echo [!contador!] Regla encontrada:
        echo     ^|
        echo     ^|- IP: !soloIP!
        echo     ^|- Direccion: !DIRECCION!
        echo     ^|- Nombre: "!nombreRegla!"
        echo.
    )
)

pause
goto menu_principal

:bloquear_puerto
cls
echo ==========================================================================
echo                       BLOQUEAR PUERTO EN FIREWALL
echo ==========================================================================
echo Direccion actual: !DIRECCION!
echo.

set "puerto="
set /p "puerto=Ingrese el puerto a bloquear: "

REM Validar puerto usando funcion reutilizable
call :validar_puerto puerto
if !errorlevel! neq 0 (
    pause
    goto menu_principal
)

echo.
set "protocolo="
set /p "protocolo=Ingrese el protocolo [TCP/UDP] (por defecto TCP): "

if "!protocolo!"=="" set "protocolo=TCP"

REM Validar protocolo usando funcion reutilizable
call :validar_protocolo "!protocolo!"
if !errorlevel! neq 0 (
    pause
    goto menu_principal
)

echo.
set "comentario="
set /p "comentario=Ingrese el nombre de la regla (opcional): "

REM Validar nombre de regla si no esta vacio
if not "!comentario!"=="" (
    call :validar_nombre "!comentario!"
    if !errorlevel! neq 0 (
        pause
        goto menu_principal
    )
)

set "nombreRegla=Bloquear Puerto - !puerto! (!protocolo!)"
if not "!comentario!"=="" (
    set "nombreRegla=!nombreRegla! - !comentario!"
)

echo.
echo ==========================================================================
echo Paso 1 - Verificando si el puerto ya esta bloqueado
echo ==========================================================================
echo.

echo Ejecutando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! ^| findstr /C:"Bloquear Puerto - !puerto!" | findstr /C:"!protocolo!"
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! | findstr /C:"Bloquear Puerto - !puerto!" | findstr /C:"!protocolo!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERROR] Verificacion completada:
    echo     ^|
    echo     ^|- El puerto !puerto! ^(!protocolo!^) ya esta bloqueado
    echo     ^|- No se puede duplicar la regla
    echo.
    pause
    goto menu_principal
) else (
    echo [INFO] Verificacion completada:
    echo     ^|
    echo     ^|- El puerto !puerto! ^(!protocolo!^) no existe en el firewall
    echo     ^|- Procediendo con el bloqueo
)

echo.
echo ==========================================================================
echo Paso 2 - Ejecutando bloqueo de puerto
echo ==========================================================================
echo.

echo Ejecutando comando:
echo netsh advfirewall firewall add rule name="!nombreRegla!" dir=!DIRECCION_LOWER! action=block protocol=!protocolo! localport=!puerto!
echo.

netsh advfirewall firewall add rule name="!nombreRegla!" dir=!DIRECCION_LOWER! action=block protocol=!protocolo! localport=!puerto! >nul 2>&1

if !errorlevel! equ 0 (
    echo [EXITO] Bloqueo completado:
    echo     ^|
    echo     ^|- Puerto: !puerto! bloqueado correctamente
    echo     ^|- Protocolo: !protocolo!
    echo     ^|- Direccion: !DIRECCION!
    echo     ^|- Nombre: "!nombreRegla!"
) else (
    echo [ERROR] Bloqueo fallido:
    echo     ^|
    echo     ^|- No se pudo bloquear el puerto !puerto!
    echo     ^|- Verifique permisos de administrador
)

echo.
pause
goto menu_principal

:desbloquear_puerto
cls
echo ==========================================================================
echo                    DESBLOQUEAR PUERTO EN FIREWALL
echo ==========================================================================
echo Direccion actual: !DIRECCION!
echo.

set "puerto="
set /p "puerto=Ingrese el puerto a desbloquear: "

REM Validar puerto usando funcion reutilizable
call :validar_puerto puerto
if !errorlevel! neq 0 (
    pause
    goto menu_principal
)

echo.
set "protocolo="
set /p "protocolo=Ingrese el protocolo [TCP/UDP] (por defecto TCP): "

if "!protocolo!"=="" set "protocolo=TCP"

REM Validar protocolo usando funcion reutilizable
call :validar_protocolo "!protocolo!"
if !errorlevel! neq 0 (
    pause
    goto menu_principal
)

echo.
echo ==========================================================================
echo Paso 1 - Buscando regla de firewall para puerto: !puerto! (!protocolo!)
echo ==========================================================================
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! | findstr /C:"Bloquear Puerto - !puerto!" | findstr /C:"!protocolo!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] Busqueda completada:
    echo     ^|
    echo     ^|- No se encontraron reglas para el puerto !puerto! "(!protocolo!)"
    echo     ^|- Verifique que el puerto este bloqueado
    echo.
    pause
    goto menu_principal
)

REM Encontrar la regla exacta de puerto
set "ultimaRegla="
for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECCION_LOWER! ^| findstr /C:"Bloquear Puerto -"') do (
    set "linea=%%a"
    set "nombreRegla=!linea:*Bloquear Puerto - =!"
    if not "!nombreRegla!"=="!linea!" (
        set "nombreRegla=Bloquear Puerto - !nombreRegla!"
        for /f "tokens=* delims= " %%b in ("!nombreRegla!") do set "nombreRegla=%%b"
        echo !nombreRegla! | findstr /C:"!puerto!" | findstr /C:"!protocolo!" >nul 2>&1
        if !errorlevel! equ 0 (
            set "ultimaRegla=!nombreRegla!"
        )
    )
)

echo [EXITO] Busqueda completada:
echo     ^|
echo     ^|- Puerto: !puerto!
echo     ^|- Protocolo: !protocolo!
echo     ^|- Direccion: !DIRECCION!
echo     ^|- Nombre: "!ultimaRegla!"
echo.

echo ==========================================================================
echo Paso 2 - Ejecutando eliminacion de regla
echo ==========================================================================
echo.

echo Ejecutando comando:
echo netsh advfirewall firewall delete rule name="!ultimaRegla!"
echo.

netsh advfirewall firewall delete rule name="!ultimaRegla!" >nul 2>&1

if !errorlevel! equ 0 (
    echo [EXITO] Eliminacion completada:
    echo     ^|
    echo     ^|- Regla eliminada correctamente
    echo     ^|- Puerto: !puerto!
    echo     ^|- Protocolo: !protocolo!
    echo     ^|- Direccion: !DIRECCION!
    echo     ^|- Nombre: "!ultimaRegla!"
) else (
    echo [ERROR] Eliminacion fallida:
    echo     ^|
    echo     ^|- No se pudo eliminar la regla
    echo     ^|- Puerto: !puerto!
    echo     ^|- Nombre: "!ultimaRegla!"
)

echo.
pause
goto menu_principal

:ver_puertos_bloqueados
setlocal
cls
echo ==========================================================================
echo                     PUERTOS BLOQUEADOS EN FIREWALL
echo ==========================================================================
echo Direccion actual: !DIRECCION!
echo.

echo Ejecutando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! ^| findstr /C:"Bloquear Puerto"
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECCION_LOWER! | findstr /C:"Bloquear Puerto -" >nul 2>&1
if !errorlevel! neq 0 (
    echo [INFO] Verificacion completada:
    echo     ^|
    echo     ^|- No hay puertos bloqueados actualmente
    echo.
    endlocal
    pause
    goto menu_principal
)

echo ==========================================================================
echo                        LISTADO DE PUERTOS BLOQUEADOS
echo ==========================================================================
echo.

set "contador=0"

for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECCION_LOWER! ^| findstr /C:"Bloquear Puerto -"') do (
    set "linea=%%a"
    set "nombreRegla=!linea:*Bloquear Puerto - =!"
    if not "!nombreRegla!"=="!linea!" (
        set "nombreRegla=Bloquear Puerto - !nombreRegla!"
        for /f "tokens=* delims= " %%b in ("!nombreRegla!") do set "nombreRegla=%%b"
        set "reglaData=!nombreRegla:Bloquear Puerto - =!"
        for /f "tokens=1,2 delims= " %%c in ("!reglaData!") do (
            set "puerto=%%c"
            set "protocoloPart=%%d"
        )
        REM Extraer protocolo entre parentesis
        if defined protocoloPart (
            set "protocolo=!protocoloPart:^(=!"
            set "protocolo=!protocolo:^)=!"
        )
        set /a "contador+=1"
        echo [!contador!] Regla encontrada:
        echo     ^|
        echo     ^|- Puerto: !puerto!
        echo     ^|- Protocolo: !protocolo!
        echo     ^|- Direccion: !DIRECCION!
        echo     ^|- Nombre: "!nombreRegla!"
        echo.
    )
)
endlocal
pause
goto menu_principal



REM =============================================================================
REM                         FUNCIONES DE VALIDACION REUTILIZABLES (Puerto, IP)
REM =============================================================================

::------------------------------------------------------------------------------
:: Funcion: validar_puerto
:: Proposito: Valida y normaliza un puerto o lista de puertos
:: Parametros:
::   %~1 - Nombre de la variable que contiene el puerto
:: Valores de retorno:
::   0 - Exito (puerto valido, variable actualizada)
::   1 - Error (formato invalido)
::------------------------------------------------------------------------------
:validar_puerto
setlocal
call set "puerto=%%%~1%%"

REM Validar que no este vacio
if "!puerto!"=="" (
    echo.
    echo [ERROR] Puerto vacio. Debe ingresar un puerto valido.
    echo.
    endlocal & exit /b 1
)

REM normalizar
set "puerto_norm=!puerto: =!"

REM Validar formato general (solo digitos, comas y guiones)
call :check_formato_puerto "!puerto_norm!"
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Formato de puerto invalido.
    echo     ^|
    echo     ^|- Solo se permiten numeros, comas y guiones
    echo     ^|- Ejemplos validos:
    echo     ^|
    echo     ^|   - 5001 ^(puerto individual^)
    echo     ^|
    echo     ^|   - 5000-5001 ^(rango^)
    echo     ^|   - 5000 - 5001 ^(rango^)
    echo     ^|
    echo     ^|   - 80,443,5000 ^(lista^)
    echo     ^|   - 80, 443, 5000 ^(lista^)
    echo     ^|
    echo     ^|   - 80,443,5000-5001 ^(mezcla^)
    echo     ^|   - 80, 443, 5000-5001 ^(mezcla^)
    echo     ^|   - 80, 443, 5000 - 5001 ^(mezcla^)
    echo.
    endlocal & exit /b 1
)

REM Procesar cada componente
set "puerto_list=!puerto_norm:,= !"

for %%p in (!puerto_list!) do (
    if not "%%p"=="" (
        REM Verificar si es un rango
        ( <nul set /p="%%p" | findstr /C:"-" ) >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "tokens=1,2 delims=-" %%a in ("%%p") do (
                set "inicio=%%a"
                set "fin=%%b"
                
                REM Validar rango
                call :validar_puerto_individual "!inicio!" || exit /b 1
                call :validar_puerto_individual "!fin!" || exit /b 1
                
                set /a num_inicio=0 + !inicio! 2>nul
                set /a num_fin=0 + !fin! 2>nul
                if !num_inicio! gtr !num_fin! (
                    echo.
                    echo [ERROR] Rango invalido: !inicio! ^> !fin!
                    echo     ^|
                    echo     ^|- El puerto inicial debe ser menor o igual al final
                    echo     ^|- Ejemplos validos:
                    echo     ^|   - 5000-5001 ^(rango^)
                    echo.
                    endlocal & exit /b 1
                )
            )
        ) else (
            REM Validar puerto individual
            call :validar_puerto_individual "%%p" || exit /b 1
        )
    )
)

REM Finalizar Funcion y ACTUALIZAR LA VARIABLE ORIGINAL POR REFERENCIA - REM Si llegue aqui, el puerto es valido
endlocal & set "%%~1=!puerto_norm!" & exit /b 0



::------------------------------------------------------------------------------
:: Funcion: check_formato_puerto
:: Proposito: Verifica que el formato del puerto sea valido (digitos, comas, guiones)
:: Parametros:
::   %~1 - Puerto a validar (sin espacios)
:: Valores de retorno:
::   0 - Exito (formato valido)
::   1 - Error (formato invalido)
::------------------------------------------------------------------------------
:check_formato_puerto
setlocal
set "puerto_norm=%~1"

REM Verificar patrones invalidos
if "!puerto_norm:--=!" neq "!puerto_norm!" endlocal & exit /b 1      REM Error si hay guiones dobles (ej: 5000--5001)
if "!puerto_norm:,,=!" neq "!puerto_norm!" endlocal & exit /b 1      REM Error si hay comas dobles (ej: 80,,443)
if "!puerto_norm:~-1!"=="," endlocal & exit /b 1                     REM Error si termina con coma (ej: 80,)
if "!puerto_norm:~-1!"=="-" endlocal & exit /b 1                     REM Error si termina con guion (ej: 5000-)

REM Verificar que solo contenga digitos, comas y guiones
( <nul set /p="!puerto_norm!" | findstr /R /C:"^[0-9][0-9,\-]*$" ) >nul 2>&1
if !errorlevel! neq 0 (
    endlocal & exit /b 1
)
endlocal & exit /b 0




::------------------------------------------------------------------------------
:: Funcion: validar_puerto_individual
:: Proposito: Valida un puerto individual (1-65535) y verifica leading zeros
:: Parametros:
::   %~1 - Puerto a validar
:: Valores de retorno:
::   0 - Exito (puerto valido)
::   1 - Error (puerto invalido)
::------------------------------------------------------------------------------
:validar_puerto_individual
setlocal
set "port=%~1"

REM Validar leading zeros
if "!port:~0,1!"=="0" if not "!port!"=="0" (
    echo.
    echo [ERROR] Leading zero invalido: "!port!"
    echo     ^| Ejemplo invalido: 05000
    echo     ^| Ejemplo valido: 5000
    echo.
    endlocal & exit /b 1
)


REM Validar rango (1-65535)
set /a num=0 + !port! 2>nul
if !num! lss 1 (
    echo.
    echo [ERROR] Puerto invalido: !port!
    echo     ^|
    echo     ^|- Debe estar entre 1 y 65535
    echo     ^|- Ejemplos validos:
    echo     ^|   - 5001 ^(puerto individual^)
    echo     ^|   - 5000-5001 ^(rango^)
    echo     ^|   - 80,443,5000 ^(lista^)
    echo     ^|   - 80,443,5000-5001 ^(mezcla^)
    echo.
    endlocal & exit /b 1
)
if !num! gtr 65535 (
    echo.
    echo [ERROR] Puerto invalido: !port!
    echo     ^|
    echo     ^|- Debe estar entre 1 y 65535
    echo     ^|- Ejemplos validos:
    echo     ^|   - 5001 ^(puerto individual^)
    echo     ^|   - 5000-5001 ^(rango^)
    echo     ^|   - 80,443,5000 ^(lista^)
    echo     ^|   - 80,443,5000-5001 ^(mezcla^)
    echo.
    endlocal & exit /b 1
)
:: Terminar seccion de validacion de Puerto individual
endlocal & exit /b 0




::------------------------------------------------------------------------------
:: Funcion: validar_ip
:: Proposito: Valida una direccion IP (IPv4) o CIDR
:: Parametros:
::   %~1 - IP a validar
:: Valores de retorno:
::   0 - Exito (IP valida)
::   1 - Error (IP invalida)
::------------------------------------------------------------------------------
:validar_ip
setlocal
set "ip=%~1"

REM Validar que no este vacia
if "!ip!"=="" (
    echo.
    echo [ERROR] IP vacia. Debe ingresar una IP valida.
    echo.
    endlocal & exit /b 1
)


REM Detectar si es CIDR y extraer componentes
set "es_cidr=false"
set "ip_base=!ip!"
set "cidr_mask="

<nul set /p="!ip!" | findstr /C:"/" >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=1,* delims=/" %%a in ("!ip!") do (
        set "ip_base=%%a"
        set "cidr_mask=%%b"
    )
    set "es_cidr=true"
)

REM Validar que no contenga puertos (detectar ":")
<nul set /p="!ip!" | findstr /C:":" >nul 2>&1
if !errorlevel! equ 0 (
    echo.
    echo [ERROR] Formato de IP invalido.
    echo     ^|
    echo     ^|- No se permiten puertos ^(ejemplo: 192.168.1.1:443^)
    echo     ^|- Ejemplos validos:
    echo     ^|   - 192.168.1.1    ^(IP individual^)
    echo     ^|   - 192.168.1.0/24 ^(rango CIDR^)
    echo.
    endlocal & exit /b 1
)

REM Validar ip_base formato basico (4 octetos)
( <nul set /p="!ip_base!" | findstr /R /C:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" ) >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Formato de IP invalido.
    echo     ^|
    echo     ^|- Solo se permiten numeros y puntos
    echo     ^|- Ejemplos validos:
    echo     ^|   - 192.168.1.1    ^(IP individual^)
    echo     ^|   - 192.168.1.0/24 ^(rango CIDR^)
    echo.
    endlocal & exit /b 1
)

REM Validar mascara CIDR (Rango CIDR) si existe
if "!es_cidr!"=="true" (
    if "!cidr_mask!"=="" (
        echo.
        echo [ERROR] Mascara CIDR vacia. Formato requerido: IP/MASK
        echo.
        endlocal & exit /b 1
    )   

    REM Validar que la mascara sea numerica
    for /f "delims=0123456789" %%x in ("!cidr_mask!") do (
        echo.
        echo [ERROR] Mascara CIDR invalida: "!cidr_mask!"
        echo     ^|
        echo     ^|- Solo se permiten numeros ^(0-32^)
        echo.
        endlocal & exit /b 1
    )

    REM Validar leading zero en mascara CIDR (rango CIDR)
    if not "!cidr_mask!"=="0" if "!cidr_mask:~0,1!"=="0" (
        echo.
        echo [ERROR] Leading zero invalido en mascara CIDR ^(rango CIDR^): "!cidr_mask!"
        echo     ^| Ejemplo invalido: /024
        echo     ^| Ejemplo valido: /24
        echo.
        endlocal & exit /b 1
    )
    
    REM Validar rango de mascara (0-32)
    set /a num_mask=0 + !cidr_mask! 2>nul
    if !num_mask! lss 0 (
        echo.
        echo [ERROR] Mascara CIDR fuera de rango: !cidr_mask!
        echo     ^|
        echo     ^|- El rango debe estar entre ^(0 y 32^)
        echo.
        endlocal & exit /b 1
    )

    if !num_mask! gtr 32 (
        echo.
        echo [ERROR] Mascara CIDR fuera de rango: !cidr_mask!
        echo     ^|
        echo     ^|- El rango debe estar entre ^(0 y 32^)
        echo.
        endlocal & exit /b 1
    )
)

REM Seguir validando la IP Extrayendo los 4 octetos
for /f "tokens=1-4 delims=." %%a in ("!ip_base!") do (
    set "o1=%%a"
    set "o2=%%b"
    set "o3=%%c"
    set "o4=%%d"
)

REM Validar cada octeto
set "pos=0"
for %%o in (o1 o2 o3 o4) do (
    set /a pos+=1
    call set "valor=%%%%o%%%%"
    
    REM Leading zeros (excepto "0")
    if not "!valor!"=="0" if "!valor:~0,1!"=="0" (
        echo.
        echo [ERROR] Leading zero invalido en octeto !pos!: "!valor!"
        echo     ^| Ejemplo invalido: 192.080.1.1
        echo     ^| Ejemplo valido: 192.80.1.1
        echo.
        endlocal
        exit /b 1
    )
    
    REM Rango 0-255
    set /a num=0 + !valor! 2>nul
    if !num! gtr 255 (
        echo.
        echo [ERROR] Octeto !pos!: "!valor!" ^> 255
        echo     ^| Rango permitido: 0-255
        echo.
        endlocal
        exit /b 1
    )
    if !num! lss 0 (
        echo.
        echo [ERROR] Octeto !pos!: "!valor!" ^< 0
        echo     ^| Rango permitido: 0-255
        echo.
        endlocal
        exit /b 1
    )
)

:: si llegué aqui, es porque la validación de IP fue un éxito
endlocal & exit /b 0




::------------------------------------------------------------------------------
:: Funcion: validar_protocolo
:: Proposito: Valida que el protocolo sea TCP o UDP (case-insensitive)
:: Parametros:
::   %~1 - Protocolo a validar
:: Valores de retorno:
::   0 - Exito (protocolo valido)
::   1 - Error (protocolo invalido)
::------------------------------------------------------------------------------
:validar_protocolo
setlocal
set "protocolo=%~1"

REM Convertir a mayusculas para comparacion
for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") do (
    call set "protocolo=%%protocolo:%%~A%%"
)

REM Validar que sea exactamente TCP o UDP
if /i "!protocolo!"=="TCP" endlocal & exit /b 0
if /i "!protocolo!"=="UDP" endlocal & exit /b 0


echo.
echo [ERROR] Protocolo invalido.
echo     ^|
echo     ^|- Solo se permiten: TCP o UDP
echo     ^|- Ejemplo valido: TCP, tcp, UDP, udp
echo.
endlocal & exit /b 1



::------------------------------------------------------------------------------
:: Funcion: validar_nombre
:: Proposito: Valida el nombre de una regla de firewall
:: Parametros:
::   %~1 - Nombre a validar
:: Valores de retorno:
::   0 - Exito (nombre valido)
::   1 - Error (nombre invalido)
::------------------------------------------------------------------------------
:validar_nombre
setlocal
set "nombre=%~1"

REM Si esta vacio, es valido (opcional)
if "%nombre%"=="" endlocal & exit /b 0

REM Calcular longitud del nombre de la regla, saliendo rapidamente al terminar de recorrer el nombre, para salida temprana
set "nombre_len=0"
REM for /l %%i in (0,1,255) do if "!nombre:~%%i,1!" neq "" set /a nombre_len+=1
for /l %%i in (0,1,255) do (
  if "!nombre:~%%i,1!"=="" goto validar_nombre_fin_len
  set /a nombre_len+=1
)

:validar_nombre_fin_len
::Validar que el nombre de la regla no supere los 255 caracteres
if !nombre_len! gtr 255 (
    echo.
    echo [ERROR] Nombre de regla demasiado largo.
    echo     ^|
    echo     ^|- Longitud maxima: 255 caracteres
    echo.
    endlocal & exit /b 1
)

REM Validar caracteres peligrosos
( <nul set /p="!nombre!" | findstr /R /C:"[^A-Za-z0-9 _-]" ) >nul 2>&1 && (
    echo.
    echo [ERROR] Nombre de regla contiene caracteres peligrosos.
    echo     ^|
    echo     ^|- No se permiten: ^& ^| ^" ^< ^> ^^ %% !!
    echo     ^|- Use solo letras, numeros y espacios
    echo.
    endlocal & exit /b 1
)

REM Validar palabras reservadas peligrosas (con espacio al final)
for %%W in ("format " "del " "remove " "erase " "rd " "rmdir " "delete " "echo " "cmd " "powershell ") do (
    ( <nul set /p=" !nombre! " | findstr /I /C:%%~W ) >nul 2>&1 && (
        echo.
        echo [ERROR] Nombre de regla contiene palabras reservadas.
        echo     ^|
        echo     ^|- No se permiten comandos del sistema
        echo.
        endlocal & exit /b 1
    )
)
endlocal & exit /b 0

:bloquear_adobe
call :gestionar_adobe "bloquear"
goto menu_principal

:desbloquear_adobe
call :gestionar_adobe "desbloquear"
goto menu_principal

:gestionar_adobe
setlocal
set "accion=%~1"
set "app_count=0"
set "result_count=0"
set "rutas_encontradas=0"

REM -----------------------------
REM rutas centralizadas de Adobe
REM -----------------------------
set "ADOBE_PATHS=%ProgramFiles%\Adobe;%ProgramFiles(x86)%\Adobe;%CommonProgramFiles%\Adobe;%CommonProgramFiles(x86)%\Adobe;%ProgramData%\Adobe"

REM Determinar mensaje y operacion
if /i "%accion%"=="bloquear" (
    set "operacion=Bloquear"
    set "verboPasado=Bloqueada"
    set "resultado=Bloqueadas"
    set "mensaje_accion=Procediendo con el bloqueo"
    set "mensaje_exito=Aplicacion bloqueada"
    set "mensaje_error=No se pudo bloquear la aplicacion"
) else (
    set "operacion=Desbloquear"
    set "verboPasado=Desbloqueada"
    set "resultado=Desbloqueadas"
    set "mensaje_accion=Procediendo con el desbloqueo"
    set "mensaje_exito=Aplicacion desbloqueada"
    set "mensaje_error=No se pudo desbloquear la aplicacion"
)

cls
echo ==========================================================================
echo                 %operacion% APLICACIONES DE ADOBE EN FIREWALL
echo ==========================================================================
echo Direccion actual: !DIRECCION!
echo.
echo NOTA: Este proceso %accion%a el acceso a internet a TODOS los ejecutables (.exe) encontrados
echo       de Adobe, para evitar consumo de ancho de banda.
echo.

REM Mostrar rutas a escanear (solo una vez)
echo Buscando en las siguientes ubicaciones de Adobe:
for %%P in ("%ADOBE_PATHS:;=" "%") do (
    echo   - %%~P
)
echo.

REM Escanear cada directorio base y contar las que existen
for %%P in ("%ADOBE_PATHS:;=" "%") do (
    if exist "%%~P" (
        set /a rutas_encontradas+=1
    )
)

REM Mostrar solo las rutas que existen
if !rutas_encontradas! gtr 0 (
    echo Ubicaciones de Adobe encontradas:
    for %%P in ("%ADOBE_PATHS:;=" "%") do (
        if exist "%%~P" echo   - %%~P
    )
    echo.
    
    REM Ahora si escanear las rutas encontradas
    for %%P in ("%ADOBE_PATHS:;=" "%") do (
        if exist "%%~P" (
            echo Escaneando ruta base: %%~P
            REM Iniciar busqueda recursiva hasta 5 niveles
            call :buscar_adobe "%%~P" 1 "!accion!"
        )
    )
) else (
    echo [ADVERTENCIA] No se encontro Adobe instalado en las ubicaciones estandar
    echo     ^| Adobe no esta instalado en ninguna de las ubicaciones tipicas
    echo     ^| Si instalaste Adobe en otra ubicacion, deberas moverlo a una
    echo     ^| de las rutas listadas arriba para que sea detectado automaticamente
    echo.
)

echo.
echo ==========================================================================
echo Resultado del %accion%
echo ==========================================================================
echo.
echo [INFO] Aplicaciones encontradas: !app_count!
echo [INFO] Aplicaciones %resultado%: !result_count!
echo.
pause
endlocal & set "app_count=%app_count%" & set "result_count=%result_count%" & exit /b 0

:buscar_adobe
setlocal
set "ruta=%~1"
set /a "nivel=%~2"
set "accion=%~3"

REM Verificar limite de profundidad (5 niveles maximo)
if %nivel% gtr 5 (
    endlocal
    exit /b 0
)

REM Buscar archivos .exe en el directorio actual
for %%f in ("%ruta%\*.exe") do (
    set "file=%%f"
    set "app_name=%%~nxf"
    
    REM Excluir plugins y componentes esenciales
    set "excluir=0"
    ::if "!file:Plug-ins=!" neq "!file!" set "excluir=1"
    ::if "!file:PlugIns=!" neq "!file!" set "excluir=1"
    ::if "!file:Support Files=!" neq "!file!" set "excluir=1"
    if "!file:Presets=!" neq "!file!" set "excluir=1"
    if "!file:Goodies=!" neq "!file!" set "excluir=1"
    if "!file:Optional=!" neq "!file!" set "excluir=1"
    if "!file:node.exe=!" neq "!file!" set "excluir=1"
    
    if !excluir! equ 0 (
        REM Incrementar contador de aplicaciones encontradas
        set /a "app_count+=1"
        
        REM Preparar nombre para la regla
        set "relative_path=!file:%ProgramFiles%=!"
        set "relative_path=!relative_path:%ProgramFiles(x86)%=!"
        set "relative_path=!relative_path:%ProgramData%=!"
        set "relative_path=!relative_path:\= - !"
        set "rule_name=Bloquear Adobe - !app_name!"
        
        echo.
        echo ==========================================================================
        echo Paso 1 - Verificando si la aplicacion ya esta %verboPasado%
        echo ==========================================================================
        echo.
        
        echo Ejecutando comando:
        echo netsh advfirewall firewall show rule name="!rule_name!"
        echo.
        
        REM Verificar si la regla existe
        netsh advfirewall firewall show rule name="!rule_name!" >nul 2>&1
        set "regla_existe=!errorlevel!"

        if /i "!accion!"=="bloquear" (
            if !regla_existe! equ 0 (
                :: Mostrar Estado Bloqueada
                echo [INFO] Verificacion completada:
                echo     ^|
                echo     ^|- La aplicacion !app_name! ya esta bloqueada
                echo     ^|- No se puede duplicar la regla
                echo.
            ) else (
                :: Ejecutar Bloqueo
                echo [INFO] Verificacion completada:
                echo     ^|
                echo     ^|- La aplicacion !app_name! no existe en el firewall
                echo     ^|   %mensaje_accion%
                echo.
                
                echo ==========================================================================
                echo Paso 2 - Ejecutando Bloqueo de aplicacion
                echo ==========================================================================
                echo.
                
                echo Ejecutando comando:
                echo netsh advfirewall firewall add rule name="!rule_name!" dir=out action=block program="!file!"
                REM Bloquear la aplicacion (solo trafico saliente)
                netsh advfirewall firewall add rule name="!rule_name!" dir=out action=block program="!file!" >nul 2>&1
                
                if !errorlevel! equ 0 (
                    set /a "result_count+=1"
                    echo [EXITO] Bloqueo completado:
                    echo     ^|
                    echo     ^|- Aplicacion: !app_name!
                    echo     ^|- Ruta: !file!
                    echo     ^|- Nombre de regla: "!rule_name!"
                ) else (
                    echo [ERROR] Bloqueo fallido:
                    echo     ^|
                    echo     ^|- %mensaje_error% !app_name!
                    echo     ^|- Verifique permisos de administrador
                )
            )
        ) else (  
            :: Seccion Desbloquear          
            if !regla_existe! equ 0 (
                :: Ejecutar desbloqueo
                echo [INFO] Verificacion completada:
                echo     ^|
                echo     ^|- La aplicacion !app_name! esta bloqueada
                echo     ^|   %mensaje_accion%
                echo.
                
                echo ==========================================================================
                echo Paso 2 - Ejecutando Desbloqueo de aplicacion
                echo ==========================================================================
                echo.
                
                echo Ejecutando comando:
                echo netsh advfirewall firewall delete rule name="!rule_name!"
                REM Desbloquear la aplicacion
                netsh advfirewall firewall delete rule name="!rule_name!" >nul 2>&1
                
                if !errorlevel! equ 0 (
                    set /a "result_count+=1"
                    echo [EXITO] Desbloqueo completado:
                    echo     ^|
                    echo     ^|- Aplicacion: !app_name!
                    echo     ^|- Ruta: !file!
                    echo     ^|- Nombre de regla: "!rule_name!"
                ) else (
                    echo [ERROR] Desbloqueo fallido:
                    echo     ^|
                    echo     ^|- %mensaje_error% !app_name!
                    echo     ^|- Verifique permisos de administrador
                )
            ) else (
                :: Mostrar estado de desbloqueo
                echo [INFO] Verificacion completada:
                echo     ^|
                echo     ^|- La aplicacion !app_name! no esta bloqueada
                echo     ^|- No hay necesidad de desbloquear
                echo.
            )
        )
    )
)

REM Buscar subdirectorios y continuar busqueda recursiva
for /d %%s in ("%ruta%\*") do (
    call :buscar_adobe "%%s" %nivel%+1 "%accion%"
)

endlocal & set "app_count=%app_count%" & set "result_count=%result_count%" & exit /b 0