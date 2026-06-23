@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
set GIT="C:\Program Files\Git\cmd\git.exe"
cd /d "C:\Users\Bruno Conte\Documents\Claude\Projects\Projeto de aplicativo para o SEST-RD para controle de AROS"
echo === Redeploy SEST-RD -^> GitHub Pages ===
echo.

rem Limpa locks fantasma que travam o git (corrupcao da pasta montada).
del /f /q ".git\HEAD.lock" ".git\index.lock" ".git\refs\heads\main.lock" ".git\objects\maintenance.lock" 2>nul

rem Primeira execucao: cria o repo local e ADOTA o historico remoto existente.
rem (Sem isso, o primeiro push seria rejeitado como non-fast-forward, pois o
rem  repo ja tem commits feitos antes pela API do GitHub.)
if not exist .git (
  %GIT% init
  %GIT% branch -M main
  %GIT% remote add origin https://github.com/gexsls-sestrd/sestrd-gexsls.git
  echo Sincronizando com o historico remoto...
  %GIT% fetch origin main
  rem Aponta o HEAD local para o ultimo commit remoto, mantendo seus arquivos.
  %GIT% reset --soft origin/main 2>nul
)

rem Garante o remote SO se faltar (nao reescreve .git/config a cada run).
%GIT% remote get-url origin >nul 2>&1 || %GIT% remote add origin https://github.com/gexsls-sestrd/sestrd-gexsls.git

rem Pede a mensagem do commit. Enter usa um padrao com data/hora.
set "MSG="
set /p "MSG=Mensagem do commit (Enter p/ usar data/hora): "
if "!MSG!"=="" set "MSG=Deploy SEST-RD %DATE% %TIME%"

rem Envia as mudancas: add -> commit -> push (incremental).
%GIT% add -A
%GIT% -c user.email=eng.comte@gmail.com -c user.name="Bruno Conte" commit -m "!MSG!"
%GIT% push -u origin main

echo ===EXITCODE_%errorlevel%=== > deploy_log.txt
echo.
echo Pronto. O GitHub Pages detecta o push e republica sozinho (~1-2 min).
echo URL: https://gexsls-sestrd.github.io/sestrd-gexsls/
echo Se aparecer "rejected"/"non-fast-forward" no log, me avise (historico divergiu).
echo Detalhes em deploy_log.txt.
pause
