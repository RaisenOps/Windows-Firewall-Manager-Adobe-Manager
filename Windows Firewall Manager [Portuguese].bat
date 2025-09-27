@echo off
setlocal EnableDelayedExpansion

REM Variaveis globais para manter a direcao atual
set "DIRECTION=IN"
set "DIRECTION_LOWER=in"

REM Verifica se esta sendo executado como administrador
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [ERRO] A execucao deste arquivo requer privilegios de administrador.
    echo.
    echo Para executar como administrador:
    echo     ^|
    echo     ^|- Clique com o botao direito no arquivo .bat
    echo     ^|- Selecione "Run as administrator"
    echo     ^|
    echo     ^|- Ou abra CMD/Terminal como administrador primeiro
    echo.
    pause
    exit /b 1
)

:select_initial_direction
cls
echo.
echo                                             GERENCIADOR DO FIREWALL DO WINDOWS
echo                                     ----------------------------------------
echo.
echo ==========================================
echo           SELECAO INICIAL DE DIRECAO
echo ==========================================
echo.
echo [1] - Regras de ENTRADA (IN)
echo [2] - Regras de SAIDA (OUT)
echo.
set /p "dir_choice=Selecione a direcao inicial [1-2]: "

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
    echo [ERRO] Opcao invalida. So e permitido 1 ou 2.
    echo.
    pause
    goto select_initial_direction
)

:main_menu
cls
echo.
echo                                             GERENCIADOR DO FIREWALL DO WINDOWS
echo                                     ----------------------------------------
echo.
echo ==========================================
echo             MENU PRINCIPAL
echo ==========================================
echo.
echo Direcao atual: !DIRECTION!
echo.
echo      ---- GESTAO DE IPS ----
echo [1] - Bloquear IP
echo [2] - Desbloquear IP
echo [3] - Ver IPs bloqueadas
echo.
echo      ---- GESTAO DE PORTAS ----
echo [4] - Bloquear / Fechar / Negar Porta
echo [5] - Desbloquear / Abrir / Permitir Porta
echo [6] - Ver Portas bloqueadas
echo.
echo      ---- GESTAO ADOBE ----
echo [7] - Bloquear aplicacoes Adobe
echo [8] - Desbloquear aplicacoes Adobe
echo.
echo      ---- CONFIGURACAO ----
echo [9] - Mudar direcao ^(regras IN/OUT^)
echo [10] - Sair
echo.
set /p "option_menu=Digite a sua opcao [1-10]: "

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
echo [ERRO] Opcao invalida. So e permitido valores de 1 a 10.
echo.
pause
goto main_menu

:change_direction
cls
echo ==========================================================================
echo                    MUDAR DIRECAO DAS REGRAS
echo ==========================================================================
echo.
echo Direcao atual: !DIRECTION!
echo.
echo [1] - Mudar para ENTRADA (IN)
echo [2] - Mudar para SAIDA (OUT)
echo [3] - Voltar ao menu principal
echo.
set /p "new_dir=Selecione nova direcao [1-3]: "

if "!new_dir!"=="1" (
    if "!DIRECTION!"=="IN" (
        echo.
        echo [INFO] Ja esta em ENTRADA ^(IN^)
        echo.
    ) else (
        set "DIRECTION=IN"
        set "DIRECTION_LOWER=in"
        echo.
        echo [INFO] Direcao alterada para: ENTRADA ^(IN^)
        echo.
    )
    pause
    goto main_menu
) else if "!new_dir!"=="2" (
    if "!DIRECTION!"=="OUT" (
        echo.
        echo [INFO] Ja esta em SAIDA ^(OUT^)
        echo.
    ) else (
        set "DIRECTION=OUT"
        set "DIRECTION_LOWER=out"
        echo.
        echo [INFO] Direcao alterada para: SAIDA ^(OUT^)
        echo.
    )
    pause
    goto main_menu
) else if "!new_dir!"=="3" (
    goto main_menu
) else (
    echo.
    echo [ERRO] Opcao invalida.
    echo.
    pause
    goto change_direction
)

:block_ip
cls
echo ==========================================================================
echo                       BLOQUEAR IP NO FIREWALL
echo ==========================================================================
echo Direcao atual: !DIRECTION!
echo.

REM Perguntar IP para bloquear
set "targetIP="
set /p "targetIP=Digite a IP para bloquear: "

if "!targetIP!"=="" (
    echo.
    echo [ERRO] Deve digitar uma IP valida.
    echo.
    pause
    goto main_menu
)

REM Validar IP usando funcao reutilizavel
call :validate_ip "!targetIP!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

REM Perguntar nome da regra (opcional)
echo.
set "comment="
set /p "comment=Digite o nome da regra (opcional): "

REM Validar nome da regra se nao estiver vazio
if not "!comment!"=="" (
    call :validate_name "!comment!"
    if !errorlevel! neq 0 (
        pause
        goto main_menu
    )
)

REM Criar o nome da regra (SEM incluir IN/OUT)
set "ruleName=Bloquear IP - !targetIP!"
if not "!comment!"=="" (
    set "ruleName=!ruleName! (!comment!)"
)

echo.
echo ==========================================================================
echo Passo 1 - Verificando se a IP ja esta bloqueada
echo ==========================================================================
echo.

echo Executando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloquear IP - !targetIP!"
echo.

REM Verificar se a IP ja esta bloqueada NA DIRECAO ESPECIFICA usando filtro dir=
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquear IP - !targetIP!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERRO] Verificacao concluida:
    echo     ^|
    echo     ^|- A IP !targetIP! ja esta bloqueada
    echo     ^|- Nao e possivel duplicar a regra
    echo.
    pause
    goto main_menu
) else (
    echo [INFO] Verificacao concluida:
    echo     ^|
    echo     ^|- A IP !targetIP! nao existe no firewall
    echo     ^|- Procedendo com o bloqueio
)

echo.
echo ==========================================================================
echo Passo 2 - Executando bloqueio de IP
echo ==========================================================================
echo.

echo Executando comando:
echo netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block remoteip=!targetIP!
echo.

REM Executar comando para bloquear a IP NA DIRECAO ESPECIFICA
netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block remoteip=!targetIP! >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCESSO] Bloqueio concluido:
    echo     ^|
    echo     ^|- IP: !targetIP! bloqueada com sucesso
    echo     ^|- Direcao: !DIRECTION!
    echo     ^|- Nome: "!ruleName!"
) else (
    echo [ERRO] Bloqueio falhou:
    echo     ^|
    echo     ^|- Nao foi possivel bloquear a IP !targetIP!
    echo     ^|- Verifique privilegios de administrador
)

echo.
pause
goto main_menu

:unblock_ip
cls
echo ==========================================================================
echo                    DESBLOQUEAR IP NO FIREWALL
echo ==========================================================================
echo Direcao atual: !DIRECTION!
echo.

REM Perguntar IP para desbloquear
set "targetIP="
set /p "targetIP=Digite a IP para desbloquear: "

if "!targetIP!"=="" (
    echo.
    echo [ERRO] Deve digitar uma IP valida.
    echo.
    pause
    goto main_menu
)

REM Validar IP usando funcao reutilizavel
call :validate_ip "!targetIP!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Passo 1 - Procurando regra de firewall para IP: !targetIP!
echo ==========================================================================
echo.

echo Executando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloquear IP - !targetIP!"
echo.

REM Verificar se existe alguma regra com a IP especifica NA DIRECAO ESPECIFICA
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquear IP - !targetIP!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERRO] Pesquisa concluida:
    echo     ^|
    echo     ^|- Nao foram encontradas regras para a IP !targetIP!
    echo     ^|- Verifique que a IP esteja bloqueada
    echo.
    pause
    goto main_menu
)

REM Encontrar a regra exacta NA DIRECAO ESPECIFICA
set "lastRule="
for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloquear IP -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloquear IP - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloquear IP - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleIP=!ruleNameLine:Bloquear IP - =!"
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

echo [SUCESSO] Pesquisa concluida:
echo     ^|
echo     ^|- IP: !targetIP!
echo     ^|- Direcao: !DIRECTION!
echo     ^|- Nome: "!lastRule!"
echo.

echo ==========================================================================
echo Passo 2 - Executando exclusao da regra
echo ==========================================================================
echo.

echo Executando comando:
echo netsh advfirewall firewall delete rule name="!lastRule!"
echo.

REM Executar comando para eliminar a regra
netsh advfirewall firewall delete rule name="!lastRule!" >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCESSO] Eliminacao concluida:
    echo     ^|
    echo     ^|- Regra eliminada com sucesso
    echo     ^|- IP: !targetIP!
    echo     ^|- Direcao: !DIRECTION!
    echo     ^|- Nome: "!lastRule!"
) else (
    echo [ERRO] Eliminacao falhou:
    echo     ^|
    echo     ^|- Nao foi possivel eliminar a regra
    echo     ^|- IP: !targetIP!
    echo     ^|- Nome: "!lastRule!"
    echo     ^|- [INFO] Verifique privilegios de administrador
    echo.
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Passo 3 - Verificando eliminacao da regra
echo ==========================================================================
echo.

echo Executando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"!targetIP!"
echo.

REM Verificar eliminacao NA DIRECAO ESPECIFICA
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"!targetIP!" >nul 2>&1

if !errorlevel! neq 0 (
    echo [SUCESSO] Verificacao concluida:
    echo     ^|
    echo     ^|- IP: !targetIP! removida com sucesso
    echo     ^|- Direcao: !DIRECTION!
    echo     ^|- Nome: "!lastRule!"
) else (
    echo [AVISO] Verificacao concluida:
    echo     ^|
    echo     ^|- Ainda existem regras com a IP !targetIP!
    echo     ^|- Possiveis duplicadas
)

echo.
pause
goto main_menu

:view_blocked_ips
cls
echo ==========================================================================
echo                     IPS BLOQUEADAS NO FIREWALL
echo ==========================================================================
echo Direcao atual: !DIRECTION!
echo.

echo Executando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloquear IP"
echo.

REM Verificar se ha regras NA DIRECAO ESPECIFICA
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquear IP -" >nul 2>&1

if !errorlevel! neq 0 (
    echo [INFO] Verificacao concluida:
    echo     ^|
    echo     ^|- Nao ha IPs bloqueadas atualmente
    echo.
    pause
    goto main_menu
)

echo ==========================================================================
echo                        LISTA DE IPS BLOQUEADAS
echo ==========================================================================
echo.

set "counter=0"

for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloquear IP -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloquear IP - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloquear IP - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleIP=!ruleNameLine:Bloquear IP - =!"
        for /f "tokens=1 delims= " %%c in ("!ruleIP!") do set "onlyIP=%%c"
        echo !onlyIP! | findstr /C:"(" >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "tokens=1 delims=(" %%d in ("!onlyIP!") do set "onlyIP=%%d"
        )
        set /a "counter+=1"
        echo [!counter!] Regra encontrada:
        echo     ^|
        echo     ^|- IP: !onlyIP!
        echo     ^|- Direcao: !DIRECTION!
        echo     ^|- Nome: "!ruleNameLine!"
        echo.
    )
)

pause
goto main_menu

:block_port
cls
echo ==========================================================================
echo                       BLOQUEAR PORTA NO FIREWALL
echo ==========================================================================
echo Direcao atual: !DIRECTION!
echo.

set "port="
set /p "port=Digite a porta para bloquear: "

REM Validar porta usando funcao reutilizavel
call :validate_port port
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "protocol="
set /p "protocol=Digite o protocolo [TCP/UDP] (padrao TCP): "

if "!protocol!"=="" set "protocol=TCP"

REM Validar protocolo usando funcao reutilizavel
call :validate_protocol "!protocol!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "comment="
set /p "comment=Digite o nome da regra (opcional): "

REM Validar nome de regra se nao estiver vazio
if not "!comment!"=="" (
    call :validate_name "!comment!"
    if !errorlevel! neq 0 (
        pause
        goto main_menu
    )
)

set "ruleName=Bloquear Porta - !port! (!protocol!)"
if not "!comment!"=="" (
    set "ruleName=!ruleName! - !comment!"
)

echo.
echo ==========================================================================
echo Passo 1 - Verificando se a porta ja esta bloqueada
echo ==========================================================================
echo.

echo Executando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloquear Porta - !port!" | findstr /C:"!protocol!"
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquear Porta - !port!" | findstr /C:"!protocol!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERRO] Verificacao concluida:
    echo     ^|
    echo     ^|- A porta !port! ^(!protocol!^) ja esta bloqueada
    echo     ^|- Nao e possivel duplicar a regra
    echo.
    pause
    goto main_menu
) else (
    echo [INFO] Verificacao concluida:
    echo     ^|
    echo     ^|- A porta !port! ^(!protocol!^) nao existe no firewall
    echo     ^|- Procedendo com o bloqueio
)

echo.
echo ==========================================================================
echo Passo 2 - Executando bloqueio de porta
echo ==========================================================================
echo.

echo Executando comando:
echo netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block protocol=!protocol! localport=!port!
echo.

netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block protocol=!protocol! localport=!port! >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCESSO] Bloqueio concluido:
    echo     ^|
    echo     ^|- Porta: !port! bloqueada com sucesso
    echo     ^|- Protocolo: !protocol!
    echo     ^|- Direcao: !DIRECTION!
    echo     ^|- Nome: "!ruleName!"
) else (
    echo [ERRO] Bloqueio falhou:
    echo     ^|
    echo     ^|- Nao foi possivel bloquear a porta !port!
    echo     ^|- Verifique privilegios de administrador
)

echo.
pause
goto main_menu

:unblock_port
cls
echo ==========================================================================
echo                    DESBLOQUEAR PORTA NO FIREWALL
echo ==========================================================================
echo Direcao atual: !DIRECTION!
echo.

set "port="
set /p "port=Digite a porta para desbloquear: "

REM Validar porta usando funcao reutilizavel
call :validate_port port
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "protocol="
set /p "protocol=Digite o protocolo [TCP/UDP] (padrao TCP): "

if "!protocol!"=="" set "protocol=TCP"

REM Validar protocolo usando funcao reutilizavel
call :validate_protocol "!protocol!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Passo 1 - Procurando regra de firewall para porta: !port! (!protocol!)
echo ==========================================================================
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquear Porta - !port!" | findstr /C:"!protocol!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERRO] Pesquisa concluida:
    echo     ^|
    echo     ^|- Nao foram encontradas regras para a porta !port! "(!protocol!)"
    echo     ^|- Verifique que a porta esteja bloqueada
    echo.
    pause
    goto main_menu
)

REM Encontrar a regra exacta da porta
set "lastRule="
for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloquear Porta -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloquear Porta - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloquear Porta - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        echo !ruleNameLine! | findstr /C:"!port!" | findstr /C:"!protocol!" >nul 2>&1
        if !errorlevel! equ 0 (
            set "lastRule=!ruleNameLine!"
        )
    )
)

echo [SUCESSO] Pesquisa concluida:
echo     ^|
echo     ^|- Porta: !port!
echo     ^|- Protocolo: !protocol!
echo     ^|- Direcao: !DIRECTION!
echo     ^|- Nome: "!lastRule!"
echo.

echo ==========================================================================
echo Passo 2 - Executando exclusao da regra
echo ==========================================================================
echo.

echo Executando comando:
echo netsh advfirewall firewall delete rule name="!lastRule!"
echo.

netsh advfirewall firewall delete rule name="!lastRule!" >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCESSO] Eliminacao concluida:
    echo     ^|
    echo     ^|- Regra eliminada com sucesso
    echo     ^|- Porta: !port!
    echo     ^|- Protocolo: !protocol!
    echo     ^|- Direcao: !DIRECTION!
    echo     ^|- Nome: "!lastRule!"
) else (
    echo [ERRO] Eliminacao falhou:
    echo     ^|
    echo     ^|- Nao foi possivel eliminar a regra
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
echo                     PORTAS BLOQUEADAS NO FIREWALL
echo ==========================================================================
echo Direcao atual: !DIRECTION!
echo.

echo Executando comando:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Bloquear Porta"
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Bloquear Porta -" >nul 2>&1
if !errorlevel! neq 0 (
    echo [INFO] Verificacao concluida:
    echo     ^|
    echo     ^|- Nao ha portas bloqueadas atualmente
    echo.
    endlocal
    pause
    goto main_menu
)

echo ==========================================================================
echo                        LISTA DE PORTAS BLOQUEADAS
echo ==========================================================================
echo.

set "counter=0"

for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Bloquear Porta -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Bloquear Porta - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Bloquear Porta - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleData=!ruleNameLine:Bloquear Porta - =!"
        for /f "tokens=1,2 delims= " %%c in ("!ruleData!") do (
            set "port=%%c"
            set "protocolPart=%%d"
        )
        REM Extrair protocolo entre parenteses
        if defined protocolPart (
            set "protocol=!protocolPart:^(=!"
            set "protocol=!protocol:^)=!"
        )
        set /a "counter+=1"
        echo [!counter!] Regra encontrada:
        echo     ^|
        echo     ^|- Porta: !port!
        echo     ^|- Protocolo: !protocol!
        echo     ^|- Direcao: !DIRECTION!
        echo     ^|- Nome: "!ruleNameLine!"
        echo.
    )
)
endlocal
pause
goto main_menu



REM =============================================================================
REM                       FUNCOES REUTILIZAVEIS DE VALIDACAO (Port, IP)
REM =============================================================================

::------------------------------------------------------------------------------
:: Funcao: validate_port
:: Propósito: Validar e normalizar uma porta ou lista de portas
:: Parametros:
::   %~1 - Nome da variavel que contem a porta
:: Retorno:
::   0 - Sucesso (porta valida, variavel atualizada)
::   1 - Erro (formato invalido)
::------------------------------------------------------------------------------
:validate_port
setlocal
call set "port=%%%~1%%"

REM Validar que nao esteja vazio
if "!port!"=="" (
    echo.
    echo [ERRO] Porta vazia. Deve digitar uma porta valida.
    echo.
    endlocal & exit /b 1
)

REM normalizar
set "port_norm=!port: =!"

REM Validar formato geral (so digitos, virgulas e hifens)
call :check_port_format "!port_norm!"
if !errorlevel! neq 0 (
    echo.
    echo [ERRO] Formato de porta invalido.
    echo     ^|
    echo     ^|- So sao permitidos numeros, virgulas e hifens
    echo     ^|- Exemplos validos:
    echo     ^|
    echo     ^|   - 5001 ^(porta individual^)
    echo     ^|
    echo     ^|   - 5000-5001 ^(intervalo^)
    echo     ^|   - 5000 - 5001 ^(intervalo^)
    echo     ^|
    echo     ^|   - 80,443,5000 ^(lista^)
    echo     ^|   - 80, 443, 5000 ^(lista^)
    echo     ^|
    echo     ^|   - 80,443,5000-5001 ^(mistura^)
    echo     ^|   - 80, 443, 5000-5001 ^(mistura^)
    echo     ^|   - 80, 443, 5000 - 5001 ^(mistura^)
    echo.
    endlocal & exit /b 1
)

REM Processar cada componente
set "port_list=!port_norm:,= !"

for %%p in (!port_list!) do (
    if not "%%p"=="" (
        REM Verificar se e um intervalo
        ( <nul set /p="%%p" | findstr /C:"-" ) >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "tokens=1,2 delims=-" %%a in ("%%p") do (
                set "start=%%a"
                set "end=%%b"
                
                REM Validar intervalo
                call :validate_individual_port "!start!" || exit /b 1
                call :validate_individual_port "!end!" || exit /b 1
                
                set /a num_start=0 + !start! 2>nul
                set /a num_end=0 + !end! 2>nul
                if !num_start! gtr !num_end! (
                    echo.
                    echo [ERRO] Intervalo invalido: !start! ^> !end!
                    echo     ^|
                    echo     ^|- A porta inicial deve ser menor ou igual que a final
                    echo     ^|- Exemplo valido:
                    echo     ^|   - 5000-5001 ^(intervalo^)
                    echo.
                    endlocal & exit /b 1
                )
            )
        ) else (
            REM Validar porta individual
            call :validate_individual_port "%%p" || exit /b 1
        )
    )
)

REM Finalizar funcao e ATUALIZAR A VARIAVEL ORIGINAL POR REFERENCIA
endlocal & set "%%~1=!port_norm!" & exit /b 0



::------------------------------------------------------------------------------
:: Funcao: check_port_format
:: Propósito: Verificar que o formato da porta e valido (digitos, virgulas, hifens)
:: Parametros:
::   %~1 - Porta a validar (sem espacos)
:: Retorno:
::   0 - Sucesso (formato valido)
::   1 - Erro (formato invalido)
::------------------------------------------------------------------------------
:check_port_format
setlocal
set "port_norm=%~1"

REM Verificar padroes invalidos
if "!port_norm:--=!" neq "!port_norm!" endlocal & exit /b 1      REM Erro se hifens duplicados (ex: 5000--5001)
if "!port_norm:,,=!" neq "!port_norm!" endlocal & exit /b 1      REM Erro se virgulas duplicadas (ex: 80,,443)
if "!port_norm:~-1!"=="," endlocal & exit /b 1                     REM Erro se termina com virgula (ex: 80,)
if "!port_norm:~-1!"=="-" endlocal & exit /b 1                     REM Erro se termina com hifen (ex: 5000-)

REM Verificar que contenha apenas digitos, virgulas e hifens
( <nul set /p="!port_norm!" | findstr /R /C:"^[0-9][0-9,\-]*$" ) >nul 2>&1
if !errorlevel! neq 0 (
    endlocal & exit /b 1
)
endlocal & exit /b 0




::------------------------------------------------------------------------------
:: Funcao: validate_individual_port
:: Propósito: Validar uma porta individual (1-65535) e verificar zeros a esquerda
:: Parametros:
::   %~1 - Porta a validar
:: Retorno:
::   0 - Sucesso (valido)
::   1 - Erro (invalido)
::------------------------------------------------------------------------------
:validate_individual_port
setlocal
set "port=%~1"

REM Verificar zeros a esquerda
if "!port:~0,1!"=="0" if not "!port!"=="0" (
    echo.
    echo [ERRO] Leading zero invalido: "!port!"
    echo     ^| Exemplo invalido: 05000
    echo     ^| Exemplo valido: 5000
    echo.
    endlocal & exit /b 1
)


REM Validar intervalo (1-65535)
set /a num=0 + !port! 2>nul
if !num! lss 1 (
    echo.
    echo [ERRO] Porta invalida: !port!
    echo     ^|
    echo     ^|- Deve estar entre 1 e 65535
    echo     ^|- Exemplos validos:
    echo     ^|   - 5001 ^(porta individual^)
    echo     ^|   - 5000-5001 ^(intervalo^)
    echo     ^|   - 80,443,5000 ^(lista^)
    echo     ^|   - 80,443,5000-5001 ^(mistura^)
    echo.
    endlocal & exit /b 1
)
if !num! gtr 65535 (
    echo.
    echo [ERRO] Porta invalida: !port!
    echo     ^|
    echo     ^|- Deve estar entre 1 e 65535
    echo     ^|- Exemplos validos:
    echo     ^|   - 5001 ^(porta individual^)
    echo     ^|   - 5000-5001 ^(intervalo^)
    echo     ^|   - 80,443,5000 ^(lista^)
    echo     ^|   - 80,443,5000-5001 ^(mistura^)
    echo.
    endlocal & exit /b 1
)
:: Fim validacao porta individual
endlocal & exit /b 0




::------------------------------------------------------------------------------
:: Funcao: validate_ip
:: Propósito: Validar um endereco IPv4 ou CIDR
:: Parametros:
::   %~1 - IP a validar
:: Retorno:
::   0 - Sucesso (IP valido)
::   1 - Erro (IP invalido)
::------------------------------------------------------------------------------
:validate_ip
setlocal
set "ip=%~1"

REM Validar que nao esteja vazio
if "!ip!"=="" (
    echo.
    echo [ERRO] IP vazio. Deve digitar um IP valido.
    echo.
    endlocal & exit /b 1
)


REM Detectar se e CIDR e extrair componentes
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

REM Validar que nao contenha portas (detectar ":")
<nul set /p="!ip!" | findstr /C:":" >nul 2>&1
if !errorlevel! equ 0 (
    echo.
    echo [ERRO] Formato de IP invalido.
    echo     ^|
    echo     ^|- Nao sao permitidas portas ^(exemplo: 192.168.1.1:443^)
    echo     ^|- Exemplos validos:
    echo     ^|   - 192.168.1.1    ^(IP individual^)
    echo     ^|   - 192.168.1.0/24 ^(intervalo CIDR^)
    echo.
    endlocal & exit /b 1
)

REM Validar formato basico ip_base (4 octetos)
( <nul set /p="!ip_base!" | findstr /R /C:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" ) >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [ERRO] Formato de IP invalido.
    echo     ^|
    echo     ^|- Apenas numeros e pontos sao permitidos
    echo     ^|- Exemplos validos:
    echo     ^|   - 192.168.1.1    ^(IP individual^)
    echo     ^|   - 192.168.1.0/24 ^(intervalo CIDR^)
    echo.
    endlocal & exit /b 1
)

REM Validar mascara CIDR (se existir)
if "!is_cidr!"=="true" (
    if "!cidr_mask!"=="" (
        echo.
        echo [ERRO] Mascara CIDR vazia. Formato requerido: IP/MASK
        echo.
        endlocal & exit /b 1
    )   

    REM Validar que a mascara seja numerica
    for /f "delims=0123456789" %%x in ("!cidr_mask!") do (
        echo.
        echo [ERRO] Mascara CIDR invalida: "!cidr_mask!"
        echo     ^|
        echo     ^|- Apenas numeros sao permitidos ^(0-32^)
        echo.
        endlocal & exit /b 1
    )

    REM Validar leading zero na mascara CIDR
    if not "!cidr_mask!"=="0" if "!cidr_mask:~0,1!"=="0" (
        echo.
        echo [ERRO] Leading zero invalido na mascara CIDR ^(intervalo CIDR^): "!cidr_mask!"
        echo     ^| Exemplo invalido: /024
        echo     ^| Exemplo valido: /24
        echo.
        endlocal & exit /b 1
    )
    
    REM Validar intervalo da mascara (0-32)
    set /a num_mask=0 + !cidr_mask! 2>nul
    if !num_mask! lss 0 (
        echo.
        echo [ERRO] Mascara CIDR fora do intervalo: !cidr_mask!
        echo     ^|
        echo     ^|- O intervalo deve estar entre ^(0 e 32^)
        echo.
        endlocal & exit /b 1
    )

    if !num_mask! gtr 32 (
        echo.
        echo [ERRO] Mascara CIDR fora do intervalo: !cidr_mask!
        echo     ^|
        echo     ^|- O intervalo deve estar entre ^(0 e 32^)
        echo.
        endlocal & exit /b 1
    )
)

REM Continuar validando extraindo os 4 octetos
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
    call set "value=%%%%o%%%%"
    
    REM Leading zeros (exceto "0")
    if not "!value!"=="0" if "!value:~0,1!"=="0" (
        echo.
        echo [ERRO] Leading zero invalido no octeto !pos!: "!value!"
        echo     ^| Exemplo invalido: 192.080.1.1
        echo     ^| Exemplo valido: 192.80.1.1
        echo.
        endlocal
        exit /b 1
    )
    
    REM Intervalo 0-255
    set /a num=0 + !value! 2>nul
    if !num! gtr 255 (
        echo.
        echo [ERRO] Octeto !pos!: "!value!" ^> 255
        echo     ^| Intervalo permitido: 0-255
        echo.
        endlocal
        exit /b 1
    )
    if !num! lss 0 (
        echo.
        echo [ERRO] Octeto !pos!: "!value!" ^< 0
        echo     ^| Intervalo permitido: 0-255
        echo.
        endlocal
        exit /b 1
    )
)

:: Se chegamos aqui, validacao de IP teve sucesso
endlocal & exit /b 0




::------------------------------------------------------------------------------
:: Funcao: validate_protocol
:: Propósito: Validar se o protocolo e TCP ou UDP (case-insensitive)
:: Parametros:
::   %~1 - Protocolo a validar
:: Retorno:
::   0 - Sucesso (valido)
::   1 - Erro (invalido)
::------------------------------------------------------------------------------
:validate_protocol
setlocal
set "protocol=%~1"

REM Converter para maiusculas para comparacao
for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") do (
    call set "protocol=%%protocol:%%~A%%"
)

REM Validar exatamente TCP ou UDP
if /i "!protocol!"=="TCP" endlocal & exit /b 0
if /i "!protocol!"=="UDP" endlocal & exit /b 0


echo.
echo [ERRO] Protocolo invalido.
echo     ^|
echo     ^|- Apenas permitido: TCP ou UDP
echo     ^|- Exemplos validos: TCP, tcp, UDP, udp
echo.
endlocal & exit /b 1



::------------------------------------------------------------------------------
:: Funcao: validate_name
:: Propósito: Validar o nome de uma regra de firewall
:: Parametros:
::   %~1 - Nome a validar
:: Retorno:
::   0 - Sucesso (valido)
::   1 - Erro (invalido)
::------------------------------------------------------------------------------
:validate_name
setlocal
set "name=%~1"

REM Se vazio, e valido (opcional)
if "%name%"=="" endlocal & exit /b 0

REM Calcular comprimento do nome, saindo rapidamente ao terminar
set "name_len=0"
REM for /l %%i in (0,1,255) do if "!name:~%%i,1!" neq "" set /a name_len+=1
for /l %%i in (0,1,255) do (
  if "!name:~%%i,1!"=="" goto validate_name_fin_len
  set /a name_len+=1
)

:validate_name_fin_len
:: Validar que o nome nao ultrapasse 255 caracteres
if !name_len! gtr 255 (
    echo.
    echo [ERRO] Nome da regra muito longo.
    echo     ^|
    echo     ^|- Comprimento maximo: 255 caracteres
    echo.
    endlocal & exit /b 1
)

REM Validar caracteres perigosos
( <nul set /p="!name!" | findstr /R /C:"[^A-Za-z0-9 _-]" ) >nul 2>&1 && (
    echo.
    echo [ERRO] Nome da regra contem caracteres perigosos.
    echo     ^|
    echo     ^|- Nao sao permitidos: ^& ^| ^" ^< ^> ^^ %% !!
    echo     ^|- Use apenas letras, numeros e espacos
    echo.
    endlocal & exit /b 1
)

REM Validar palavras reservadas perigosas (com espaco ao final)
for %%W in ("format " "del " "remove " "erase " "rd " "rmdir " "delete " "echo " "cmd " "powershell ") do (
    ( <nul set /p=" !name! " | findstr /I /C:%%~W ) >nul 2>&1 && (
        echo.
        echo [ERRO] Nome da regra contem palavras reservadas.
        echo     ^|
        echo     ^|- Comandos do sistema nao sao permitidos
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
REM caminhos centralizados da Adobe
REM -----------------------------
set "ADOBE_PATHS=%ProgramFiles%\Adobe;%ProgramFiles(x86)%\Adobe;%CommonProgramFiles%\Adobe;%CommonProgramFiles(x86)%\Adobe;%ProgramData%\Adobe"

REM Determinar mensagem e operacao
if /i "%action%"=="block" (
    set "operation=Bloquear"
    set "verbPast=Bloqueada"
    set "result=Bloqueadas"
    set "message_action=Procedendo com o bloqueio"
    set "message_success=Aplicacao bloqueada"
    set "message_error=Nao foi possivel bloquear a aplicacao"
) else (
    set "operation=Desbloquear"
    set "verbPast=Desbloqueada"
    set "result=Desbloqueadas"
    set "message_action=Procedendo com o desbloqueio"
    set "message_success=Aplicacao desbloqueada"
    set "message_error=Nao foi possivel desbloquear a aplicacao"
)

cls
echo ==========================================================================
echo                 %operation% APLICACOES ADOBE NO FIREWALL
echo ==========================================================================
echo Direcao atual: !DIRECTION!
echo.
echo NOTA: Este processo %action% o acesso a internet para TODOS os executaveis (.exe) encontrados
echo       da Adobe, para evitar consumo de largura de banda.
echo.

REM Mostrar caminhos a escanear (apenas uma vez)
echo Procurando nas seguintes localizacoes da Adobe:
for %%P in ("%ADOBE_PATHS:;=" "%") do (
    echo   - %%~P
)
echo.

REM Escanear cada diretorio base e contar os que existem
for %%P in ("%ADOBE_PATHS:;=" "%") do (
    if exist "%%~P" (
        set /a paths_found+=1
    )
)

REM Mostrar apenas os caminhos que existem
if !paths_found! gtr 0 (
    echo Localizacoes Adobe encontradas:
    for %%P in ("%ADOBE_PATHS:;=" "%") do (
        if exist "%%~P" echo   - %%~P
    )
    echo.
    
    REM Agora escanear os caminhos encontrados
    for %%P in ("%ADOBE_PATHS:;=" "%") do (
        if exist "%%~P" (
            echo Escaneando caminho base: %%~P
            REM Iniciar busca recursiva ate 5 niveis
            call :search_adobe "%%~P" 1 "!action!"
        )
    )
) else (
    echo [AVISO] Adobe nao encontrado nas localizacoes padrao
    echo     ^| Adobe nao esta instalado em nenhuma das localizacoes tipicas
    echo     ^| Se instalou Adobe noutro lugar, mova para um dos caminhos listados acima
    echo     ^| para deteccao automatica
    echo.
)

echo.
echo ==========================================================================
echo Resultado de %action%
echo ==========================================================================
echo.
echo [INFO] Aplicacoes encontradas: !app_count!
echo [INFO] Aplicacoes %result%: !result_count!
echo.
pause
endlocal & set "app_count=%app_count%" & set "result_count=%result_count%" & exit /b 0

:search_adobe
setlocal
set "path=%~1"
set /a "level=%~2"
set "action=%~3"

REM Verificar limite de profundidade (maximo 5 niveis)
if %level% gtr 5 (
    endlocal
    exit /b 0
)

REM Procurar arquivos .exe no diretorio atual
for %%f in ("%path%\*.exe") do (
    set "file=%%f"
    set "app_name=%%~nxf"
    
    REM Excluir plugins e componentes essenciais
    set "exclude=0"
    ::if "!file:Plug-ins=!" neq "!file!" set "exclude=1"
    ::if "!file:PlugIns=!" neq "!file!" set "exclude=1"
    ::if "!file:Support Files=!" neq "!file!" set "exclude=1"
    if "!file:Presets=!" neq "!file!" set "exclude=1"
    if "!file:Goodies=!" neq "!file!" set "exclude=1"
    if "!file:Optional=!" neq "!file!" set "exclude=1"
    if "!file:node.exe=!" neq "!file!" set "exclude=1"
    
    if !exclude! equ 0 (
        REM Incrementar contador de aplicacoes encontradas
        set /a "app_count+=1"
        
        REM Preparar nome para a regra
        set "relative_path=!file:%ProgramFiles%=!"
        set "relative_path=!relative_path:%ProgramFiles(x86)%=!"
        set "relative_path=!relative_path:%ProgramData%=!"
        set "relative_path=!relative_path:\= - !"
        set "rule_name=Bloquear Adobe - !app_name!"
        
        echo.
        echo ==========================================================================
        echo Passo 1 - Verificando se a aplicacao ja esta %verbPast%
        echo ==========================================================================
        echo.
        
        echo Executando comando:
        echo netsh advfirewall firewall show rule name="!rule_name!"
        echo.
        
        REM Verificar se a regra existe
        netsh advfirewall firewall show rule name="!rule_name!" >nul 2>&1
        set "rule_exists=!errorlevel!"

        if /i "!action!"=="block" (
            if !rule_exists! equ 0 (
                :: Mostrar estado bloqueada
                echo [INFO] Verificacao concluida:
                echo     ^|
                echo     ^|- Aplicacao !app_name! ja esta bloqueada
                echo     ^|- Nao e possivel duplicar a regra
                echo.
            ) else (
                :: Executar bloqueio
                echo [INFO] Verificacao concluida:
                echo     ^|
                echo     ^|- Aplicacao !app_name! nao existe no firewall
                echo     ^|   %message_action%
                echo.
                
                echo ==========================================================================
                echo Passo 2 - Executando Bloqueio da aplicacao
                echo ==========================================================================
                echo.
                
                echo Executando comando:
                echo netsh advfirewall firewall add rule name="!rule_name!" dir=out action=block program="!file!"
                REM Bloquear a aplicacao (apenas trafego de saida)
                netsh advfirewall firewall add rule name="!rule_name!" dir=out action=block program="!file!" >nul 2>&1
                
                if !errorlevel! equ 0 (
                    set /a "result_count+=1"
                    echo [SUCESSO] Bloqueio concluido:
                    echo     ^|
                    echo     ^|- Aplicacao: !app_name!
                    echo     ^|- Caminho: !file!
                    echo     ^|- Nome da regra: "!rule_name!"
                ) else (
                    echo [ERRO] Bloqueio falhou:
                    echo     ^|
                    echo     ^|- %message_error% !app_name!
                    echo     ^|- Verifique privilegios de administrador
                )
            )
        ) else (  
            :: Secao Desbloquear          
            if !rule_exists! equ 0 (
                :: Executar desbloqueio
                echo [INFO] Verificacao concluida:
                echo     ^|
                echo     ^|- Aplicacao !app_name! esta bloqueada
                echo     ^|   %message_action%
                echo.
                
                echo ==========================================================================
                echo Passo 2 - Executando Desbloqueio da aplicacao
                echo ==========================================================================
                echo.
                
                echo Executando comando:
                echo netsh advfirewall firewall delete rule name="!rule_name!"
                REM Desbloquear a aplicacao
                netsh advfirewall firewall delete rule name="!rule_name!" >nul 2>&1
                
                if !errorlevel! equ 0 (
                    set /a "result_count+=1"
                    echo [SUCESSO] Desbloqueio concluido:
                    echo     ^|
                    echo     ^|- Aplicacao: !app_name!
                    echo     ^|- Caminho: !file!
                    echo     ^|- Nome da regra: "!rule_name!"
                ) else (
                    echo [ERRO] Desbloqueio falhou:
                    echo     ^|
                    echo     ^|- %message_error% !app_name!
                    echo     ^|- Verifique privilegios de administrador
                )
            ) else (
                :: Mostrar estado desbloqueada
                echo [INFO] Verificacao concluida:
                echo     ^|
                echo     ^|- Aplicacao !app_name! nao esta bloqueada
                echo     ^|- Nao ha necessidade de desbloquear
                echo.
            )
        )
    )
)

REM Procurar subdiretorios e continuar busca recursiva
for /d %%s in ("%path%\*") do (
    call :search_adobe "%%s" %level%+1 "%action%"
)

endlocal & set "app_count=%app_count%" & set "result_count=%result_count%" & exit /b 0