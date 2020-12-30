@echo off

where gpg.exe >nul 2>nul

IF NOT ERRORLEVEL 0 (
    echo GPG isn't installed. Exiting...
    exit 1
)

for /F "tokens=1,* delims=:" %%a in ('chcp') do set ORIGCP=%%b
set tmpfile="%TMP%\temppass.txt"

IF NOT DEFINED PASSWORD_STORE_CLIP_TIME (
    set PASSWORD_STORE_CLIP_TIME=45
)

IF NOT DEFINED PASSWORD_STORE_KEY (
	FOR /F "delims=" %%k in (%PASSWORD_STORE_DIR%\.gpg-id) DO set "PASSWORD_STORE_KEY=%%k"
)

IF NOT DEFINED PASSWORD_STORE_DIR (
	echo.PASSWORD_STORE_DIR system variable not defined, defaulting to "%USERPROFILE%\.password-store\"
	echo.You can change this sysvar anytime in SystemPropertiesAdvanced.exe or via setx. See setx/? for help.
	set PASSWORD_STORE_DIR="%USERPROFILE%\.password-store"
	::setx PASSWORD_STORE_DIR "%USERPROFILE%\.password-store"
)

IF [%~1] EQU [] (
    echo.Copyright ^(c^) 2012-2018, Jason A. Donenfeld ^<Jason@zx2c4.com^> 
	echo.Copyright ^(c^) 2019-2020, Miquel Lionel
	echo.
	echo.Here's the available parameters for pass. Text between [] is MANDATORY:
	echo.
	echo.  ls - without arguments, it list the entire password store as a tree.
	echo.  view [passname] - decrypt the password with name [passname], output the result to the console
	echo.  insert [passname] - insert a password with name [passname], prompt for input. Stop and save with a newline and by pressing Ctrl+Z on your keyboard.
	echo.  rm [passname] - delete the password matching [passname]. Prompts for confirmation.
	echo.  rmf [passname] - force the deletion of password matching [passname].
	echo.  rmrf [passname] - recursively and forcefully delete a directory in the password store.
	echo.  clip [passname] [linenumber] - copy into the clipboard the text at line [linenumber] for password matching [passname].

        echo.
        echo.ENVIRONNEMENT VARIABLES:
        echo.   PASSWORD_STORE_KEY    The key^(s^) ID in 0xlong form. Can alternatively be in a .gpg-id file in the password store directory, searches in it by default.
	echo.   PASSWORD_STORE_DIR    The directory which contains the password, with .gpg extension.
    echo.   PASSWORD_STORE_CLIP_TIME    The time remaining for which a password copied to the clipboard.

)

IF ["%1"] EQU ["init"] (
	shift
	if [%~1] EQU [] (
		md %PASSWORD_STORE_DIR%\.extensions
		echo.%PASSWORD_STORE_KEY%>%PASSWORD_STORE_DIR%\.gpg-id
		
	) ELSE (
		md "%PASSWORD_STORE_DIR%\%~1\.extensions"
		echo.%PASSWORD_STORE_KEY%>"%PASSWORD_STORE_DIR%\%~1\.gpg-id"
	)
	goto :eof
)

IF ["%1"] EQU ["ls"] (
	tree /F "%PASSWORD_STORE_DIR%"
	goto :eof
)

IF ["%1"] EQU ["view"] (
        :: remove 2>nul for debug info
        chcp 65001 >nul
	gpg --default-key %PASSWORD_STORE_KEY% -d "%PASSWORD_STORE_DIR%\%~2.gpg" 2>nul
        chcp %ORIGCP% >nul
	goto :eof
)

IF ["%1"] EQU ["insert"] (
	shift
	gpg -r %PASSWORD_STORE_KEY% -e -a -o "%PASSWORD_STORE_DIR%\%~2.gpg"
	goto :eof

)

IF ["%1"] EQU ["md"] (
	shift
	md "%PASSWORD_STORE_DIR%\%~2.gpg"
	goto :eof

)

IF ["%1"] EQU ["rm"] (
	shift
	IF NOT ["%~2"] EQU [] (
		del /P "%PASSWORD_STORE_DIR%\%~2.gpg"
	)
	goto :eof

)

IF ["%1"] EQU ["rmf"] (
	shift
	IF NOT ["%~2"] EQU [] (
		del /F "%PASSWORD_STORE_DIR%\%~2.gpg"
	)
	goto :eof

)

IF ["%1"] EQU ["rmrf"] (
	shift
	IF NOT ["%~2"] EQU [] (
		rmdir /S /Q "%PASSWORD_STORE_DIR%\%~2.gpg"
	)
	goto :eof

)

IF ["%1"] EQU ["mv"] (
	shift
	IF NOT ["%~2"] EQU [] (
		move "%PASSWORD_STORE_DIR%\%~2.gpg" "%PASSWORD_STORE_DIR%\%~3.gpg"
	)
	goto :eof

)

IF ["%1"] EQU ["clip"] (
    shift
    set LINENUMBER=%~3
    if defined LINENUMBER (
	echo hoo
        for /F "tokens=1,2* delims=:" %%a in ('chcp 65001 ^>nul ^&^& pass view "%~2" ^| findstr/n ^^^^ ^| findstr /i /b "%~3:" ^&^& chcp %ORIGCP% ^>nul') do (
            echo.%%b|clip
	    start /MIN /B "" "cmd /c ping ::1 -n %PASSWORD_STORE_CLIP_TIME% >nul && cmd /c echo.|C:\Windows\System32\clip.exe"
        )
    ) else (
        for /F "tokens=1,2* delims=:" %%a in ('chcp 65001 ^>nul ^&^& pass view "%~2" ^| findstr/n ^^^^ ^| findstr /i /b "1:" ^&^& chcp %ORIGCP% ^>nul') do (
            echo.%%b|clip
	    start /MIN /B "" "cmd /c ping ::1 -n %PASSWORD_STORE_CLIP_TIME% >nul && cmd /c echo.|C:\Windows\System32\clip.exe"
        )
    )
    goto :eof

)

IF ["%1"] EQU ["edit"] (
    shift
    gpg -o %tmpfile% -d "%PASSWORD_STORE_DIR%\%~2.gpg"
    start /W "" notepad %tmpfile%
    gpg -r %PASSWORD_STORE_KEY% -e -a -o "%PASSWORD_STORE_DIR%\%~2.gpg" %tmpfile%
    del /Q %tmpfile%
    goto :eof
)

IF EXIST "%PASSWORD_STORE_DIR%\%~1.gpg" (
    pass view "%~1"
    goto :eof
)

goto :eof
