# ============================================================
# SESTRD — Deploy para GitHub Pages
# Execute com duplo clique ou: PowerShell -ExecutionPolicy Bypass -File deploy.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$repo  = "gexsls-sestrd/sestrd-gexsls"
$file  = "index.html"
$sha   = "a267830effc8adf63c94afcb51ec009b46ca2b32"  # SHA atual no repo
$branch = "main"
$msg   = "feat: melhorias ROI/RO/usuarios + bugfixes (deploy automatico)"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   SESTRD — Deploy para GitHub Pages" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se o arquivo existe
$srcPath = Join-Path $PSScriptRoot "index.html"
if (-not (Test-Path $srcPath)) {
    Write-Host "ERRO: index.html nao encontrado em $srcPath" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Pedir token
Write-Host "Informe o GitHub Personal Access Token (ghp_...):" -ForegroundColor Yellow
Write-Host "(Settings -> Developer settings -> Personal access tokens -> Fine-grained ou Classic)" -ForegroundColor Gray
Write-Host "(Permissao necessaria: Contents = Read and write)" -ForegroundColor Gray
Write-Host ""
$token = Read-Host "Token"
if (-not $token -or $token.Trim() -eq "") {
    Write-Host "ERRO: Token nao informado." -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host ""
Write-Host "Lendo index.html..." -ForegroundColor Gray
$bytes   = [System.IO.File]::ReadAllBytes($srcPath)
$b64     = [System.Convert]::ToBase64String($bytes)

Write-Host "Preparando commit (arquivo: $([math]::Round($bytes.Length/1024))KB)..." -ForegroundColor Gray

$body = @{
    message = $msg
    content = $b64
    sha     = $sha
    branch  = $branch
} | ConvertTo-Json -Depth 3

$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "Content-Type" = "application/json"
}

Write-Host "Enviando para GitHub ($repo)..." -ForegroundColor Gray

try {
    $url = "https://api.github.com/repos/$repo/contents/$file"
    $resp = Invoke-RestMethod -Method Put -Uri $url -Headers $headers -Body $body
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   DEPLOY CONCLUIDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Commit: $($resp.commit.sha.Substring(0,7))" -ForegroundColor Green
    Write-Host "URL: https://gexsls-sestrd.github.io/sestrd-gexsls/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "GitHub Pages atualiza em ~1-2 minutos." -ForegroundColor Gray
}
catch {
    Write-Host ""
    Write-Host "ERRO no deploy:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host $reader.ReadToEnd() -ForegroundColor Red
    }
}

Write-Host ""
Read-Host "Pressione Enter para fechar"
