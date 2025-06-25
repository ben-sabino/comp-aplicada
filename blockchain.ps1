# Script PowerShell para gerenciar a rede blockchain NaiveCoin

param(
    [string]$Action,
    [int]$Node = 1,
    [int]$ToNode = 2,
    [int]$Amount = 10
)

function Show-Help {
    Write-Host "=== Gerenciador da Rede Blockchain NaiveCoin ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Uso: .\blockchain.ps1 -Action <comando> [parâmetros]"
    Write-Host ""
    Write-Host "Comandos disponíveis:" -ForegroundColor Yellow
    Write-Host "  start                     - Inicia a rede blockchain"
    Write-Host "  stop                      - Para a rede blockchain"
    Write-Host "  status                    - Mostra status de todos os nós"
    Write-Host "  balance                   - Mostra saldo de um nó (-Node 1-5)"
    Write-Host "  mine                      - Minera bloco (-Node 1-5)"
    Write-Host "  send                      - Envia transação (-Node origem -ToNode destino -Amount valor)"
    Write-Host "  logs                      - Mostra logs de um nó (-Node 1-5)"
    Write-Host "  monitor                   - Inicia monitoramento contínuo"
    Write-Host "  restart                   - Reinicia toda a rede"
    Write-Host "  clean                     - Para e limpa tudo"
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Cyan
    Write-Host "  .\blockchain.ps1 -Action start"
    Write-Host "  .\blockchain.ps1 -Action status"
    Write-Host "  .\blockchain.ps1 -Action balance -Node 1"
    Write-Host "  .\blockchain.ps1 -Action mine -Node 2"
    Write-Host "  .\blockchain.ps1 -Action send -Node 1 -ToNode 2 -Amount 10"
    Write-Host ""
}

function Get-NodeUrl {
    param([int]$NodeNumber)
    
    switch ($NodeNumber) {
        1 { return "localhost:3001" }
        2 { return "localhost:3002" }
        3 { return "localhost:3003" }
        4 { return "localhost:3004" }
        5 { return "localhost:3005" }
        default { return $null }
    }
}

function Get-NodeAddress {
    param([int]$NodeNumber)
    
    $url = Get-NodeUrl -NodeNumber $NodeNumber
    if (-not $url) {
        Write-Host "Nó inválido: $NodeNumber" -ForegroundColor Red
        return $null
    }
    
    try {
        $response = Invoke-RestMethod -Uri "http://$url/address" -TimeoutSec 5
        return $response.address
    }
    catch {
        Write-Host "Erro ao obter endereço do nó $NodeNumber" -ForegroundColor Red
        return $null
    }
}

function Start-Network {
    Write-Host "Iniciando rede blockchain..." -ForegroundColor Green
    docker-compose up -d --build
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Rede iniciada com sucesso!" -ForegroundColor Green
        Write-Host "Aguardando nós ficarem online..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        Write-Host "Acesse os nós em:" -ForegroundColor Cyan
        Write-Host "- Nó 1: http://localhost:3001"
        Write-Host "- Nó 2: http://localhost:3002"
        Write-Host "- Nó 3: http://localhost:3003"
        Write-Host "- Nó 4: http://localhost:3004"
        Write-Host "- Nó 5: http://localhost:3005"
    }
    else {
        Write-Host "Erro ao iniciar a rede!" -ForegroundColor Red
    }
}

function Stop-Network {
    Write-Host "Parando rede blockchain..." -ForegroundColor Yellow
    docker-compose down
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Rede parada com sucesso!" -ForegroundColor Green
    }
    else {
        Write-Host "Erro ao parar a rede!" -ForegroundColor Red
    }
}

function Show-Status {
    Write-Host "=== STATUS DA REDE ===" -ForegroundColor Green
    Write-Host ""
    
    for ($i = 1; $i -le 5; $i++) {
        $url = Get-NodeUrl -NodeNumber $i
        Write-Host "--- Nó $i ($url) ---" -ForegroundColor Yellow
        
        try {
            $blocks = Invoke-RestMethod -Uri "http://$url/blocks" -TimeoutSec 3
            $balance = Invoke-RestMethod -Uri "http://$url/balance" -TimeoutSec 3
            $address = Invoke-RestMethod -Uri "http://$url/address" -TimeoutSec 3
            $peers = Invoke-RestMethod -Uri "http://$url/peers" -TimeoutSec 3
            
            Write-Host "Status: ONLINE" -ForegroundColor Green
            Write-Host "Endereço: $($address.address)"
            Write-Host "Saldo: $($balance.balance) coins"
            Write-Host "Blocos: $($blocks.Count)"
            Write-Host "Peers: $($peers.Count)"
        }
        catch {
            Write-Host "Status: OFFLINE" -ForegroundColor Red
        }
        Write-Host ""
    }
}

function Show-Balance {
    param([int]$NodeNumber)
    
    $url = Get-NodeUrl -NodeNumber $NodeNumber
    if (-not $url) {
        Write-Host "Nó inválido: $NodeNumber" -ForegroundColor Red
        return
    }
    
    try {
        $response = Invoke-RestMethod -Uri "http://$url/balance" -TimeoutSec 5
        Write-Host "Saldo do nó $NodeNumber`: $($response.balance) coins" -ForegroundColor Green
    }
    catch {
        Write-Host "Erro ao obter saldo do nó $NodeNumber" -ForegroundColor Red
    }
}

function Mine-Block {
    param([int]$NodeNumber)
    
    $url = Get-NodeUrl -NodeNumber $NodeNumber
    if (-not $url) {
        Write-Host "Nó inválido: $NodeNumber" -ForegroundColor Red
        return
    }
    
    Write-Host "Minerando bloco no nó $NodeNumber..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "http://$url/mineBlock" -Method Post -TimeoutSec 30
        Write-Host "Bloco minerado com sucesso!" -ForegroundColor Green
        Write-Host "Hash: $($response.hash)"
        Write-Host "Index: $($response.index)"
    }
    catch {
        Write-Host "Erro ao minerar bloco no nó $NodeNumber" -ForegroundColor Red
    }
}

function Send-Transaction {
    param([int]$FromNode, [int]$ToNode, [int]$Amount)
    
    $fromUrl = Get-NodeUrl -NodeNumber $FromNode
    $toAddress = Get-NodeAddress -NodeNumber $ToNode
    
    if (-not $fromUrl -or -not $toAddress) {
        Write-Host "Erro nos parâmetros dos nós" -ForegroundColor Red
        return
    }
    
    Write-Host "Enviando $Amount coins do nó $FromNode para o nó $ToNode..." -ForegroundColor Yellow
    
    try {
        $body = @{
            address = $toAddress
            amount = $Amount
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "http://$fromUrl/mineTransaction" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Write-Host "Transação enviada com sucesso!" -ForegroundColor Green
        Write-Host "Hash da transação: $($response.hash)"
    }
    catch {
        Write-Host "Erro ao enviar transação: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-Logs {
    param([int]$NodeNumber)
    
    $containerName = "naivecoin-node$NodeNumber"
    Write-Host "Logs do $containerName`:" -ForegroundColor Yellow
    docker logs $containerName --tail 50
}

function Start-Monitor {
    Write-Host "Iniciando monitoramento contínuo..." -ForegroundColor Green
    Write-Host "Pressione Ctrl+C para sair" -ForegroundColor Yellow
    Write-Host ""
    
    while ($true) {
        Clear-Host
        Write-Host "=== MONITOR DA REDE $(Get-Date) ===" -ForegroundColor Green
        Write-Host ""
        
        Show-Status
        
        Write-Host "Próxima atualização em 10 segundos..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
}

function Restart-Network {
    Write-Host "Reiniciando rede blockchain..." -ForegroundColor Yellow
    docker-compose restart
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Rede reiniciada com sucesso!" -ForegroundColor Green
    }
    else {
        Write-Host "Erro ao reiniciar a rede!" -ForegroundColor Red
    }
}

function Clean-Everything {
    Write-Host "Limpando tudo (containers, volumes, imagens)..." -ForegroundColor Yellow
    docker-compose down -v --rmi all
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Limpeza concluída!" -ForegroundColor Green
    }
    else {
        Write-Host "Erro durante a limpeza!" -ForegroundColor Red
    }
}

# Processamento dos comandos
switch ($Action.ToLower()) {
    "start" { Start-Network }
    "stop" { Stop-Network }
    "status" { Show-Status }
    "balance" { Show-Balance -NodeNumber $Node }
    "mine" { Mine-Block -NodeNumber $Node }
    "send" { Send-Transaction -FromNode $Node -ToNode $ToNode -Amount $Amount }
    "logs" { Show-Logs -NodeNumber $Node }
    "monitor" { Start-Monitor }
    "restart" { Restart-Network }
    "clean" { Clean-Everything }
    default { Show-Help }
}
