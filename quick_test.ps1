# Script de teste rápido para Windows PowerShell

Write-Host "=== TESTE RÁPIDO DA REDE BLOCKCHAIN ===" -ForegroundColor Green
Write-Host ""

# Verificar se Docker está rodando
try {
    docker --version | Out-Null
    Write-Host "✅ Docker detectado" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker não está instalado ou não está rodando" -ForegroundColor Red
    exit 1
}

try {
    docker-compose --version | Out-Null
    Write-Host "✅ Docker Compose detectado" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker Compose não está instalado" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Verificar portas
Write-Host "Verificando portas..." -ForegroundColor Yellow
$ports = @(3001, 3002, 3003, 3004, 3005, 6001, 6002, 6003, 6004, 6005)

foreach ($port in $ports) {
    $connection = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($connection) {
        Write-Host "⚠️  Porta $port já está em uso" -ForegroundColor Yellow
    }
    else {
        Write-Host "✅ Porta $port está livre" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== INICIANDO TESTE ===" -ForegroundColor Green

# Construir e iniciar containers
Write-Host "Construindo e iniciando containers..." -ForegroundColor Yellow
docker-compose up -d --build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao iniciar containers" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Containers iniciados" -ForegroundColor Green
Write-Host ""

# Aguardar nós ficarem online
Write-Host "Aguardando nós ficarem online (30 segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Testar conectividade
Write-Host ""
Write-Host "=== TESTANDO CONECTIVIDADE ===" -ForegroundColor Green
for ($i = 1; $i -le 5; $i++) {
    $port = 3000 + $i
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$port/blocks" -TimeoutSec 5
        Write-Host "✅ Nó $i (porta $port) está online" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Nó $i (porta $port) está offline" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== TESTE DE MINERAÇÃO ===" -ForegroundColor Green

# Minerar um bloco no nó 1
Write-Host "Minerando bloco no nó 1..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3001/mineBlock" -Method Post -TimeoutSec 30
    Write-Host "✅ Bloco minerado com sucesso" -ForegroundColor Green
    Write-Host "Hash: $($response.hash)" -ForegroundColor Cyan
    Write-Host "Index: $($response.index)" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Erro ao minerar bloco: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== VERIFICANDO SINCRONIZAÇÃO ===" -ForegroundColor Green

# Aguardar sincronização
Start-Sleep -Seconds 5

# Verificar se todos os nós têm o mesmo número de blocos
Write-Host "Verificando se todos os nós estão sincronizados..." -ForegroundColor Yellow
for ($i = 1; $i -le 5; $i++) {
    $port = 3000 + $i
    try {
        $blocks = Invoke-RestMethod -Uri "http://localhost:$port/blocks" -TimeoutSec 5
        Write-Host "Nó $i tem $($blocks.Count) blocos" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Nó $i: erro ao obter blocos" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== TESTE CONCLUÍDO ===" -ForegroundColor Green
Write-Host ""
Write-Host "Para continuar testando:" -ForegroundColor Yellow
Write-Host "- Execute: docker logs naivecoin-simulator"
Write-Host "- Acesse: http://localhost:3001/blocks"
Write-Host "- Use: .\blockchain.ps1 -Action status"
Write-Host ""
Write-Host "Para parar tudo:" -ForegroundColor Yellow
Write-Host "- Execute: docker-compose down"
