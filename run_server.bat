@echo off
title SQL Mastery Handbook Server
echo =====================================================================
echo  🚀 SQL MASTERY: DATA ANALYST TO DATA ENGINEER (WEB HANDBOOK)
echo =====================================================================
echo.

REM Lay dia chi IP noi bo de ket noi tu dien thoai
for /f "delims=" %%a in ('python -c "import socket; s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(('8.8.8.8', 80)); print(s.getsockname()[0]); s.close()" 2^>nul') do set LOCAL_IP=%%a

if "%LOCAL_IP%"=="" set LOCAL_IP=127.0.0.1

echo May chu web dang chay tai:
echo   [1] Tren May Tinh: http://localhost:8000
echo   [2] TREN DIEN THOAI (bat cung mang Wi-Fi): 
echo       ==^> http://%LOCAL_IP%:8000
echo.
echo =====================================================================
echo.

start "" "http://localhost:8000"

python -m http.server 8000 --bind 0.0.0.0
pause
