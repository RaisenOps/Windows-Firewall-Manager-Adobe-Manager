@echo off
setlocal EnableDelayedExpansion

REM Global variables to keep current direction
set "DIRECTION=IN"
set "DIRECTION_LOWER=in"

REM Check if running as administrator
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [ERREUR] L'execution de ce fichier requiert des privileges administrateur.
    echo.
    echo Pour executer en tant qu'administrateur :
    echo     ^|
    echo     ^|- Clic droit sur le fichier .bat
    echo     ^|- Selectionner "Run as administrator"
    echo     ^|
    echo     ^|- Ou ouvrir CMD/Terminal en tant qu'administrateur d'abord
    echo.
    pause
    exit /b 1
)

:select_initial_direction
cls
echo.
echo                                             GESTIONNAIRE WINDOWS FIREWALL
echo                                     ----------------------------------------
echo.
echo ==========================================
echo           SELECTION DIRECTION INITIALE
echo ==========================================
echo.
echo [1] - Regles entrants (IN)
echo [2] - Regles sortants (OUT)
echo.
set /p "dir_choice=Selectionnez la direction initiale [1-2]: "

if "!dir_choice!"=="1" (
    set "DIRECTION=IN"
    set "DIRECTION_LOWER=in"
    goto main_menu
) else if "!dir_choice!"=="2" (
    set "DIRECTION=OUT"
    set "DIRECTION_LOWER=out"
    goto main_menu
) else (
    echo.
    echo [ERREUR] Option invalide. Vous pouvez seulement saisir 1 ou 2.
    echo.
    pause
    goto select_initial_direction
)

:main_menu
cls
echo.
echo                                             GESTIONNAIRE WINDOWS FIREWALL
echo                                     ----------------------------------------
echo.
echo ==========================================
echo             MENU PRINCIPAL
echo ==========================================
echo.
echo Direction actuelle : !DIRECTION!
echo.
echo      ---- GESTION IP ----
echo [1] - Bloquer IP
echo [2] - Debloquer IP
echo [3] - Voir IP bloquees
echo.
echo      ---- GESTION PORTS ----
echo [4] - Bloquer / Fermer / Refuser Port
echo [5] - Debloquer / Ouvrir / Autoriser Port
echo [6] - Voir Ports bloques
echo.
echo      ---- GESTION ADOBE ----
echo [7] - Bloquer applications Adobe
echo [8] - Debloquer applications Adobe
echo.
echo      ---- CONFIGURATION ----
echo [9] - Changer direction ^(regles IN/OUT^)
echo [10] - Quitter
echo.
set /p "option_menu=Entrez votre option [1-10]: "

if "!option_menu!"=="1" goto block_ip
if "!option_menu!"=="2" goto unblock_ip
if "!option_menu!"=="3" goto view_blocked_ips
if "!option_menu!"=="4" goto block_port
if "!option_menu!"=="5" goto unblock_port
if "!option_menu!"=="6" goto view_blocked_ports
if "!option_menu!"=="7" goto block_adobe
if "!option_menu!"=="8" goto unblock_adobe
if "!option_menu!"=="9" goto change_direction
if "!option_menu!"=="10" exit

echo.
echo [ERREUR] Option invalide. Vous pouvez seulement entrer des valeurs de 1 a 10.
echo.
pause
goto main_menu

:change_direction
cls
echo ==========================================================================
echo                    CHANGER DIRECTION DES REGLES
echo ==========================================================================
echo.
echo Direction actuelle : !DIRECTION!
echo.
echo [1] - Changer vers ENTRANT (IN)
echo [2] - Changer vers SORTANT (OUT)
echo [3] - Retour au menu principal
echo.
set /p "new_dir=Selectionnez la nouvelle direction [1-3]: "

if "!new_dir!"=="1" (
    if "!DIRECTION!"=="IN" (
        echo.
        echo [INFO] Deja en mode ENTRANT ^(IN^)
        echo.
    ) else (
        set "DIRECTION=IN"
        set "DIRECTION_LOWER=in"
        echo.
        echo [INFO] Direction changee en : ENTRANT ^(IN^)
        echo.
    )
    pause
    goto main_menu
) else if "!new_dir!"=="2" (
    if "!DIRECTION!"=="OUT" (
        echo.
        echo [INFO] Deja en mode SORTANT ^(OUT^)
        echo.
    ) else (
        set "DIRECTION=OUT"
        set "DIRECTION_LOWER=out"
        echo.
        echo [INFO] Direction changee en : SORTANT ^(OUT^)
        echo.
    )
    pause
    goto main_menu
) else if "!new_dir!"=="3" (
    goto main_menu
) else (
    echo.
    echo [ERREUR] Option invalide.
    echo.
    pause
    goto change_direction
)

:block_ip
cls
echo ==========================================================================
echo                       BLOQUER IP DANS LE FIREWALL
echo ==========================================================================
echo Direction actuelle : !DIRECTION!
echo.

REM Demander l'IP a bloquer
set "targetIP="
set /p "targetIP=Entrez l'IP a bloquer: "

if "!targetIP!"=="" (
    echo.
    echo [ERREUR] Vous devez entrer une IP valide.
    echo.
    pause
    goto main_menu
)

REM Valider IP en utilisant la fonction reutilisable
call :validate_ip "!targetIP!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

REM Demander le nom de la regle (optionnel)
echo.
set "comment="
set /p "comment=Entrez le nom de la regle (optionnel): "

REM Valider le nom de la regle si non vide
if not "!comment!"=="" (
    call :validate_name "!comment!"
    if !errorlevel! neq 0 (
        pause
        goto main_menu
    )
)

REM Creer le nom de la regle au format original (SANS inclure IN/OUT)
set "ruleName=Bloquer IP - !targetIP!"
if not "!comment!"=="" (
    set "ruleName=!ruleName! (!comment!)"
)

echo.
echo ==========================================================================
echo Etape 1 - Verification si l'IP est deja bloquee
echo ==========================================================================
echo.

echo Execution de la commande:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloquer IP - !targetIP!"
echo.

REM Verifier si l'IP est deja bloquee DANS LA DIRECTION SPECIFIQUE en utilisant le filtre dir=
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquer IP - !targetIP!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERREUR] Verification terminee :
    echo     ^|
    echo     ^|- L'IP !targetIP! est deja bloquee
    echo     ^|- Impossible de dupliquer la regle
    echo.
    pause
    goto main_menu
) else (
    echo [INFO] Verification terminee :
    echo     ^|
    echo     ^|- L'IP !targetIP! n'est pas presente dans le firewall
    echo     ^|- Procede au blocage
)

echo.
echo ==========================================================================
echo Etape 2 - Execution du blocage de l'IP
echo ==========================================================================
echo.

echo Execution de la commande:
echo netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block remoteip=!targetIP!
echo.

REM Executer la commande pour bloquer l'IP DANS LA DIRECTION SPECIFIQUE
netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block remoteip=!targetIP! >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCES] Blocage effectue :
    echo     ^|
    echo     ^|- IP: !targetIP! bloquee avec succes
    echo     ^|- Direction: !DIRECTION!
    echo     ^|- Nom: "!ruleName!"
) else (
    echo [ERREUR] Blocage echoue :
    echo     ^|
    echo     ^|- Impossible de bloquer l'IP !targetIP!
    echo     ^|- Verifiez les privileges administrateur
)

echo.
pause
goto main_menu

:unblock_ip
cls
echo ==========================================================================
echo                    DEBLOQUER IP DANS LE FIREWALL
echo ==========================================================================
echo Direction actuelle : !DIRECTION!
echo.

REM Demander l'IP a debloquer
set "targetIP="
set /p "targetIP=Entrez l'IP a debloquer: "

if "!targetIP!"=="" (
    echo.
    echo [ERREUR] Vous devez entrer une IP valide.
    echo.
    pause
    goto main_menu
)

REM Valider IP en utilisant la fonction reutilisable
call :validate_ip "!targetIP!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Etape 1 - Recherche de la regle firewall pour l'IP : !targetIP!
echo ==========================================================================
echo.

echo Execution de la commande:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloquer IP - !targetIP!"
echo.

REM Verifier s'il existe une regle avec l'IP specifique DANS LA DIRECTION SPECIFIQUE
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquer IP - !targetIP!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERREUR] Recherche terminee :
    echo     ^|
    echo     ^|- Aucune regle trouvee pour l'IP !targetIP!
    echo     ^|- Verifiez que l'IP est bien bloquee
    echo.
    pause
    goto main_menu
)

REM Trouver la regle exacte DANS LA DIRECTION SPECIFIQUE
set "lastRule="
for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloquer IP -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloquer IP - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloquer IP - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleIP=!ruleNameLine:Bloquer IP - =!"
        for /f "tokens=1 delims= " %%c in ("!ruleIP!") do set "onlyIP=%%c"
        echo !onlyIP! | findstr /C:"(" >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "tokens=1 delims=(" %%d in ("!onlyIP!") do set "onlyIP=%%d"
        )
        if "!onlyIP!"=="!targetIP!" (
            set "lastRule=!ruleNameLine!"
        )
    )
)

echo [SUCCES] Recherche terminee :
echo     ^|
echo     ^|- IP: !targetIP!
echo     ^|- Direction: !DIRECTION!
echo     ^|- Nom: "!lastRule!"
echo.

echo ==========================================================================
echo Etape 2 - Execution de la suppression de la regle
echo ==========================================================================
echo.

echo Execution de la commande:
echo netsh advfirewall firewall delete rule name="!lastRule!"
echo.

REM Executer la commande pour supprimer la regle
netsh advfirewall firewall delete rule name="!lastRule!" >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCES] Suppression effectuee :
    echo     ^|
    echo     ^|- Regle supprimee avec succes
    echo     ^|- IP: !targetIP!
    echo     ^|- Direction: !DIRECTION!
    echo     ^|- Nom: "!lastRule!"
) else (
    echo [ERREUR] Suppression echouee :
    echo     ^|
    echo     ^|- Impossible de supprimer la regle
    echo     ^|- IP: !targetIP!
    echo     ^|- Nom: "!lastRule!"
    echo     ^|- [INFO] Verifiez les privileges administrateur
    echo.
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Etape 3 - Verification de la suppression de la regle
echo ==========================================================================
echo.

echo Execution de la commande:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"!targetIP!"
echo.

REM Verifier la suppression DANS LA DIRECTION SPECIFIQUE
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"!targetIP!" >nul 2>&1

if !errorlevel! neq 0 (
    echo [SUCCES] Verification terminee :
    echo     ^|
    echo     ^|- IP: !targetIP! supprimee avec succes
    echo     ^|- Direction: !DIRECTION!
    echo     ^|- Nom: "!lastRule!"
) else (
    echo [ATTENTION] Verification terminee :
    echo     ^|
    echo     ^|- Des regles contenant l'IP !targetIP! existent encore
    echo     ^|- Il peut y avoir des regles dupliquees
)

echo.
pause
goto main_menu

:view_blocked_ips
cls
echo ==========================================================================
echo                     IPS BLOQUEES DANS LE FIREWALL
echo ==========================================================================
echo Direction actuelle : !DIRECTION!
echo.

echo Execution de la commande:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloquer IP"
echo.

REM Verifier s'il y a des regles DANS LA DIRECTION SPECIFIQUE
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquer IP -" >nul 2>&1

if !errorlevel! neq 0 (
    echo [INFO] Verification terminee :
    echo     ^|
    echo     ^|- Il n'y a pas d'IPs bloquees actuellement
    echo.
    pause
    goto main_menu
)

echo ==========================================================================
echo                        LISTE DES IPS BLOQUEES
echo ==========================================================================
echo.

set "counter=0"

for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloquer IP -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloquer IP - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloquer IP - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleIP=!ruleNameLine:Bloquer IP - =!"
        for /f "tokens=1 delims= " %%c in ("!ruleIP!") do set "onlyIP=%%c"
        echo !onlyIP! | findstr /C:"(" >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "tokens=1 delims=(" %%d in ("!onlyIP!") do set "onlyIP=%%d"
        )
        set /a "counter+=1"
        echo [!counter!] Regle trouvee :
        echo     ^|
        echo     ^|- IP: !onlyIP!
        echo     ^|- Direction: !DIRECTION!
        echo     ^|- Nom: "!ruleNameLine!"
        echo.
    )
)

pause
goto main_menu

:block_port
cls
echo ==========================================================================
echo                       BLOQUER PORT DANS LE FIREWALL
echo ==========================================================================
echo Direction actuelle : !DIRECTION!
echo.

set "port="
set /p "port=Entrez le port a bloquer: "

REM Valider le port en utilisant la fonction reutilisable
call :validate_port port
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "protocol="
set /p "protocol=Entrez le protocole [TCP/UDP] (par defaut TCP): "

if "!protocol!"=="" set "protocol=TCP"

REM Valider le protocole en utilisant la fonction reutilisable
call :validate_protocol "!protocol!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "comment="
set /p "comment=Entrez le nom de la regle (optionnel): "

REM Valider le nom de la regle si non vide
if not "!comment!"=="" (
    call :validate_name "!comment!"
    if !errorlevel! neq 0 (
        pause
        goto main_menu
    )
)

set "ruleName=Bloquer Port - !port! (!protocol!)"
if not "!comment!"=="" (
    set "ruleName=!ruleName! - !comment!"
)

echo.
echo ==========================================================================
echo Etape 1 - Verification si le port est deja bloque
echo ==========================================================================
echo.

echo Execution de la commande:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloquer Port - !port!" | findstr /C:"!protocol!"
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquer Port - !port!" | findstr /C:"!protocol!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERREUR] Verification terminee :
    echo     ^|
    echo     ^|- Le port !port! ^(!protocol!^) est deja bloque
    echo     ^|- Impossible de dupliquer la regle
    echo.
    pause
    goto main_menu
) else (
    echo [INFO] Verification terminee :
    echo     ^|
    echo     ^|- Le port !port! ^(!protocol!^) n'existe pas dans le firewall
    echo     ^|- Procede au blocage
)

echo.
echo ==========================================================================
echo Etape 2 - Execution du blocage du port
echo ==========================================================================
echo.

echo Execution de la commande:
echo netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block protocol=!protocol! localport=!port!
echo.

netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block protocol=!protocol! localport=!port! >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCES] Blocage effectue :
    echo     ^|
    echo     ^|- Port: !port! bloque avec succes
    echo     ^|- Protocole: !protocol!
    echo     ^|- Direction: !DIRECTION!
    echo     ^|- Nom: "!ruleName!"
) else (
    echo [ERREUR] Blocage echoue :
    echo     ^|
    echo     ^|- Impossible de bloquer le port !port!
    echo     ^|- Verifiez les privileges administrateur
)

echo.
pause
goto main_menu

:unblock_port
cls
echo ==========================================================================
echo                    DEBLOQUER PORT DANS LE FIREWALL
echo ==========================================================================
echo Direction actuelle : !DIRECTION!
echo.

set "port="
set /p "port=Entrez le port a debloquer: "

REM Valider le port en utilisant la fonction reutilisable
call :validate_port port
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "protocol="
set /p "protocol=Entrez le protocole [TCP/UDP] (par defaut TCP): "

if "!protocol!"=="" set "protocol=TCP"

REM Valider le protocole en utilisant la fonction reutilisable
call :validate_protocol "!protocol!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Etape 1 - Recherche de la regle firewall pour le port : !port! (!protocol!)
echo ==========================================================================
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquer Port - !port!" | findstr /C:"!protocol!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERREUR] Recherche terminee :
    echo     ^|
    echo     ^|- Aucune regle trouvee pour le port !port! "(!protocol!)"
    echo     ^|- Verifiez que le port est bloque
    echo.
    pause
    goto main_menu
)

REM Trouver la regle exacte de port
set "lastRule="
for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloquer Port -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloquer Port - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloquer Port - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        echo !ruleNameLine! | findstr /C:"!port!" | findstr /C:"!protocol!" >nul 2>&1
        if !errorlevel! equ 0 (
            set "lastRule=!ruleNameLine!"
        )
    )
)

echo [SUCCES] Recherche terminee :
echo     ^|
echo     ^|- Port: !port!
echo     ^|- Protocole: !protocol!
echo     ^|- Direction: !DIRECTION!
echo     ^|- Nom: "!lastRule!"
echo.

echo ==========================================================================
echo Etape 2 - Execution de la suppression de la regle
echo ==========================================================================
echo.

echo Execution de la commande:
echo netsh advfirewall firewall delete rule name="!lastRule!"
echo.

netsh advfirewall firewall delete rule name="!lastRule!" >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCES] Suppression effectuee :
    echo     ^|
    echo     ^|- Regle supprimee avec succes
    echo     ^|- Port: !port!
    echo     ^|- Protocole: !protocol!
    echo     ^|- Direction: !DIRECTION!
    echo     ^|- Nom: "!lastRule!"
) else (
    echo [ERREUR] Suppression echouee :
    echo     ^|
    echo     ^|- Impossible de supprimer la regle
    echo     ^|- Port: !port!
    echo     ^|- Nom: "!lastRule!"
)

echo.
pause
goto main_menu

:view_blocked_ports
setlocal
cls
echo ==========================================================================
echo                     PORTS BLOQUES DANS LE FIREWALL
echo ==========================================================================
echo Direction actuelle : !DIRECTION!
echo.

echo Execution de la commande:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloquer Port"
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquer Port -" >nul 2>&1
if !errorlevel! neq 0 (
    echo [INFO] Verification terminee :
    echo     ^|
    echo     ^|- Il n'y a pas de ports bloques actuellement
    echo.
    endlocal
    pause
    goto main_menu
)

echo ==========================================================================
echo                        LISTE DES PORTS BLOQUES
echo ==========================================================================
echo.

set "counter=0"

for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloquer Port -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloquer Port - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloquer Port - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleData=!ruleNameLine:Bloquer Port - =!"
        for /f "tokens=1,2 delims= " %%c in ("!ruleData!") do (
            set "port=%%c"
            set "protocolPart=%%d"
        )
        REM Extract protocol between parentheses
        if defined protocolPart (
            set "protocol=!protocolPart:^(=!"
            set "protocol=!protocol:^)=!"
        )
        set /a "counter+=1"
        echo [!counter!] Regle trouvee :
        echo     ^|
        echo     ^|- Port: !port!
        echo     ^|- Protocole: !protocol!
        echo     ^|- Direction: !DIRECTION!
        echo     ^|- Nom: "!ruleNameLine!"
        echo.
    )
)
endlocal
pause
goto main_menu



REM =============================================================================
REM                       REUTILISABLES FONCTIONS DE VALIDATION (Port, IP)
REM =============================================================================

::------------------------------------------------------------------------------
:: Function: validate_port
:: Purpose: Validate and normalize a port or list of ports
:: Parameters:
::   %~1 - Name of the variable that contains the port
:: Return values:
::   0 - Success (valid port, variable updated)
::   1 - Error (invalid format)
::------------------------------------------------------------------------------
:validate_port
setlocal
call set "port=%%%~1%%"

REM Validate not empty
if "!port!"=="" (
    echo.
    echo [ERREUR] Port vide. Vous devez entrer un port valide.
    echo.
    endlocal & exit /b 1
)

REM normalize
set "port_norm=!port: =!"

REM Validate general format (digits, commas and hyphens only)
call :check_port_format "!port_norm!"
if !errorlevel! neq 0 (
    echo.
    echo [ERREUR] Format de port invalide.
    echo     ^|
    echo     ^|- Seuls les chiffres, les virgules et les tirets sont autorises
    echo     ^|- Exemples valides :
    echo     ^|
    echo     ^|   - 5001 ^(port simple^)
    echo     ^|
    echo     ^|   - 5000-5001 ^(intervalle^)
    echo     ^|   - 5000 - 5001 ^(intervalle^)
    echo     ^|
    echo     ^|   - 80,443,5000 ^(liste^)
    echo     ^|   - 80, 443, 5000 ^(liste^)
    echo     ^|
    echo     ^|   - 80,443,5000-5001 ^(melange^)
    echo     ^|   - 80, 443, 5000-5001 ^(melange^)
    echo     ^|   - 80, 443, 5000 - 5001 ^(melange^)
    echo.
    endlocal & exit /b 1
)

REM Process each component
set "port_list=!port_norm:,= !"

for %%p in (!port_list!) do (
    if not "%%p"=="" (
        REM Check if it's a range
        ( <nul set /p="%%p" | findstr /C:"-" ) >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "tokens=1,2 delims=-" %%a in ("%%p") do (
                set "start=%%a"
                set "end=%%b"
                
                REM Validate range
                call :validate_individual_port "!start!" || exit /b 1
                call :validate_individual_port "!end!" || exit /b 1
                
                set /a num_start=0 + !start! 2>nul
                set /a num_end=0 + !end! 2>nul
                if !num_start! gtr !num_end! (
                    echo.
                    echo [ERREUR] Intervalle invalide : !start! ^> !end!
                    echo     ^|
                    echo     ^|- Le port de debut doit etre inferieur ou egal au port de fin
                    echo     ^|- Exemple valide :
                    echo     ^|   - 5000-5001 ^(intervalle^)
                    echo.
                    endlocal & exit /b 1
                )
            )
        ) else (
            REM Validate single port
            call :validate_individual_port "%%p" || exit /b 1
        )
    )
)

REM Finish function and UPDATE ORIGINAL VARIABLE BY REFERENCE - If we reached here, port is valid
endlocal & set "%%~1=!port_norm!" & exit /b 0



::------------------------------------------------------------------------------
:: Function: check_port_format
:: Purpose: Verify port format is valid (digits, commas, hyphens)
:: Parameters:
::   %~1 - Port to validate (without spaces)
:: Return values:
::   0 - Success (valid format)
::   1 - Error (invalid format)
::------------------------------------------------------------------------------
:check_port_format
setlocal
set "port_norm=%~1"

REM Check invalid patterns
if "!port_norm:--=!" neq "!port_norm!" endlocal & exit /b 1      REM Error if double hyphens (e.g., 5000--5001)
if "!port_norm:,,=!" neq "!port_norm!" endlocal & exit /b 1      REM Error if double commas (e.g., 80,,443)
if "!port_norm:~-1!"=="," endlocal & exit /b 1                     REM Error if ends with comma (e.g., 80,)
if "!port_norm:~-1!"=="-" endlocal & exit /b 1                     REM Error if ends with hyphen (e.g., 5000-)

REM Verify contains only digits, commas and hyphens
( <nul set /p="!port_norm!" | findstr /R /C:"^[0-9][0-9,\-]*$" ) >nul 2>&1
if !errorlevel! neq 0 (
    endlocal & exit /b 1
)
endlocal & exit /b 0




::------------------------------------------------------------------------------
:: Function: validate_individual_port
:: Purpose: Validate a single port (1-65535) and check leading zeros
:: Parameters:
::   %~1 - Port to validate
:: Return:
::   0 - Success (valid)
::   1 - Error (invalid)
::------------------------------------------------------------------------------
:validate_individual_port
setlocal
set "port=%~1"

REM Leading zeros
if "!port:~0,1!"=="0" if not "!port!"=="0" (
    echo.
    echo [ERREUR] Zero initial invalide : "!port!"
    echo     ^| Exemple invalide: 05000
    echo     ^| Exemple valide: 5000
    echo.
    endlocal & exit /b 1
)


REM Validate range (1-65535)
set /a num=0 + !port! 2>nul
if !num! lss 1 (
    echo.
    echo [ERREUR] Port invalide: !port!
    echo     ^|
    echo     ^|- Doit etre entre 1 et 65535
    echo     ^|- Exemples valides :
    echo     ^|   - 5001 ^(port simple^)
    echo     ^|   - 5000-5001 ^(intervalle^)
    echo     ^|   - 80,443,5000 ^(liste^)
    echo     ^|   - 80,443,5000-5001 ^(melange^)
    echo.
    endlocal & exit /b 1
)
if !num! gtr 65535 (
    echo.
    echo [ERREUR] Port invalide: !port!
    echo     ^|
    echo     ^|- Doit etre entre 1 et 65535
    echo     ^|- Exemples valides :
    echo     ^|   - 5001 ^(port simple^)
    echo     ^|   - 5000-5001 ^(intervalle^)
    echo     ^|   - 80,443,5000 ^(liste^)
    echo     ^|   - 80,443,5000-5001 ^(melange^)
    echo.
    endlocal & exit /b 1
)
:: End individual port validation section
endlocal & exit /b 0




::------------------------------------------------------------------------------
:: Function: validate_ip
:: Purpose: Validate an IPv4 address or CIDR
:: Parameters:
::   %~1 - IP to validate
:: Return values:
::   0 - Success (valid IP)
::   1 - Error (invalid IP)
::------------------------------------------------------------------------------
:validate_ip
setlocal
set "ip=%~1"

REM Validate not empty
if "!ip!"=="" (
    echo.
    echo [ERREUR] IP vide. Vous devez entrer une IP valide.
    echo.
    endlocal & exit /b 1
)


REM Detect CIDR and extract components
set "is_cidr=false"
set "ip_base=!ip!"
set "cidr_mask="

<nul set /p="!ip!" | findstr /C:"/" >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=1,* delims=/" %%a in ("!ip!") do (
        set "ip_base=%%a"
        set "cidr_mask=%%b"
    )
    set "is_cidr=true"
)

REM Validate that it does not contain ports (detect ":")
<nul set /p="!ip!" | findstr /C:":" >nul 2>&1
if !errorlevel! equ 0 (
    echo.
    echo [ERREUR] Format d'IP invalide.
    echo     ^|
    echo     ^|- Les ports ne sont pas autorises ^(ex: 192.168.1.1:443^)
    echo     ^|- Exemples valides :
    echo     ^|   - 192.168.1.1    ^(IP simple^)
    echo     ^|   - 192.168.1.0/24 ^(intervalle CIDR^)
    echo.
    endlocal & exit /b 1
)

REM Validate ip_base basic format (4 octets)
( <nul set /p="!ip_base!" | findstr /R /C:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" ) >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [ERREUR] Format d'IP invalide.
    echo     ^|
    echo     ^|- Seuls les nombres et les points sont autorises
    echo     ^|- Exemples valides :
    echo     ^|   - 192.168.1.1    ^(IP simple^)
    echo     ^|   - 192.168.1.0/24 ^(intervalle CIDR^)
    echo.
    endlocal & exit /b 1
)

REM Validate CIDR mask (if present)
if "!is_cidr!"=="true" (
    if "!cidr_mask!"=="" (
        echo.
        echo [ERREUR] Masque CIDR vide. Format requis: IP/MASK
        echo.
        endlocal & exit /b 1
    )   

    REM Validate mask is numeric
    for /f "delims=0123456789" %%x in ("!cidr_mask!") do (
        echo.
        echo [ERREUR] Masque CIDR invalide: "!cidr_mask!"
        echo     ^|
        echo     ^|- Seuls les nombres sont autorises ^(0-32^)
        echo.
        endlocal & exit /b 1
    )

    REM Validate leading zero in CIDR mask
    if not "!cidr_mask!"=="0" if "!cidr_mask:~0,1!"=="0" (
        echo.
        echo [ERREUR] Zero initial invalide dans le masque CIDR ^(CIDR^): "!cidr_mask!"
        echo     ^| Exemple invalide: /024
        echo     ^| Exemple valide: /24
        echo.
        endlocal & exit /b 1
    )
    
    REM Validate mask range (0-32)
    set /a num_mask=0 + !cidr_mask! 2>nul
    if !num_mask! lss 0 (
        echo.
        echo [ERREUR] Masque CIDR hors plage : !cidr_mask!
        echo     ^|
        echo     ^|- La plage doit etre entre ^(0 et 32^)
        echo.
        endlocal & exit /b 1
    )

    if !num_mask! gtr 32 (
        echo.
        echo [ERREUR] Masque CIDR hors plage : !cidr_mask!
        echo     ^|
        echo     ^|- La plage doit etre entre ^(0 et 32^)
        echo.
        endlocal & exit /b 1
    )
)

REM Continue validating the IP by extracting the 4 octets
for /f "tokens=1-4 delims=." %%a in ("!ip_base!") do (
    set "o1=%%a"
    set "o2=%%b"
    set "o3=%%c"
    set "o4=%%d"
)

REM Validate each octet
set "pos=0"
for %%o in (o1 o2 o3 o4) do (
    set /a pos+=1
    call set "value=%%%%o%%%%"
    
    REM Leading zeros (except "0")
    if not "!value!"=="0" if "!value:~0,1!"=="0" (
        echo.
        echo [ERREUR] Zero initial invalide dans l'octet !pos! : "!value!"
        echo     ^| Exemple invalide: 192.080.1.1
        echo     ^| Exemple valide: 192.80.1.1
        echo.
        endlocal
        exit /b 1
    )
    
    REM Range 0-255
    set /a num=0 + !value! 2>nul
    if !num! gtr 255 (
        echo.
        echo [ERREUR] Octet !pos!: "!value!" ^> 255
        echo     ^| Plage autorisee: 0-255
        echo.
        endlocal
        exit /b 1
    )
    if !num! lss 0 (
        echo.
        echo [ERREUR] Octet !pos!: "!value!" ^< 0
        echo     ^| Plage autorisee: 0-255
        echo.
        endlocal
        exit /b 1
    )
)

:: if we got here, IP validation was successful
endlocal & exit /b 0




::------------------------------------------------------------------------------
:: Function: validate_protocol
:: Purpose: Validate that protocol is TCP or UDP (case-insensitive)
:: Parameters:
::   %~1 - Protocol to validate
:: Return:
::   0 - Success (valid)
::   1 - Error (invalid)
::------------------------------------------------------------------------------
:validate_protocol
setlocal
set "protocol=%~1"

REM Convert to uppercase for comparison
for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") do (
    call set "protocol=%%protocol:%%~A%%"
)

REM Validate exactly TCP or UDP
if /i "!protocol!"=="TCP" endlocal & exit /b 0
if /i "!protocol!"=="UDP" endlocal & exit /b 0


echo.
echo [ERREUR] Protocole invalide.
echo     ^|
echo     ^|- Seuls : TCP ou UDP sont autorises
echo     ^|- Exemples valides: TCP, tcp, UDP, udp
echo.
endlocal & exit /b 1



::------------------------------------------------------------------------------
:: Function: validate_name
:: Purpose: Validate firewall rule name
:: Parameters:
::   %~1 - Name to validate
:: Return:
::   0 - Success (valid)
::   1 - Error (invalid)
::------------------------------------------------------------------------------
:validate_name
setlocal
set "name=%~1"

REM If empty, it's valid (optional)
if "%name%"=="" endlocal & exit /b 0

REM Calculate length of rule name, exit early when reaching end of string
set "name_len=0"
REM for /l %%i in (0,1,255) do if "!name:~%%i,1!" neq "" set /a name_len+=1
for /l %%i in (0,1,255) do (
  if "!name:~%%i,1!"=="" goto validate_name_fin_len
  set /a name_len+=1
)

:validate_name_fin_len
:: Validate that rule name does not exceed 255 characters
if !name_len! gtr 255 (
    echo.
    echo [ERREUR] Nom de regle trop long.
    echo     ^|
    echo     ^|- Longueur maximum : 255 caracteres
    echo.
    endlocal & exit /b 1
)

REM Validate dangerous characters
( <nul set /p="!name!" | findstr /R /C:"[^A-Za-z0-9 _-]" ) >nul 2>&1 && (
    echo.
    echo [ERREUR] Le nom de la regle contient des caracteres dangereux.
    echo     ^|
    echo     ^|- Non autorise : ^& ^| ^" ^< ^> ^^ %% !!
    echo     ^|- Utilisez seulement lettres, chiffres et espaces
    echo.
    endlocal & exit /b 1
)

REM Validate dangerous reserved words (with trailing space)
for %%W in ("format " "del " "remove " "erase " "rd " "rmdir " "delete " "echo " "cmd " "powershell ") do (
    ( <nul set /p=" !name! " | findstr /I /C:%%~W ) >nul 2>&1 && (
        echo.
        echo [ERREUR] Le nom de la regle contient des mots reserves.
        echo     ^|
        echo     ^|- Les commandes systeme ne sont pas autorisees
        echo.
        endlocal & exit /b 1
    )
)
endlocal & exit /b 0

:block_adobe
call :manage_adobe "block"
goto main_menu

:unblock_adobe
call :manage_adobe "unblock"
goto main_menu

:manage_adobe
setlocal
set "action=%~1"
set "app_count=0"
set "result_count=0"
set "paths_found=0"

REM -----------------------------
REM centralized Adobe paths
REM -----------------------------
set "ADOBE_PATHS=%ProgramFiles%\Adobe;%ProgramFiles(x86)%\Adobe;%CommonProgramFiles%\Adobe;%CommonProgramFiles(x86)%\Adobe;%ProgramData%\Adobe"

REM Determine message and operation
if /i "%action%"=="block" (
    set "operation=Bloquer"
    set "verbPast=Bloquee"
    set "result=Bloquees"
    set "message_action=Proceeding with blocking"
    set "message_success=Application bloquee"
    set "message_error=Impossible de bloquer l'application"
) else (
    set "operation=Debloquer"
    set "verbPast=Debloquee"
    set "result=Debloquees"
    set "message_action=Proceeding with unblocking"
    set "message_success=Application debloquee"
    set "message_error=Impossible de debloquer l'application"
)

cls
echo ==========================================================================
echo                 %operation% APPLICATIONS ADOBE DANS LE FIREWALL
echo ==========================================================================
echo Direction actuelle : !DIRECTION!
echo.
echo NOTE: Ce processus va %action% l'acces internet pour TOUS les executables (.exe)
echo       pour Adobe, afin d'eviter l'utilisation de la bande passante.
echo.

REM Show paths to scan (only once)
echo Recherche dans les emplacements Adobe suivants :
for %%P in ("%ADOBE_PATHS:;=" "%") do (
    echo   - %%~P
)
echo.

REM Scan each base directory and count those that exist
for %%P in ("%ADOBE_PATHS:;=" "%") do (
    if exist "%%~P" (
        set /a paths_found+=1
    )
)

REM Show only the paths that exist
if !paths_found! gtr 0 (
    echo Emplacements Adobe trouves :
    for %%P in ("%ADOBE_PATHS:;=" "%") do (
        if exist "%%~P" echo   - %%~P
    )
    echo.
    
    REM Now scan the found paths
    for %%P in ("%ADOBE_PATHS:;=" "%") do (
        if exist "%%~P" (
            echo Analyse du chemin de base : %%~P
            REM Start recursive search up to 5 levels
            call :search_adobe "%%~P" 1 "!action!"
        )
    )
) else (
    echo [ATTENTION] Adobe non trouve dans les emplacements standards
    echo     ^| Adobe n'est pas installe dans l'un des emplacements typiques
    echo     ^| Si vous avez installe Adobe ailleurs, deplacez-le vers l'un des chemins listes
    echo     ^| ci-dessus pour une detection automatique
    echo.
)

echo.
echo ==========================================================================
echo Resultat de %action%
echo ==========================================================================
echo.
echo [INFO] Applications trouvees : !app_count!
echo [INFO] Applications %result% : !result_count!
echo.
pause
endlocal & set "app_count=%app_count%" & set "result_count=%result_count%" & exit /b 0

:search_adobe
setlocal
set "path=%~1"
set /a "level=%~2"
set "action=%~3"

REM Verify depth limit (maximum 5 levels)
if %level% gtr 5 (
    endlocal
    exit /b 0
)

REM Search for .exe files in the current directory
for %%f in ("%path%\*.exe") do (
    set "file=%%f"
    set "app_name=%%~nxf"
    
    REM Exclude plugins and essential components
    set "exclude=0"
    ::if "!file:Plug-ins=!" neq "!file!" set "exclude=1"
    ::if "!file:PlugIns=!" neq "!file!" set "exclude=1"
    ::if "!file:Support Files=!" neq "!file!" set "exclude=1"
    if "!file:Presets=!" neq "!file!" set "exclude=1"
    if "!file:Goodies=!" neq "!file!" set "exclude=1"
    if "!file:Optional=!" neq "!file!" set "exclude=1"
    if "!file:node.exe=!" neq "!file!" set "exclude=1"
    
    if !exclude! equ 0 (
        REM Increment application found counter
        set /a "app_count+=1"
        
        REM Prepare name for the rule
        set "relative_path=!file:%ProgramFiles%=!"
        set "relative_path=!relative_path:%ProgramFiles(x86)%=!"
        set "relative_path=!relative_path:%ProgramData%=!"
        set "relative_path=!relative_path:\= - !"
        set "rule_name=Bloquer Adobe - !app_name!"
        
        echo.
        echo ==========================================================================
        echo Etape 1 - Verification si l'application est deja %verbPast%
        echo ==========================================================================
        echo.
        
        echo Execution de la commande:
        echo netsh advfirewall firewall show rule name="!rule_name!"
        echo.
        
        REM Check if the rule exists
        netsh advfirewall firewall show rule name="!rule_name!" >nul 2>&1
        set "rule_exists=!errorlevel!"

        if /i "!action!"=="block" (
            if !rule_exists! equ 0 (
                :: Show Blocked State
                echo [INFO] Verification terminee :
                echo     ^|
                echo     ^|- L'application !app_name! est deja bloquee
                echo     ^|- Impossible de dupliquer la regle
                echo.
            ) else (
                :: Execute Block
                echo [INFO] Verification terminee :
                echo     ^|
                echo     ^|- L'application !app_name! n'existe pas dans le firewall
                echo     ^|   %message_action%
                echo.
                
                echo ==========================================================================
                echo Etape 2 - Execution du blocage de l'application
                echo ==========================================================================
                echo.
                
                echo Execution de la commande:
                echo netsh advfirewall firewall add rule name="!rule_name!" dir=out action=block program="!file!"
                REM Block the application (outbound traffic only)
                netsh advfirewall firewall add rule name="!rule_name!" dir=out action=block program="!file!" >nul 2>&1
                
                if !errorlevel! equ 0 (
                    set /a "result_count+=1"
                    echo [SUCCES] Blocage effectue :
                    echo     ^|
                    echo     ^|- Application: !app_name!
                    echo     ^|- Chemin: !file!
                    echo     ^|- Nom de regle: "!rule_name!"
                ) else (
                    echo [ERREUR] Blocage echoue :
                    echo     ^|
                    echo     ^|- %message_error% !app_name!
                    echo     ^|- Verifiez les privileges administrateur
                )
            )
        ) else (  
            :: Unblock section          
            if !rule_exists! equ 0 (
                :: Execute unblock
                echo [INFO] Verification terminee :
                echo     ^|
                echo     ^|- L'application !app_name! est bloquee
                echo     ^|   %message_action%
                echo.
                
                echo ==========================================================================
                echo Etape 2 - Execution du debocage de l'application
                echo ==========================================================================
                echo.
                
                echo Execution de la commande:
                echo netsh advfirewall firewall delete rule name="!rule_name!"
                REM Unblock the application
                netsh advfirewall firewall delete rule name="!rule_name!" >nul 2>&1
                
                if !errorlevel! equ 0 (
                    set /a "result_count+=1"
                    echo [SUCCES] Deblocage effectue :
                    echo     ^|
                    echo     ^|- Application: !app_name!
                    echo     ^|- Chemin: !file!
                    echo     ^|- Nom de regle: "!rule_name!"
                ) else (
                    echo [ERREUR] Deblocage echoue :
                    echo     ^|
                    echo     ^|- %message_error% !app_name!
                    echo     ^|- Verifiez les privileges administrateur
                )
            ) else (
                :: Show unblocked state
                echo [INFO] Verification terminee :
                echo     ^|
                echo     ^|- L'application !app_name! n'est pas bloquee
                echo     ^|- Pas besoin de debloquer
                echo.
            )
        )
    )
)

REM Search subdirectories and continue recursive search
for /d %%s in ("%path%\*") do (
    call :search_adobe "%%s" %level%+1 "%action%"
)

endlocal & set "app_count=%app_count%" & set "result_count=%result_count%" & exit /b 0