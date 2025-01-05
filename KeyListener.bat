@ECHO OFF
SETLOCAL EnableDelayedExpansion

SET key_listener=

:start_app
CLS
ECHO nacisnij [W,S,A,D] by sie poruszac
ECHO !key_listener!>KeyStroke.txt
ECHO wcisniety przycisk [!key_listener!]
REM SET /p key_listener=
CHOICE /C wsad /N
if errorlevel 4 (
  SET key_listener=d
  GOTO :start_app
)
if errorlevel 3 (
  SET key_listener=a
  GOTO :start_app
)
if errorlevel 2 (
  SET key_listener=s
  GOTO :start_app
)
if errorlevel 1 (
  SET key_listener=w
  GOTO :start_app
)
GOTO :start_app