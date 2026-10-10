@echo off
setlocal
cd /d "%~dp0.."

set "PY="
where py >nul 2>nul && set "PY=py -3"
if not defined PY where python >nul 2>nul && set "PY=python"
if not defined PY (
  echo ERROR: Python 3 is required to pack config tables.
  exit /b 1
)

%PY% -c "import xlrd" >nul 2>nul
if errorlevel 1 (
  echo Installing packer dependencies...
  %PY% -m pip install -r tools\requirements.txt
  if errorlevel 1 exit /b 1
)

%PY% tools\pack_config.py %*
exit /b %ERRORLEVEL%
