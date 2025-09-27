@echo off
setlocal EnableDelayedExpansion

REM Variabili globali per mantenere la direzione corrente
set "DIRECTION=IN"
set "DIRECTION_LOWER=in"

REM Verifica se in esecuzione come amministratore
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [ERRORE] L'esecuzione di questo file richiede privilegi di amministratore.
    echo.
    echo Per eseguire come amministratore:
    echo     ^|
    echo     ^|- Clic destro sul file .bat
    echo     ^|- Selezionare "Run as administrator"
    echo     ^|
    echo     ^|- Oppure aprire CMD/Terminal come amministratore prima
    echo.
    pause
    exit /b 1
)

:select_initial_direction
cls
echo.
echo                                             GESTORE WINDOWS FIREWALL
echo                                     ----------------------------------------
echo.
echo ==========================================
echo           SELEZIONE DIREZIONE INIZIALE
echo ==========================================
echo.
echo [1] - Regole in ingresso (IN)
echo [2] - Regole in uscita (OUT)
echo.
set /p "dir_choice=Seleziona la direzione iniziale [1-2]: "

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
    echo [ERRORE] Opzione non valida. Puoi inserire solo 1 o 2.
    echo.
    pause
    goto select_initial_direction
)

:main_menu
cls
echo.
echo                                             GESTORE WINDOWS FIREWALL
echo                                     ----------------------------------------
echo.
echo ==========================================
echo             MENU PRINCIPALE
echo ==========================================
echo.
echo Direzione corrente: !DIRECTION!
echo.
echo      ---- GESTIONE IP ----
echo [1] - Bloccare IP
echo [2] - Sbloccare IP
echo [3] - Visualizza IP bloccati
echo.
echo      ---- GESTIONE PORTE ----
echo [4] - Bloccare / Chiudere / Negare Porta
echo [5] - Sbloccare / Aprire / Consentire Porta
echo [6] - Visualizza Porte Chiuse
echo.
echo      ---- GESTIONE ADOBE ----
echo [7] - Bloccare Applicazioni Adobe
echo [8] - Sbloccare Applicazioni Adobe
echo.
echo      ---- CONFIGURAZIONE ----
echo [9] - Cambia direzione ^(regole IN/OUT^)
echo [10] - Esci
echo.
set /p "option_menu=Inserisci la tua opzione [1-10]: "

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
echo [ERRORE] Opzione non valida. Puoi inserire solo valori da 1 a 10.
echo.
pause
goto main_menu

:change_direction
cls
echo ==========================================================================
echo                    CAMBIA DIREZIONE DELLE REGOLE
echo ==========================================================================
echo.
echo Direzione corrente: !DIRECTION!
echo.
echo [1] - Cambia a INGRESSO (IN)
echo [2] - Cambia a USCITA (OUT)
echo [3] - Torna al menu principale
echo.
set /p "new_dir=Seleziona nuova direzione [1-3]: "

if "!new_dir!"=="1" (
    if "!DIRECTION!"=="IN" (
        echo.
        echo [INFO] Gia in modalita INGRESSO ^(IN^)
        echo.
    ) else (
        set "DIRECTION=IN"
        set "DIRECTION_LOWER=in"
        echo.
        echo [INFO] Direzione cambiata in: INGRESSO ^(IN^)
        echo.
    )
    pause
    goto main_menu
) else if "!new_dir!"=="2" (
    if "!DIRECTION!"=="OUT" (
        echo.
        echo [INFO] Gia in modalita USCITA ^(OUT^)
        echo.
    ) else (
        set "DIRECTION=OUT"
        set "DIRECTION_LOWER=out"
        echo.
        echo [INFO] Direzione cambiata in: USCITA ^(OUT^)
        echo.
    )
    pause
    goto main_menu
) else if "!new_dir!"=="3" (
    goto main_menu
) else (
    echo.
    echo [ERRORE] Opzione non valida.
    echo.
    pause
    goto change_direction
)

:block_ip
cls
echo ==========================================================================
echo                       BLOCCARE IP NEL FIREWALL
echo ==========================================================================
echo Direzione corrente: !DIRECTION!
echo.

REM Richiedi IP da bloccare
set "targetIP="
set /p "targetIP=Inserisci l'IP da bloccare: "

if "!targetIP!"=="" (
    echo.
    echo [ERRORE] Devi inserire un IP valido.
    echo.
    pause
    goto main_menu
)

REM Valida IP usando funzione riutilizzabile
call :validate_ip "!targetIP!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

REM Richiedi il nome della regola (opzionale)
echo.
set "comment="
set /p "comment=Inserisci il nome della regola (opzionale): "

REM Valida il nome della regola se non vuoto
if not "!comment!"=="" (
    call :validate_name "!comment!"
    if !errorlevel! neq 0 (
        pause
        goto main_menu
    )
)

REM Crea il nome della regola nel formato originale (SENZA includere IN/OUT)
set "ruleName=Bloccare IP - !targetIP!"
if not "!comment!"=="" (
    set "ruleName=!ruleName! (!comment!)"
)

echo.
echo ==========================================================================
echo Passo 1 - Verifica se l'IP e gia bloccato
echo ==========================================================================
echo.

echo Esecuzione comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloccare IP - !targetIP!"
echo.

REM Controlla se l'IP e gia bloccato NELLA DIREZIONE SPECIFICA usando filtro dir=
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloccare IP - !targetIP!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERRORE] Verifica completata:
    echo     ^|
    echo     ^|- L'IP !targetIP! e gia bloccato
    echo     ^|- Impossibile duplicare la regola
    echo.
    pause
    goto main_menu
) else (
    echo [INFO] Verifica completata:
    echo     ^|
    echo     ^|- L'IP !targetIP! non e presente nel firewall
    echo     ^|- Procedo con il blocco
)

echo.
echo ==========================================================================
echo Passo 2 - Esecuzione blocco IP
echo ==========================================================================
echo.

echo Esecuzione comando:
echo netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block remoteip=!targetIP!
echo.

REM Esegui comando per bloccare l'IP NELLA DIREZIONE SPECIFICA
netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block remoteip=!targetIP! >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCESSO] Blocco completato:
    echo     ^|
    echo     ^|- IP: !targetIP! bloccato con successo
    echo     ^|- Direzione: !DIRECTION!
    echo     ^|- Nome: "!ruleName!"
) else (
    echo [ERRORE] Blocco fallito:
    echo     ^|
    echo     ^|- Impossibile bloccare l'IP !targetIP!
    echo     ^|- Verifica privilegi di amministratore
)

echo.
pause
goto main_menu

:unblock_ip
cls
echo ==========================================================================
echo                    SBLOCCARE IP NEL FIREWALL
echo ==========================================================================
echo Direzione corrente: !DIRECTION!
echo.

REM Richiedi IP da sbloccare
set "targetIP="
set /p "targetIP=Inserisci l'IP da sbloccare: "

if "!targetIP!"=="" (
    echo.
    echo [ERRORE] Devi inserire un IP valido.
    echo.
    pause
    goto main_menu
)

REM Valida IP usando funzione riutilizzabile
call :validate_ip "!targetIP!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Passo 1 - Ricerca della regola firewall per IP: !targetIP!
echo ==========================================================================
echo.

echo Esecuzione comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloccare IP - !targetIP!"
echo.

REM Verifica se esiste qualche regola con l'IP specifico NELLA DIREZIONE SPECIFICA
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloccare IP - !targetIP!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERRORE] Ricerca completata:
    echo     ^|
    echo     ^|- Nessuna regola trovata per l'IP !targetIP!
    echo     ^|- Verifica che l'IP sia bloccato
    echo.
    pause
    goto main_menu
)

REM Trova la regola esatta NELLA DIREZIONE SPECIFICA
set "lastRule="
for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloccare IP -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloccare IP - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloccare IP - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleIP=!ruleNameLine:Bloccare IP - =!"
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

echo [SUCCESSO] Ricerca completata:
echo     ^|
echo     ^|- IP: !targetIP!
echo     ^|- Direzione: !DIRECTION!
echo     ^|- Nome: "!lastRule!"
echo.

echo ==========================================================================
echo Passo 2 - Esecuzione eliminazione regola
echo ==========================================================================
echo.

echo Esecuzione comando:
echo netsh advfirewall firewall delete rule name="!lastRule!"
echo.

REM Esegui il comando per eliminare la regola
netsh advfirewall firewall delete rule name="!lastRule!" >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCESSO] Eliminazione completata:
    echo     ^|
    echo     ^|- Regola eliminata con successo
    echo     ^|- IP: !targetIP!
    echo     ^|- Direzione: !DIRECTION!
    echo     ^|- Nome: "!lastRule!"
) else (
    echo [ERRORE] Eliminazione fallita:
    echo     ^|
    echo     ^|- Impossibile eliminare la regola
    echo     ^|- IP: !targetIP!
    echo     ^|- Nome: "!lastRule!"
    echo     ^|- [INFO] Verifica privilegi di amministratore
    echo.
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Passo 3 - Verifica eliminazione regola
echo ==========================================================================
echo.

echo Esecuzione comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"!targetIP!"
echo.

REM Verifica eliminazione NELLA DIREZIONE SPECIFICA
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"!targetIP!" >nul 2>&1

if !errorlevel! neq 0 (
    echo [SUCCESSO] Verifica completata:
    echo     ^|
    echo     ^|- IP: !targetIP! rimosso con successo
    echo     ^|- Direzione: !DIRECTION!
    echo     ^|- Nome: "!lastRule!"
) else (
    echo [ATTENZIONE] Verifica completata:
    echo     ^|
    echo     ^|- Esistono ancora regole con l'IP !targetIP!
    echo     ^|- Potrebbero esserci regole duplicate
)

echo.
pause
goto main_menu

:view_blocked_ips
cls
echo ==========================================================================
echo                     IPS BLOCCATE NEL FIREWALL
echo ==========================================================================
echo Direzione corrente: !DIRECTION!
echo.

echo Esecuzione comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloccare IP"
echo.

REM Controlla se ci sono regole NELLA DIREZIONE SPECIFICA
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloccare IP -" >nul 2>&1

if !errorlevel! neq 0 (
    echo [INFO] Verifica completata:
    echo     ^|
    echo     ^|- Al momento non ci sono IP bloccati
    echo.
    pause
    goto main_menu
)

echo ==========================================================================
echo                        ELENCO DI IP BLOCCATE
echo ==========================================================================
echo.

set "counter=0"

for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloccare IP -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloccare IP - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloccare IP - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleIP=!ruleNameLine:Bloccare IP - =!"
        for /f "tokens=1 delims= " %%c in ("!ruleIP!") do set "onlyIP=%%c"
        echo !onlyIP! | findstr /C:"(" >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "tokens=1 delims=(" %%d in ("!onlyIP!") do set "onlyIP=%%d"
        )
        set /a "counter+=1"
        echo [!counter!] Regola trovata:
        echo     ^|
        echo     ^|- IP: !onlyIP!
        echo     ^|- Direzione: !DIRECTION!
        echo     ^|- Nome: "!ruleNameLine!"
        echo.
    )
)

pause
goto main_menu

:block_port
cls
echo ==========================================================================
echo                       BLOCCARE PORTA NEL FIREWALL
echo ==========================================================================
echo Direzione corrente: !DIRECTION!
echo.

set "port="
set /p "port=Inserisci la porta da bloccare: "

REM Valida porta usando funzione riutilizzabile
call :validate_port port
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "protocol="
set /p "protocol=Inserisci il protocollo [TCP/UDP] (default TCP): "

if "!protocol!"=="" set "protocol=TCP"

REM Valida protocollo usando funzione riutilizzabile
call :validate_protocol "!protocol!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "comment="
set /p "comment=Inserisci il nome della regola (opzionale): "

REM Valida il nome della regola se non vuoto
if not "!comment!"=="" (
    call :validate_name "!comment!"
    if !errorlevel! neq 0 (
        pause
        goto main_menu
    )
)

set "ruleName=Bloccare Porta - !port! (!protocol!)"
if not "!comment!"=="" (
    set "ruleName=!ruleName! - !comment!"
)

echo.
echo ==========================================================================
echo Passo 1 - Verifica se la porta e gia bloccata
echo ==========================================================================
echo.

echo Esecuzione comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloccare Porta - !port!" | findstr /C:"!protocol!"
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloccare Porta - !port!" | findstr /C:"!protocol!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERRORE] Verifica completata:
    echo     ^|
    echo     ^|- La porta !port! ^(!protocol!^) e gia bloccata
    echo     ^|- Impossibile duplicare la regola
    echo.
    pause
    goto main_menu
) else (
    echo [INFO] Verifica completata:
    echo     ^|
    echo     ^|- La porta !port! ^(!protocol!^) non esiste nel firewall
    echo     ^|- Procedo con il blocco
)

echo.
echo ==========================================================================
echo Passo 2 - Esecuzione blocco porta
echo ==========================================================================
echo.

echo Esecuzione comando:
echo netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block protocol=!protocol! localport=!port!
echo.

netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block protocol=!protocol! localport=!port! >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCESSO] Blocco completato:
    echo     ^|
    echo     ^|- Porta: !port! bloccata con successo
    echo     ^|- Protocollo: !protocol!
    echo     ^|- Direzione: !DIRECTION!
    echo     ^|- Nome: "!ruleName!"
) else (
    echo [ERRORE] Blocco fallito:
    echo     ^|
    echo     ^|- Impossibile bloccare la porta !port!
    echo     ^|- Verifica privilegi di amministratore
)

echo.
pause
goto main_menu

:unblock_port
cls
echo ==========================================================================
echo                    SBLOCCARE PORTA NEL FIREWALL
echo ==========================================================================
echo Direzione corrente: !DIRECTION!
echo.

set "port="
set /p "port=Inserisci la porta da sbloccare: "

REM Valida porta usando funzione riutilizzabile
call :validate_port port
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "protocol="
set /p "protocol=Inserisci il protocollo [TCP/UDP] (default TCP): "

if "!protocol!"=="" set "protocol=TCP"

REM Valida protocollo usando funzione riutilizzabile
call :validate_protocol "!protocol!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Passo 1 - Ricerca della regola firewall per la porta: !port! (!protocol!)
echo ==========================================================================
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloccare Porta - !port!" | findstr /C:"!protocol!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERRORE] Ricerca completata:
    echo     ^|
    echo     ^|- Nessuna regola trovata per la porta !port! "(!protocol!)"
    echo     ^|- Verifica che la porta sia bloccata
    echo.
    pause
    goto main_menu
)

REM Trova la regola esatta della porta
set "lastRule="
for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloccare Porta -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloccare Porta - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloccare Porta - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        echo !ruleNameLine! | findstr /C:"!port!" | findstr /C:"!protocol!" >nul 2>&1
        if !errorlevel! equ 0 (
            set "lastRule=!ruleNameLine!"
        )
    )
)

echo [SUCCESSO] Ricerca completata:
echo     ^|
echo     ^|- Porta: !port!
echo     ^|- Protocollo: !protocol!
echo     ^|- Direzione: !DIRECTION!
echo     ^|- Nome: "!lastRule!"
echo.

echo ==========================================================================
echo Passo 2 - Esecuzione eliminazione regola
echo ==========================================================================
echo.

echo Esecuzione comando:
echo netsh advfirewall firewall delete rule name="!lastRule!"
echo.

netsh advfirewall firewall delete rule name="!lastRule!" >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCESSO] Eliminazione completata:
    echo     ^|
    echo     ^|- Regola eliminata con successo
    echo     ^|- Porta: !port!
    echo     ^|- Protocollo: !protocol!
    echo     ^|- Direzione: !DIRECTION!
    echo     ^|- Nome: "!lastRule!"
) else (
    echo [ERRORE] Eliminazione fallita:
    echo     ^|
    echo     ^|- Impossibile eliminare la regola
    echo     ^|- Porta: !port!
    echo     ^|- Nome: "!lastRule!"
)

echo.
pause
goto main_menu

:view_blocked_ports
setlocal
cls
echo ==========================================================================
echo                     PORTE BLOCCATE NEL FIREWALL
echo ==========================================================================
echo Direzione corrente: !DIRECTION!
echo.

echo Esecuzione comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloccare Porta"
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloccare Porta -" >nul 2>&1
if !errorlevel! neq 0 (
    echo [INFO] Verifica completata:
    echo     ^|
    echo     ^|- Al momento non ci sono porte bloccate
    echo.
    endlocal
    pause
    goto main_menu
)

echo ==========================================================================
echo                        ELENCO DELLE PORTE BLOCCATE
echo ==========================================================================
echo.

set "counter=0"

for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloccare Porta -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloccare Porta - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloccare Porta - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleData=!ruleNameLine:Bloccare Porta - =!"
        for /f "tokens=1,2 delims= " %%c in ("!ruleData!") do (
            set "port=%%c"
            set "protocolPart=%%d"
        )
        REM Estrai protocollo tra parentesi
        if defined protocolPart (
            set "protocol=!protocolPart:^(=!"
            set "protocol=!protocol:^)=!"
        )
        set /a "counter+=1"
        echo [!counter!] Regola trovata:
        echo     ^|
        echo     ^|- Porta: !port!
        echo     ^|- Protocollo: !protocol!
        echo     ^|- Direzione: !DIRECTION!
        echo     ^|- Nome: "!ruleNameLine!"
        echo.
    )
)
endlocal
pause
goto main_menu



REM =============================================================================
REM                       FUNZIONI RIUTILIZZABILI DI VALIDAZIONE (Porta, IP)
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
    echo [ERRORE] Porta vuota. Devi inserire una porta valida.
    echo.
    endlocal & exit /b 1
)

REM normalize
set "port_norm=!port: =!"

REM Validate general format (digits, commas and hyphens only)
call :check_port_format "!port_norm!"
if !errorlevel! neq 0 (
    echo.
    echo [ERRORE] Formato porta non valido.
    echo     ^|
    echo     ^|- Solo numeri, virgole e trattini sono permessi
    echo     ^|- Esempi validi:
    echo     ^|
    echo     ^|   - 5001 ^(porta singola^)
    echo     ^|
    echo     ^|   - 5000-5001 ^(range^)
    echo     ^|   - 5000 - 5001 ^(range^)
    echo     ^|
    echo     ^|   - 80,443,5000 ^(lista^)
    echo     ^|   - 80, 443, 5000 ^(lista^)
    echo     ^|
    echo     ^|   - 80,443,5000-5001 ^(misto^)
    echo     ^|   - 80, 443, 5000-5001 ^(misto^)
    echo     ^|   - 80, 443, 5000 - 5001 ^(misto^)
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
                    echo [ERRORE] Range non valido: !start! ^> !end!
                    echo     ^|
                    echo     ^|- La porta iniziale deve essere minore o uguale alla finale
                    echo     ^|- Esempio valido:
                    echo     ^|   - 5000-5001 ^(range^)
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
    echo [ERRORE] Zero iniziale non valido: "!port!"
    echo     ^| Esempio non valido: 05000
    echo     ^| Esempio valido: 5000
    echo.
    endlocal & exit /b 1
)


REM Validate range (1-65535)
set /a num=0 + !port! 2>nul
if !num! lss 1 (
    echo.
    echo [ERRORE] Porta non valida: !port!
    echo     ^|
    echo     ^|- Deve essere tra 1 e 65535
    echo     ^|- Esempi validi:
    echo     ^|   - 5001 ^(porta singola^)
    echo     ^|   - 5000-5001 ^(range^)
    echo     ^|   - 80,443,5000 ^(lista^)
    echo     ^|   - 80,443,5000-5001 ^(misto^)
    echo.
    endlocal & exit /b 1
)
if !num! gtr 65535 (
    echo.
    echo [ERRORE] Porta non valida: !port!
    echo     ^|
    echo     ^|- Deve essere tra 1 e 65535
    echo     ^|- Esempi validi:
    echo     ^|   - 5001 ^(porta singola^)
    echo     ^|   - 5000-5001 ^(range^)
    echo     ^|   - 80,443,5000 ^(lista^)
    echo     ^|   - 80,443,5000-5001 ^(misto^)
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
    echo [ERRORE] IP vuoto. Devi inserire un IP valido.
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
    echo [ERRORE] Formato IP non valido.
    echo     ^|
    echo     ^|- Non sono permessi i porti ^(es: 192.168.1.1:443^)
    echo     ^|- Esempi validi:
    echo     ^|   - 192.168.1.1    ^(IP singolo^)
    echo     ^|   - 192.168.1.0/24 ^(range CIDR^)
    echo.
    endlocal & exit /b 1
)

REM Validate ip_base basic format (4 octets)
( <nul set /p="!ip_base!" | findstr /R /C:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" ) >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [ERRORE] Formato IP non valido.
    echo     ^|
    echo     ^|- Solo numeri e punti sono permessi
    echo     ^|- Esempi validi:
    echo     ^|   - 192.168.1.1    ^(IP singolo^)
    echo     ^|   - 192.168.1.0/24 ^(range CIDR^)
    echo.
    endlocal & exit /b 1
)

REM Validate CIDR mask (if present)
if "!is_cidr!"=="true" (
    if "!cidr_mask!"=="" (
        echo.
        echo [ERRORE] Maschera CIDR vuota. Formato richiesto: IP/MASK
        echo.
        endlocal & exit /b 1
    )   

    REM Validate mask is numeric
    for /f "delims=0123456789" %%x in ("!cidr_mask!") do (
        echo.
        echo [ERRORE] Maschera CIDR non valida: "!cidr_mask!"
        echo     ^|
        echo     ^|- Solo numeri sono permessi ^(0-32^)
        echo.
        endlocal & exit /b 1
    )

    REM Validate leading zero in CIDR mask
    if not "!cidr_mask!"=="0" if "!cidr_mask:~0,1!"=="0" (
        echo.
        echo [ERRORE] Zero iniziale non valido nella maschera CIDR ^(CIDR^): "!cidr_mask!"
        echo     ^| Esempio non valido: /024
        echo     ^| Esempio valido: /24
        echo.
        endlocal & exit /b 1
    )
    
    REM Validate mask range (0-32)
    set /a num_mask=0 + !cidr_mask! 2>nul
    if !num_mask! lss 0 (
        echo.
        echo [ERRORE] Maschera CIDR fuori intervallo: !cidr_mask!
        echo     ^|
        echo     ^|- L'intervallo deve essere tra ^(0 e 32^)
        echo.
        endlocal & exit /b 1
    )

    if !num_mask! gtr 32 (
        echo.
        echo [ERRORE] Maschera CIDR fuori intervallo: !cidr_mask!
        echo     ^|
        echo     ^|- L'intervallo deve essere tra ^(0 e 32^)
        echo.
        endlocal & exit /b 1
    )
)

REM Continua con la validazione dell'IP estraendo i 4 octet
for /f "tokens=1-4 delims=." %%a in ("!ip_base!") do (
    set "o1=%%a"
    set "o2=%%b"
    set "o3=%%c"
    set "o4=%%d"
)

REM Valida ogni octet
set "pos=0"
for %%o in (o1 o2 o3 o4) do (
    set /a pos+=1
    call set "value=%%%%o%%%%"
    
    REM Leading zeros (except "0")
    if not "!value!"=="0" if "!value:~0,1!"=="0" (
        echo.
        echo [ERRORE] Zero iniziale non valido nell'octet !pos!: "!value!"
        echo     ^| Esempio non valido: 192.080.1.1
        echo     ^| Esempio valido: 192.80.1.1
        echo.
        endlocal
        exit /b 1
    )
    
    REM Range 0-255
    set /a num=0 + !value! 2>nul
    if !num! gtr 255 (
        echo.
        echo [ERRORE] Octet !pos!: "!value!" ^> 255
        echo     ^| Intervallo permesso: 0-255
        echo.
        endlocal
        exit /b 1
    )
    if !num! lss 0 (
        echo.
        echo [ERRORE] Octet !pos!: "!value!" ^< 0
        echo     ^| Intervallo permesso: 0-255
        echo.
        endlocal
        exit /b 1
    )
)

:: se siamo arrivati qui, la validazione IP e stata completata con successo
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
echo [ERRORE] Protocollo non valido.
echo     ^|
echo     ^|- Sono permessi solo: TCP o UDP
echo     ^|- Esempi validi: TCP, tcp, UDP, udp
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
    echo [ERRORE] Nome regola troppo lungo.
    echo     ^|
    echo     ^|- Lunghezza massima: 255 caratteri
    echo.
    endlocal & exit /b 1
)

REM Validate dangerous characters
( <nul set /p="!name!" | findstr /R /C:"[^A-Za-z0-9 _-]" ) >nul 2>&1 && (
    echo.
    echo [ERRORE] Il nome della regola contiene caratteri pericolosi.
    echo     ^|
    echo     ^|- Non sono permessi: ^& ^| ^" ^< ^> ^^ %% !!
    echo     ^|- Usa solo lettere, numeri e spazi
    echo.
    endlocal & exit /b 1
)

REM Validate dangerous reserved words (with trailing space)
for %%W in ("format " "del " "remove " "erase " "rd " "rmdir " "delete " "echo " "cmd " "powershell ") do (
    ( <nul set /p=" !name! " | findstr /I /C:%%~W ) >nul 2>&1 && (
        echo.
        echo [ERRORE] Il nome della regola contiene parole riservate.
        echo     ^|
        echo     ^|- Non sono consentiti comandi di sistema
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
REM percorsi centralizzati di Adobe
REM -----------------------------
set "ADOBE_PATHS=%ProgramFiles%\Adobe;%ProgramFiles(x86)%\Adobe;%CommonProgramFiles%\Adobe;%CommonProgramFiles(x86)%\Adobe;%ProgramData%\Adobe"

REM Determina messaggio e operazione
if /i "%action%"=="block" (
    set "operation=Bloccare"
    set "verbPast=Bloccata"
    set "result=Bloccate"
    set "message_action=Procedo con il blocco"
    set "message_success=Applicazione bloccata"
    set "message_error=Impossibile bloccare l'applicazione"
) else (
    set "operation=Sbloccare"
    set "verbPast=Sbloccata"
    set "result=Sbloccate"
    set "message_action=Procedo con lo sblocco"
    set "message_success=Applicazione sbloccata"
    set "message_error=Impossibile sbloccare l'applicazione"
)

cls
echo ==========================================================================
echo                 %operation% APPLICAZIONI ADOBE NEL FIREWALL
echo ==========================================================================
echo Direzione corrente: !DIRECTION!
echo.
echo NOTA: Questo processo limitera l'accesso a internet di TUTTI gli eseguibili (.exe)
echo       trovati per Adobe, per evitare l'utilizzo della banda.
echo.

REM Mostra i percorsi da scansionare (una sola volta)
echo Ricerca nelle seguenti posizioni di Adobe:
for %%P in ("%ADOBE_PATHS:;=" "%") do (
    echo   - %%~P
)
echo.

REM Scansiona ogni directory base e conta quelle esistenti
for %%P in ("%ADOBE_PATHS:;=" "%") do (
    if exist "%%~P" (
        set /a paths_found+=1
    )
)

REM Mostra solo i percorsi esistenti
if !paths_found! gtr 0 (
    echo Posizioni Adobe trovate:
    for %%P in ("%ADOBE_PATHS:;=" "%") do (
        if exist "%%~P" echo   - %%~P
    )
    echo.
    
    REM Ora scansiona i percorsi trovati
    for %%P in ("%ADOBE_PATHS:;=" "%") do (
        if exist "%%~P" (
            echo Scansione percorso base: %%~P
            REM Avvia ricerca ricorsiva fino a 5 livelli
            call :search_adobe "%%~P" 1 "!action!"
        )
    )
) else (
    echo [ATTENZIONE] Adobe non trovato nelle posizioni standard
    echo     ^| Adobe non e installato in nessuna delle posizioni tipiche
    echo     ^| Se hai installato Adobe in un'altra posizione, spostalo in uno dei percorsi elencati sopra
    echo     ^| per essere rilevato automaticamente
    echo.
)

echo.
echo ==========================================================================
echo Risultato di %action%
echo ==========================================================================
echo.
echo [INFO] Applicazioni trovate: !app_count!
echo [INFO] Applicazioni %result%: !result_count!
echo.
pause
endlocal & set "app_count=%app_count%" & set "result_count=%result_count%" & exit /b 0

:search_adobe
setlocal
set "path=%~1"
set /a "level=%~2"
set "action=%~3"

REM Verifica limite di profondita (max 5 livelli)
if %level% gtr 5 (
    endlocal
    exit /b 0
)

REM Cerca file .exe nella directory corrente
for %%f in ("%path%\*.exe") do (
    set "file=%%f"
    set "app_name=%%~nxf"
    
    REM Escludi plugin e componenti essenziali
    set "exclude=0"
    ::if "!file:Plug-ins=!" neq "!file!" set "exclude=1"
    ::if "!file:PlugIns=!" neq "!file!" set "exclude=1"
    ::if "!file:Support Files=!" neq "!file!" set "exclude=1"
    if "!file:Presets=!" neq "!file!" set "exclude=1"
    if "!file:Goodies=!" neq "!file!" set "exclude=1"
    if "!file:Optional=!" neq "!file!" set "exclude=1"
    if "!file:node.exe=!" neq "!file!" set "exclude=1"
    
    if !exclude! equ 0 (
        REM Incrementa contatore applicazioni trovate
        set /a "app_count+=1"
        
        REM Prepara nome per la regola
        set "relative_path=!file:%ProgramFiles%=!"
        set "relative_path=!relative_path:%ProgramFiles(x86)%=!"
        set "relative_path=!relative_path:%ProgramData%=!"
        set "relative_path=!relative_path:\= - !"
        set "rule_name=Bloccare Adobe - !app_name!"
        
        echo.
        echo ==========================================================================
        echo Passo 1 - Verifica se l'applicazione e gia %verbPast%
        echo ==========================================================================
        echo.
        
        echo Esecuzione comando:
        echo netsh advfirewall firewall show rule name="!rule_name!"
        echo.
        
        REM Verifica se la regola esiste
        netsh advfirewall firewall show rule name="!rule_name!" >nul 2>&1
        set "rule_exists=!errorlevel!"

        if /i "!action!"=="block" (
            if !rule_exists! equ 0 (
                :: Mostra stato bloccata
                echo [INFO] Verifica completata:
                echo     ^|
                echo     ^|- L'applicazione !app_name! e gia bloccata
                echo     ^|- Impossibile duplicare la regola
                echo.
            ) else (
                :: Esegui blocco
                echo [INFO] Verifica completata:
                echo     ^|
                echo     ^|- L'applicazione !app_name! non esiste nel firewall
                echo     ^|   %message_action%
                echo.
                
                echo ==========================================================================
                echo Passo 2 - Esecuzione blocco applicazione
                echo ==========================================================================
                echo.
                
                echo Esecuzione comando:
                echo netsh advfirewall firewall add rule name="!rule_name!" dir=out action=block program="!file!"
                REM Blocca l'applicazione (solo traffico in uscita)
                netsh advfirewall firewall add rule name="!rule_name!" dir=out action=block program="!file!" >nul 2>&1
                
                if !errorlevel! equ 0 (
                    set /a "result_count+=1"
                    echo [SUCCESSO] Blocco completato:
                    echo     ^|
                    echo     ^|- Applicazione: !app_name!
                    echo     ^|- Percorso: !file!
                    echo     ^|- Nome regola: "!rule_name!"
                ) else (
                    echo [ERRORE] Blocco fallito:
                    echo     ^|
                    echo     ^|- %message_error% !app_name!
                    echo     ^|- Verifica privilegi di amministratore
                )
            )
        ) else (  
            :: Sezione sblocco          
            if !rule_exists! equ 0 (
                :: Esegui sblocco
                echo [INFO] Verifica completata:
                echo     ^|
                echo     ^|- L'applicazione !app_name! e bloccata
                echo     ^|   %message_action%
                echo.
                
                echo ==========================================================================
                echo Passo 2 - Esecuzione sblocco applicazione
                echo ==========================================================================
                echo.
                
                echo Esecuzione comando:
                echo netsh advfirewall firewall delete rule name="!rule_name!"
                REM Sblocca l'applicazione
                netsh advfirewall firewall delete rule name="!rule_name!" >nul 2>&1
                
                if !errorlevel! equ 0 (
                    set /a "result_count+=1"
                    echo [SUCCESSO] Sblocco completato:
                    echo     ^|
                    echo     ^|- Applicazione: !app_name!
                    echo     ^|- Percorso: !file!
                    echo     ^|- Nome regola: "!rule_name!"
                ) else (
                    echo [ERRORE] Sblocco fallito:
                    echo     ^|
                    echo     ^|- %message_error% !app_name!
                    echo     ^|- Verifica privilegi di amministratore
                )
            ) else (
                :: Mostra stato non bloccata
                echo [INFO] Verifica completata:
                echo     ^|
                echo     ^|- L'applicazione !app_name! non e bloccata
                echo     ^|- Nessuna necessita di sblocco
                echo.
            )
        )
    )
)

REM Cerca sottodirectory e continua la ricerca ricorsiva
for /d %%s in ("%path%\*") do (
    call :search_adobe "%%s" %level%+1 "%action%"
)

endlocal & set "app_count=%app_count%" & set "result_count=%result_count%" & exit /b 0