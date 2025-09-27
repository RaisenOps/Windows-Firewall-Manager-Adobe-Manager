@echo off
setlocal EnableDelayedExpansion

REM Global variables to keep current direction
set "DIRECTION=IN"
set "DIRECTION_LOWER=in"

REM Check if running as administrator
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Running this file requires administrator privileges.
    echo.
    echo To run as administrator:
    echo     ^|
    echo     ^|- Right-click the .bat file
    echo     ^|- Select "Run as administrator"
    echo     ^|
    echo     ^|- Or open CMD/Terminal as administrator first
    echo.
    pause
    exit /b 1
)

:select_initial_direction
cls
echo.
echo                                             WINDOWS FIREWALL MANAGER
echo                                     ----------------------------------------
echo.
echo ==========================================
echo           INITIAL DIRECTION SELECTION
echo ==========================================
echo.
echo [1] - Inbound rules (IN)
echo [2] - Outbound rules (OUT)
echo.
set /p "dir_choice=Select the initial direction [1-2]: "

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
    echo [ERROR] Invalid option. You can only enter 1 or 2.
    echo.
    pause
    goto select_initial_direction
)

:main_menu
cls
echo.
echo                                             WINDOWS FIREWALL MANAGER
echo                                     ----------------------------------------
echo.
echo ==========================================
echo             MAIN MENU
echo ==========================================
echo.
echo Current direction: !DIRECTION!
echo.
echo      ---- IP MANAGEMENT ----
echo [1] - Block IP
echo [2] - Unblock IP
echo [3] - View blocked IPs
echo.
echo      ---- PORT MANAGEMENT ----
echo [4] - Block / Close / Deny Port
echo [5] - Unblock / Open / Allow Port
echo [6] - View Closed Ports
echo.
echo      ---- ADOBE MANAGEMENT ----
echo [7] - Block Adobe Applications
echo [8] - Unblock Adobe Applications
echo.
echo      ---- CONFIGURATION ----
echo [9] - Change direction ^(rules IN/OUT^)
echo [10] - Exit
echo.
set /p "option_menu=Enter your option [1-10]: "

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
echo [ERROR] Invalid option. You can only enter values from 1 to 10.
echo.
pause
goto main_menu

:change_direction
cls
echo ==========================================================================
echo                    CHANGE RULE DIRECTION
echo ==========================================================================
echo.
echo Current direction: !DIRECTION!
echo.
echo [1] - Change to INBOUND (IN)
echo [2] - Change to OUTBOUND (OUT)
echo [3] - Return to main menu
echo.
set /p "new_dir=Select new direction [1-3]: "

if "!new_dir!"=="1" (
    if "!DIRECTION!"=="IN" (
        echo.
        echo [INFO] Already set to INBOUND ^(IN^)
        echo.
    ) else (
        set "DIRECTION=IN"
        set "DIRECTION_LOWER=in"
        echo.
        echo [INFO] Direction changed to: INBOUND ^(IN^)
        echo.
    )
    pause
    goto main_menu
) else if "!new_dir!"=="2" (
    if "!DIRECTION!"=="OUT" (
        echo.
        echo [INFO] Already set to OUTBOUND ^(OUT^)
        echo.
    ) else (
        set "DIRECTION=OUT"
        set "DIRECTION_LOWER=out"
        echo.
        echo [INFO] Direction changed to: OUTBOUND ^(OUT^)
        echo.
    )
    pause
    goto main_menu
) else if "!new_dir!"=="3" (
    goto main_menu
) else (
    echo.
    echo [ERROR] Invalid option.
    echo.
    pause
    goto change_direction
)

:block_ip
cls
echo ==========================================================================
echo                       BLOCK IP IN FIREWALL
echo ==========================================================================
echo Current direction: !DIRECTION!
echo.

REM Ask for IP to block
set "targetIP="
set /p "targetIP=Enter the IP to block: "

if "!targetIP!"=="" (
    echo.
    echo [ERROR] You must enter a valid IP.
    echo.
    pause
    goto main_menu
)

REM Validate IP using reusable function
call :validate_ip "!targetIP!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

REM Ask for rule name (optional)
echo.
set "comment="
set /p "comment=Enter the rule name (optional): "

REM Validate rule name if not empty
if not "!comment!"=="" (
    call :validate_name "!comment!"
    if !errorlevel! neq 0 (
        pause
        goto main_menu
    )
)

REM Create the rule name in original format (WITHOUT including IN/OUT)
set "ruleName=Block IP - !targetIP!"
if not "!comment!"=="" (
    set "ruleName=!ruleName! (!comment!)"
)

echo.
echo ==========================================================================
echo Step 1 - Checking if IP is already blocked
echo ==========================================================================
echo.

echo Executing command:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Block IP - !targetIP!"
echo.

REM Check if the IP is already blocked IN THE SPECIFIC DIRECTION using dir= filter
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Block IP - !targetIP!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERROR] Check completed:
    echo     ^|
    echo     ^|- The IP !targetIP! is already blocked
    echo     ^|- Cannot duplicate the rule
    echo.
    pause
    goto main_menu
) else (
    echo [INFO] Check completed:
    echo     ^|
    echo     ^|- The IP !targetIP! is not present in the firewall
    echo     ^|- Proceeding with blocking
)

echo.
echo ==========================================================================
echo Step 2 - Executing IP block
echo ==========================================================================
echo.

echo Executing command:
echo netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block remoteip=!targetIP!
echo.

REM Execute command to block the IP IN THE SPECIFIC DIRECTION
netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block remoteip=!targetIP! >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCESS] Block completed:
    echo     ^|
    echo     ^|- IP: !targetIP! blocked successfully
    echo     ^|- Direction: !DIRECTION!
    echo     ^|- Name: "!ruleName!"
) else (
    echo [ERROR] Block failed:
    echo     ^|
    echo     ^|- Could not block IP !targetIP!
    echo     ^|- Check administrator privileges
)

echo.
pause
goto main_menu

:unblock_ip
cls
echo ==========================================================================
echo                    UNBLOCK IP IN FIREWALL
echo ==========================================================================
echo Current direction: !DIRECTION!
echo.

REM Ask for IP to unblock
set "targetIP="
set /p "targetIP=Enter the IP to unblock: "

if "!targetIP!"=="" (
    echo.
    echo [ERROR] You must enter a valid IP.
    echo.
    pause
    goto main_menu
)

REM Validate IP using reusable function
call :validate_ip "!targetIP!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Step 1 - Searching for firewall rule for IP: !targetIP!
echo ==========================================================================
echo.

echo Executing command:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Block IP - !targetIP!"
echo.

REM Verify if there is any rule with the specific IP IN THE SPECIFIC DIRECTION
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Block IP - !targetIP!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] Search completed:
    echo     ^|
    echo     ^|- No rules were found for IP !targetIP!
    echo     ^|- Verify that the IP is blocked
    echo.
    pause
    goto main_menu
)

REM Find the exact rule IN THE SPECIFIC DIRECTION
set "lastRule="
for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Block IP -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Block IP - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Block IP - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleIP=!ruleNameLine:Block IP - =!"
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

echo [SUCCESS] Search completed:
echo     ^|
echo     ^|- IP: !targetIP!
echo     ^|- Direction: !DIRECTION!
echo     ^|- Name: "!lastRule!"
echo.

echo ==========================================================================
echo Step 2 - Executing rule deletion
echo ==========================================================================
echo.

echo Executing command:
echo netsh advfirewall firewall delete rule name="!lastRule!"
echo.

REM Execute command to delete the rule
netsh advfirewall firewall delete rule name="!lastRule!" >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCESS] Deletion completed:
    echo     ^|
    echo     ^|- Rule deleted successfully
    echo     ^|- IP: !targetIP!
    echo     ^|- Direction: !DIRECTION!
    echo     ^|- Name: "!lastRule!"
) else (
    echo [ERROR] Deletion failed:
    echo     ^|
    echo     ^|- Could not delete the rule
    echo     ^|- IP: !targetIP!
    echo     ^|- Name: "!lastRule!"
    echo     ^|- [INFO] Check administrator privileges
    echo.
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Step 3 - Verifying rule deletion
echo ==========================================================================
echo.

echo Executing command:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"!targetIP!"
echo.

REM Verify deletion IN THE SPECIFIC DIRECTION
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"!targetIP!" >nul 2>&1

if !errorlevel! neq 0 (
    echo [SUCCESS] Verification completed:
    echo     ^|
    echo     ^|- IP: !targetIP! removed successfully
    echo     ^|- Direction: !DIRECTION!
    echo     ^|- Name: "!lastRule!"
) else (
    echo [WARNING] Verification completed:
    echo     ^|
    echo     ^|- Rules with IP !targetIP! still exist
    echo     ^|- There may be duplicate rules
)

echo.
pause
goto main_menu

:view_blocked_ips
cls
echo ==========================================================================
echo                     BLOCKED IPs IN FIREWALL
echo ==========================================================================
echo Current direction: !DIRECTION!
echo.

echo Executing command:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Block IP"
echo.

REM Check if there are rules IN THE SPECIFIC DIRECTION
netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Block IP -" >nul 2>&1

if !errorlevel! neq 0 (
    echo [INFO] Check completed:
    echo     ^|
    echo     ^|- There are no blocked IPs currently
    echo.
    pause
    goto main_menu
)

echo ==========================================================================
echo                        LIST OF BLOCKED IPs
echo ==========================================================================
echo.

set "counter=0"

for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Block IP -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Block IP - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Block IP - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleIP=!ruleNameLine:Block IP - =!"
        for /f "tokens=1 delims= " %%c in ("!ruleIP!") do set "onlyIP=%%c"
        echo !onlyIP! | findstr /C:"(" >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "tokens=1 delims=(" %%d in ("!onlyIP!") do set "onlyIP=%%d"
        )
        set /a "counter+=1"
        echo [!counter!] Rule found:
        echo     ^|
        echo     ^|- IP: !onlyIP!
        echo     ^|- Direction: !DIRECTION!
        echo     ^|- Name: "!ruleNameLine!"
        echo.
    )
)

pause
goto main_menu

:block_port
cls
echo ==========================================================================
echo                       BLOCK PORT IN FIREWALL
echo ==========================================================================
echo Current direction: !DIRECTION!
echo.

set "port="
set /p "port=Enter the port to block: "

REM Validate port using reusable function
call :validate_port port
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "protocol="
set /p "protocol=Enter the protocol [TCP/UDP] (default TCP): "

if "!protocol!"=="" set "protocol=TCP"

REM Validate protocol using reusable function
call :validate_protocol "!protocol!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "comment="
set /p "comment=Enter the rule name (optional): "

REM Validate rule name if not empty
if not "!comment!"=="" (
    call :validate_name "!comment!"
    if !errorlevel! neq 0 (
        pause
        goto main_menu
    )
)

set "ruleName=Block Port - !port! (!protocol!)"
if not "!comment!"=="" (
    set "ruleName=!ruleName! - !comment!"
)

echo.
echo ==========================================================================
echo Step 1 - Checking if the port is already blocked
echo ==========================================================================
echo.

echo Executing command:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Block Port - !port!" | findstr /C:"!protocol!"
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Block Port - !port!" | findstr /C:"!protocol!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERROR] Check completed:
    echo     ^|
    echo     ^|- Port !port! ^(!protocol!^) is already blocked
    echo     ^|- Cannot duplicate the rule
    echo.
    pause
    goto main_menu
) else (
    echo [INFO] Check completed:
    echo     ^|
    echo     ^|- Port !port! ^(!protocol!^) does not exist in the firewall
    echo     ^|- Proceeding with blocking
)

echo.
echo ==========================================================================
echo Step 2 - Executing port block
echo ==========================================================================
echo.

echo Executing command:
echo netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block protocol=!protocol! localport=!port!
echo.

netsh advfirewall firewall add rule name="!ruleName!" dir=!DIRECTION_LOWER! action=block protocol=!protocol! localport=!port! >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCESS] Block completed:
    echo     ^|
    echo     ^|- Port: !port! blocked successfully
    echo     ^|- Protocol: !protocol!
    echo     ^|- Direction: !DIRECTION!
    echo     ^|- Name: "!ruleName!"
) else (
    echo [ERROR] Block failed:
    echo     ^|
    echo     ^|- Could not block port !port!
    echo     ^|- Check administrator privileges
)

echo.
pause
goto main_menu

:unblock_port
cls
echo ==========================================================================
echo                    UNBLOCK PORT IN FIREWALL
echo ==========================================================================
echo Current direction: !DIRECTION!
echo.

set "port="
set /p "port=Enter the port to unblock: "

REM Validate port using reusable function
call :validate_port port
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
set "protocol="
set /p "protocol=Enter the protocol [TCP/UDP] (default TCP): "

if "!protocol!"=="" set "protocol=TCP"

REM Validate protocol using reusable function
call :validate_protocol "!protocol!"
if !errorlevel! neq 0 (
    pause
    goto main_menu
)

echo.
echo ==========================================================================
echo Step 1 - Searching for firewall rule for port: !port! (!protocol!)
echo ==========================================================================
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Block Port - !port!" | findstr /C:"!protocol!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] Search completed:
    echo     ^|
    echo     ^|- No rules found for port !port! "(!protocol!)"
    echo     ^|- Verify that the port is blocked
    echo.
    pause
    goto main_menu
)

REM Find the exact port rule
set "lastRule="
for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Block Port -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Block Port - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Block Port - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        echo !ruleNameLine! | findstr /C:"!port!" | findstr /C:"!protocol!" >nul 2>&1
        if !errorlevel! equ 0 (
            set "lastRule=!ruleNameLine!"
        )
    )
)

echo [SUCCESS] Search completed:
echo     ^|
echo     ^|- Port: !port!
echo     ^|- Protocol: !protocol!
echo     ^|- Direction: !DIRECTION!
echo     ^|- Name: "!lastRule!"
echo.

echo ==========================================================================
echo Step 2 - Executing rule deletion
echo ==========================================================================
echo.

echo Executing command:
echo netsh advfirewall firewall delete rule name="!lastRule!"
echo.

netsh advfirewall firewall delete rule name="!lastRule!" >nul 2>&1

if !errorlevel! equ 0 (
    echo [SUCCESS] Deletion completed:
    echo     ^|
    echo     ^|- Rule deleted successfully
    echo     ^|- Port: !port!
    echo     ^|- Protocol: !protocol!
    echo     ^|- Direction: !DIRECTION!
    echo     ^|- Name: "!lastRule!"
) else (
    echo [ERROR] Deletion failed:
    echo     ^|
    echo     ^|- Could not delete the rule
    echo     ^|- Port: !port!
    echo     ^|- Name: "!lastRule!"
)

echo.
pause
goto main_menu

:view_blocked_ports
setlocal
cls
echo ==========================================================================
echo                     BLOCKED PORTS IN FIREWALL
echo ==========================================================================
echo Current direction: !DIRECTION!
echo.

echo Executing command:
echo netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! ^| findstr /C:"Block Port"
echo.

netsh advfirewall firewall show rule name=all dir=!DIRECTION_LOWER! | findstr /C:"Block Port -" >nul 2>&1
if !errorlevel! neq 0 (
    echo [INFO] Check completed:
    echo     ^|
    echo     ^|- There are no blocked ports currently
    echo.
    endlocal
    pause
    goto main_menu
)

echo ==========================================================================
echo                        LIST OF BLOCKED PORTS
echo ==========================================================================
echo.

set "counter=0"

for /f "tokens=*" %%a in ('netsh advfirewall firewall show rule name^=all dir^=!DIRECTION_LOWER! ^| findstr /C:"Block Port -"') do (
    set "line=%%a"
    set "ruleNameLine=!line:*Block Port - =!"
    if not "!ruleNameLine!"=="!line!" (
        set "ruleNameLine=Block Port - !ruleNameLine!"
        for /f "tokens=* delims= " %%b in ("!ruleNameLine!") do set "ruleNameLine=%%b"
        set "ruleData=!ruleNameLine:Block Port - =!"
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
        echo [!counter!] Rule found:
        echo     ^|
        echo     ^|- Port: !port!
        echo     ^|- Protocol: !protocol!
        echo     ^|- Direction: !DIRECTION!
        echo     ^|- Name: "!ruleNameLine!"
        echo.
    )
)
endlocal
pause
goto main_menu



REM =============================================================================
REM                       REUSABLE VALIDATION FUNCTIONS (Port, IP)
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
    echo [ERROR] Empty port. You must enter a valid port.
    echo.
    endlocal & exit /b 1
)

REM normalize
set "port_norm=!port: =!"

REM Validate general format (digits, commas and hyphens only)
call :check_port_format "!port_norm!"
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Invalid port format.
    echo     ^|
    echo     ^|- Only numbers, commas and hyphens are allowed
    echo     ^|- Valid examples:
    echo     ^|
    echo     ^|   - 5001 ^(single port^)
    echo     ^|
    echo     ^|   - 5000-5001 ^(range^)
    echo     ^|   - 5000 - 5001 ^(range^)
    echo     ^|
    echo     ^|   - 80,443,5000 ^(list^)
    echo     ^|   - 80, 443, 5000 ^(list^)
    echo     ^|
    echo     ^|   - 80,443,5000-5001 ^(mix^)
    echo     ^|   - 80, 443, 5000-5001 ^(mix^)
    echo     ^|   - 80, 443, 5000 - 5001 ^(mix^)
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
                    echo [ERROR] Invalid range: !start! ^> !end!
                    echo     ^|
                    echo     ^|- The start port must be less than or equal to the end
                    echo     ^|- Valid example:
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
    echo [ERROR] Invalid leading zero: "!port!"
    echo     ^| Invalid example: 05000
    echo     ^| Valid example: 5000
    echo.
    endlocal & exit /b 1
)


REM Validate range (1-65535)
set /a num=0 + !port! 2>nul
if !num! lss 1 (
    echo.
    echo [ERROR] Invalid port: !port!
    echo     ^|
    echo     ^|- Must be between 1 and 65535
    echo     ^|- Valid examples:
    echo     ^|   - 5001 ^(single port^)
    echo     ^|   - 5000-5001 ^(range^)
    echo     ^|   - 80,443,5000 ^(list^)
    echo     ^|   - 80,443,5000-5001 ^(mix^)
    echo.
    endlocal & exit /b 1
)
if !num! gtr 65535 (
    echo.
    echo [ERROR] Invalid port: !port!
    echo     ^|
    echo     ^|- Must be between 1 and 65535
    echo     ^|- Valid examples:
    echo     ^|   - 5001 ^(single port^)
    echo     ^|   - 5000-5001 ^(range^)
    echo     ^|   - 80,443,5000 ^(list^)
    echo     ^|   - 80,443,5000-5001 ^(mix^)
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
    echo [ERROR] Empty IP. You must enter a valid IP.
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
    echo [ERROR] Invalid IP format.
    echo     ^|
    echo     ^|- Ports are not allowed ^(example: 192.168.1.1:443^)
    echo     ^|- Valid examples:
    echo     ^|   - 192.168.1.1    ^(single IP^)
    echo     ^|   - 192.168.1.0/24 ^(CIDR range^)
    echo.
    endlocal & exit /b 1
)

REM Validate ip_base basic format (4 octets)
( <nul set /p="!ip_base!" | findstr /R /C:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" ) >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Invalid IP format.
    echo     ^|
    echo     ^|- Only numbers and dots are allowed
    echo     ^|- Valid examples:
    echo     ^|   - 192.168.1.1    ^(single IP^)
    echo     ^|   - 192.168.1.0/24 ^(CIDR range^)
    echo.
    endlocal & exit /b 1
)

REM Validate CIDR mask (if present)
if "!is_cidr!"=="true" (
    if "!cidr_mask!"=="" (
        echo.
        echo [ERROR] Empty CIDR mask. Required format: IP/MASK
        echo.
        endlocal & exit /b 1
    )   

    REM Validate mask is numeric
    for /f "delims=0123456789" %%x in ("!cidr_mask!") do (
        echo.
        echo [ERROR] Invalid CIDR mask: "!cidr_mask!"
        echo     ^|
        echo     ^|- Only numbers are allowed ^(0-32^)
        echo.
        endlocal & exit /b 1
    )

    REM Validate leading zero in CIDR mask
    if not "!cidr_mask!"=="0" if "!cidr_mask:~0,1!"=="0" (
        echo.
        echo [ERROR] Invalid leading zero in CIDR mask ^(CIDR range^): "!cidr_mask!"
        echo     ^| Invalid example: /024
        echo     ^| Valid example: /24
        echo.
        endlocal & exit /b 1
    )
    
    REM Validate mask range (0-32)
    set /a num_mask=0 + !cidr_mask! 2>nul
    if !num_mask! lss 0 (
        echo.
        echo [ERROR] CIDR mask out of range: !cidr_mask!
        echo     ^|
        echo     ^|- Range must be between ^(0 and 32^)
        echo.
        endlocal & exit /b 1
    )

    if !num_mask! gtr 32 (
        echo.
        echo [ERROR] CIDR mask out of range: !cidr_mask!
        echo     ^|
        echo     ^|- Range must be between ^(0 and 32^)
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
        echo [ERROR] Invalid leading zero in octet !pos!: "!value!"
        echo     ^| Invalid example: 192.080.1.1
        echo     ^| Valid example: 192.80.1.1
        echo.
        endlocal
        exit /b 1
    )
    
    REM Range 0-255
    set /a num=0 + !value! 2>nul
    if !num! gtr 255 (
        echo.
        echo [ERROR] Octet !pos!: "!value!" ^> 255
        echo     ^| Allowed range: 0-255
        echo.
        endlocal
        exit /b 1
    )
    if !num! lss 0 (
        echo.
        echo [ERROR] Octet !pos!: "!value!" ^< 0
        echo     ^| Allowed range: 0-255
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
echo [ERROR] Invalid protocol.
echo     ^|
echo     ^|- Only allowed: TCP or UDP
echo     ^|- Valid examples: TCP, tcp, UDP, udp
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
    echo [ERROR] Rule name too long.
    echo     ^|
    echo     ^|- Maximum length: 255 characters
    echo.
    endlocal & exit /b 1
)

REM Validate dangerous characters
( <nul set /p="!name!" | findstr /R /C:"[^A-Za-z0-9 _-]" ) >nul 2>&1 && (
    echo.
    echo [ERROR] Rule name contains dangerous characters.
    echo     ^|
    echo     ^|- Not allowed: ^& ^| ^" ^< ^> ^^ %% !!
    echo     ^|- Use only letters, numbers and spaces
    echo.
    endlocal & exit /b 1
)

REM Validate dangerous reserved words (with trailing space)
for %%W in ("format " "del " "remove " "erase " "rd " "rmdir " "delete " "echo " "cmd " "powershell ") do (
    ( <nul set /p=" !name! " | findstr /I /C:%%~W ) >nul 2>&1 && (
        echo.
        echo [ERROR] Rule name contains reserved words.
        echo     ^|
        echo     ^|- System commands are not allowed
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
    set "operation=Block"
    set "verbPast=Blocked"
    set "result=Blocked"
    set "message_action=Proceeding with blocking"
    set "message_success=Application blocked"
    set "message_error=Could not block the application"
) else (
    set "operation=Unblock"
    set "verbPast=Unblocked"
    set "result=Unblocked"
    set "message_action=Proceeding with unblocking"
    set "message_success=Application unblocked"
    set "message_error=Could not unblock the application"
)

cls
echo ==========================================================================
echo                 %operation% ADOBE APPLICATIONS IN FIREWALL
echo ==========================================================================
echo Current direction: !DIRECTION!
echo.
echo NOTE: This process will %action% internet access for ALL executables (.exe) found
echo       for Adobe, to avoid bandwidth usage.
echo.

REM Show paths to scan (only once)
echo Searching in the following Adobe locations:
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
    echo Adobe locations found:
    for %%P in ("%ADOBE_PATHS:;=" "%") do (
        if exist "%%~P" echo   - %%~P
    )
    echo.
    
    REM Now scan the found paths
    for %%P in ("%ADOBE_PATHS:;=" "%") do (
        if exist "%%~P" (
            echo Scanning base path: %%~P
            REM Start recursive search up to 5 levels
            call :search_adobe "%%~P" 1 "!action!"
        )
    )
) else (
    echo [WARNING] Adobe not found in standard locations
    echo     ^| Adobe is not installed in any of the typical locations
    echo     ^| If you installed Adobe elsewhere, move it to one of the listed paths
    echo     ^| above for automatic detection
    echo.
)

echo.
echo ==========================================================================
echo Result of %action%
echo ==========================================================================
echo.
echo [INFO] Applications found: !app_count!
echo [INFO] Applications %result%: !result_count!
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
        set "rule_name=Block Adobe - !app_name!"
        
        echo.
        echo ==========================================================================
        echo Step 1 - Checking if application is already %verbPast%
        echo ==========================================================================
        echo.
        
        echo Executing command:
        echo netsh advfirewall firewall show rule name="!rule_name!"
        echo.
        
        REM Check if the rule exists
        netsh advfirewall firewall show rule name="!rule_name!" >nul 2>&1
        set "rule_exists=!errorlevel!"

        if /i "!action!"=="block" (
            if !rule_exists! equ 0 (
                :: Show Blocked State
                echo [INFO] Check completed:
                echo     ^|
                echo     ^|- Application !app_name! is already blocked
                echo     ^|- Cannot duplicate the rule
                echo.
            ) else (
                :: Execute Block
                echo [INFO] Check completed:
                echo     ^|
                echo     ^|- Application !app_name! is not present in the firewall
                echo     ^|   %message_action%
                echo.
                
                echo ==========================================================================
                echo Step 2 - Executing Application Block
                echo ==========================================================================
                echo.
                
                echo Executing command:
                echo netsh advfirewall firewall add rule name="!rule_name!" dir=out action=block program="!file!"
                REM Block the application (outbound traffic only)
                netsh advfirewall firewall add rule name="!rule_name!" dir=out action=block program="!file!" >nul 2>&1
                
                if !errorlevel! equ 0 (
                    set /a "result_count+=1"
                    echo [SUCCESS] Block completed:
                    echo     ^|
                    echo     ^|- Application: !app_name!
                    echo     ^|- Path: !file!
                    echo     ^|- Rule name: "!rule_name!"
                ) else (
                    echo [ERROR] Block failed:
                    echo     ^|
                    echo     ^|- %message_error% !app_name!
                    echo     ^|- Check administrator privileges
                )
            )
        ) else (  
            :: Unblock section          
            if !rule_exists! equ 0 (
                :: Execute unblock
                echo [INFO] Check completed:
                echo     ^|
                echo     ^|- Application !app_name! is blocked
                echo     ^|   %message_action%
                echo.
                
                echo ==========================================================================
                echo Step 2 - Executing Application Unblock
                echo ==========================================================================
                echo.
                
                echo Executing command:
                echo netsh advfirewall firewall delete rule name="!rule_name!"
                REM Unblock the application
                netsh advfirewall firewall delete rule name="!rule_name!" >nul 2>&1
                
                if !errorlevel! equ 0 (
                    set /a "result_count+=1"
                    echo [SUCCESS] Unblock completed:
                    echo     ^|
                    echo     ^|- Application: !app_name!
                    echo     ^|- Path: !file!
                    echo     ^|- Rule name: "!rule_name!"
                ) else (
                    echo [ERROR] Unblock failed:
                    echo     ^|
                    echo     ^|- %message_error% !app_name!
                    echo     ^|- Check administrator privileges
                )
            ) else (
                :: Show unblocked state
                echo [INFO] Check completed:
                echo     ^|
                echo     ^|- Application !app_name! is not blocked
                echo     ^|- No need to unblock
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