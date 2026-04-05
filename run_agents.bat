@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

:menu
cls
echo ====================================================
echo               LAMBDA AGENTS MANAGER
echo ====================================================
echo --- START AGENTS ---
echo  1. Start Intake Agent (Port 8000)
echo  2. Start Validation Agent (Port 8010)
echo  3. Start Recommendation Agent (Port 8020)
echo  4. Start ALL Agents
echo.
echo --- STOP AGENTS ---
echo  5. Stop Intake Agent (Port 8000)
echo  6. Stop Validation Agent (Port 8010)
echo  7. Stop Recommendation Agent (Port 8020)
echo  8. Stop ALL Agents
echo.
echo --- STATUS ---
echo  9. Check Health Status
echo  0. Exit
echo ====================================================
set /p choice="Enter your choice (0-9): "

if "%choice%"=="1" goto start_intake
if "%choice%"=="2" goto start_validation
if "%choice%"=="3" goto start_recommendation
if "%choice%"=="4" goto start_all
if "%choice%"=="5" goto stop_intake
if "%choice%"=="6" goto stop_validation
if "%choice%"=="7" goto stop_recommendation
if "%choice%"=="8" goto stop_all
if "%choice%"=="9" goto check_health
if "%choice%"=="0" exit
goto menu

:start_intake
echo [Intake Agent] Installing dependencies...
cd intake_agent
pip install -r requirements.txt
start "Intake Agent (8000)" cmd /k "python -m uvicorn local_api:app --port 8000 --reload"
cd ..
pause
goto menu

:start_validation
echo [Validation Agent] Installing dependencies...
cd validation_agent
pip install -r requirements.txt
start "Validation Agent (8010)" cmd /k "python -m uvicorn local_api:app --port 8010 --reload"
cd ..
pause
goto menu

:start_recommendation
echo [Recommendation Agent] Installing dependencies...
cd recommendation_agents
pip install -r requirements.txt
start "Recommendation Agent (8020)" cmd /k "python -m uvicorn local_api:app --port 8020 --reload"
cd ..
pause
goto menu

:start_all
echo Starting ALL Agents...
cd intake_agent
pip install -r requirements.txt
start "Intake Agent (8000)" cmd /k "python -m uvicorn local_api:app --port 8000 --reload"
cd ..

cd validation_agent
pip install -r requirements.txt
start "Validation Agent (8010)" cmd /k "python -m uvicorn local_api:app --port 8010 --reload"
cd ..

cd recommendation_agents
pip install -r requirements.txt
start "Recommendation Agent (8020)" cmd /k "python -m uvicorn local_api:app --port 8020 --reload"
cd ..
pause
goto menu

:stop_intake
echo Stopping Intake Agent (Port 8000)...
for /f "tokens=5" %%a in ('netstat -aon ^| find "LISTENING" ^| find ":8000"') do taskkill /F /PID %%a >nul 2>&1
echo Intake Agent stopped.
pause
goto menu

:stop_validation
echo Stopping Validation Agent (Port 8010)...
for /f "tokens=5" %%a in ('netstat -aon ^| find "LISTENING" ^| find ":8010"') do taskkill /F /PID %%a >nul 2>&1
echo Validation Agent stopped.
pause
goto menu

:stop_recommendation
echo Stopping Recommendation Agent (Port 8020)...
for /f "tokens=5" %%a in ('netstat -aon ^| find "LISTENING" ^| find ":8020"') do taskkill /F /PID %%a >nul 2>&1
echo Recommendation Agent stopped.
pause
goto menu

:stop_all
echo Stopping ALL Agents...
for /f "tokens=5" %%a in ('netstat -aon ^| find "LISTENING" ^| find ":8000"') do taskkill /F /PID %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find "LISTENING" ^| find ":8010"') do taskkill /F /PID %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find "LISTENING" ^| find ":8020"') do taskkill /F /PID %%a >nul 2>&1
echo All agents stopped.
pause
goto menu

:check_health
echo.
echo ====================================================
echo HEALTH STATUS
echo ====================================================
echo [Intake Agent - 8000]
curl -s http://localhost:8000/health || echo ❌ Offline
echo.
echo.
echo [Validation Agent - 8010]
curl -s http://localhost:8010/health || echo ❌ Offline
echo.
echo.
echo [Recommendation Agent - 8020]
curl -s http://localhost:8020/health || echo ❌ Offline
echo.
echo ====================================================
pause
goto menu