# Script PowerShell para executar stress tests no Windows
# Wrapper para os scripts bash de stress test

param(
    [int]$Duration = 300,
    [int]$Interval = 5,
    [switch]$Monitor,
    [switch]$Analyze,
    [switch]$Cleanup,
    [switch]$Help
)

# Função para mostrar ajuda
function Show-Help {
    Write-Host "=== Stress Test PowerShell - NaiveCoin ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Uso: .\run_stress_test.ps1 [parâmetros]"
    Write-Host ""
    Write-Host "Parâmetros:"
    Write-Host "  -Duration SECONDS    Duração do teste (padrão: 300)"
    Write-Host "  -Interval SECONDS    Intervalo entre operações (padrão: 5)"
    Write-Host "  -Monitor             Executar monitoramento em paralelo"
    Write-Host "  -Analyze             Executar análise após o teste"
    Write-Host "  -Cleanup             Limpar logs antigos antes do teste"
    Write-Host "  -Help                Mostra esta ajuda"
    Write-Host ""
    Write-Host "Exemplos:"
    Write-Host "  .\run_stress_test.ps1 -Duration 600 -Interval 3 -Monitor -Analyze"
    Write-Host "  .\run_stress_test.ps1 -Duration 1800"
    Write-Host "  .\run_stress_test.ps1 -Monitor"
    Write-Host ""
}

# Função para verificar se WSL está disponível
function Test-WSL {
    try {
        $wslVersion = wsl --version 2>$null
        return $true
    }
    catch {
        return $false
    }
}

# Função para verificar se os nós estão rodando
function Test-Nodes {
    Write-Host "Verificando se os nós estão rodando..." -ForegroundColor Blue
    
    $nodes = @("localhost:3001", "localhost:3002", "localhost:3003", "localhost:3004", "localhost:3005")
    $onlineCount = 0
    
    foreach ($node in $nodes) {
        try {
            $response = Invoke-WebRequest -Uri "http://$node/blocks" -TimeoutSec 3 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "  ✓ $node está online" -ForegroundColor Green
                $onlineCount++
            }
        }
        catch {
            Write-Host "  ✗ $node está offline" -ForegroundColor Red
        }
    }
    
    if ($onlineCount -eq 0) {
        Write-Host "Nenhum nó está rodando!" -ForegroundColor Red
        Write-Host "Inicie os nós primeiro:" -ForegroundColor Yellow
        Write-Host "  cd .. && .\blockchain.ps1"
        return $false
    }
    elseif ($onlineCount -lt $nodes.Count) {
        Write-Host "Apenas $onlineCount de $($nodes.Count) nós estão online" -ForegroundColor Yellow
        Write-Host "Recomendado: iniciar todos os nós para melhor teste" -ForegroundColor Yellow
    }
    else {
        Write-Host "✓ Todos os nós estão online" -ForegroundColor Green
    }
    
    return $true
}

# Função para executar stress test via WSL
function Start-StressTest {
    param(
        [int]$Duration,
        [int]$Interval,
        [bool]$Monitor,
        [bool]$Analyze,
        [bool]$Cleanup
    )
    
    Write-Host "Iniciando stress test via WSL..." -ForegroundColor Blue
    Write-Host "  Duração: $Duration segundos"
    Write-Host "  Intervalo: $Interval segundos"
    Write-Host ""
    
    # Construir comando
    $command = "./run_stress_test_complete.sh -d $Duration -i $Interval"
    
    if ($Monitor) {
        $command += " -m"
    }
    
    if ($Analyze) {
        $command += " -a"
    }
    
    if ($Cleanup) {
        $command += " -c"
    }
    
    Write-Host "Executando: $command" -ForegroundColor Yellow
    Write-Host ""
    
    # Executar via WSL
    wsl bash -c "cd /mnt/c/Users/pinsa/OneDrive/Documents/Blockchain/NaiveCoin/naivecoin/simulation && $command"
}

# Função para executar monitoramento via WSL
function Start-Monitoring {
    Write-Host "Iniciando monitoramento via WSL..." -ForegroundColor Blue
    
    # Executar monitor em nova janela do WSL
    Start-Process wsl -ArgumentList "bash -c 'cd /mnt/c/Users/pinsa/OneDrive/Documents/Blockchain/NaiveCoin/naivecoin/simulation && ./realtime_monitor.sh'"
    
    Write-Host "Monitor iniciado em nova janela" -ForegroundColor Green
}

# Função para executar análise via WSL
function Start-Analysis {
    Write-Host "Executando análise via WSL..." -ForegroundColor Blue
    
    wsl bash -c "cd /mnt/c/Users/pinsa/OneDrive/Documents/Blockchain/NaiveCoin/naivecoin/simulation && ./analyze_stress_test.sh -a"
    
    Write-Host "Análise concluída!" -ForegroundColor Green
}

# Função para mostrar resultados
function Show-Results {
    Write-Host "=== RESULTADOS DO STRESS TEST ===" -ForegroundColor Cyan
    Write-Host ""
    
    $logDir = ".\stress_test_logs"
    $analysisDir = ".\stress_test_analysis"
    
    if (Test-Path "$logDir\stress_test_report.txt") {
        Write-Host "Relatório de texto:" -ForegroundColor Blue
        Get-Content "$logDir\stress_test_report.txt"
        Write-Host ""
    }
    
    if (Test-Path "$analysisDir\stress_test_report.html") {
        Write-Host "Relatório HTML: $analysisDir\stress_test_report.html" -ForegroundColor Blue
        Write-Host ""
    }
    
    Write-Host "Arquivos de log:" -ForegroundColor Blue
    Write-Host "  - Log principal: $logDir\stress_test.log"
    Write-Host "  - Log de latência: $logDir\latency.log"
    Write-Host "  - Log de recursos: $logDir\resources.log"
    Write-Host "  - Log de performance: $logDir\performance.log"
    Write-Host ""
    
    Write-Host "Arquivos de análise:" -ForegroundColor Blue
    Write-Host "  - Diretório: $analysisDir\"
    if (Test-Path "$analysisDir\latency_over_time.png") {
        Write-Host "  - Gráfico de latência: $analysisDir\latency_over_time.png"
    }
    if (Test-Path "$analysisDir\system_resources.png") {
        Write-Host "  - Gráfico de recursos: $analysisDir\system_resources.png"
    }
    Write-Host ""
}

# Função principal
function Main {
    # Mostrar ajuda se solicitado
    if ($Help) {
        Show-Help
        return
    }
    
    # Verificar se WSL está disponível
    if (-not (Test-WSL)) {
        Write-Host "WSL não está disponível!" -ForegroundColor Red
        Write-Host "Instale o WSL para executar os scripts de stress test:" -ForegroundColor Yellow
        Write-Host "  wsl --install"
        Write-Host ""
        Write-Host "Ou execute os scripts diretamente no WSL/Linux" -ForegroundColor Yellow
        return
    }
    
    # Verificar se os nós estão rodando
    if (-not (Test-Nodes)) {
        return
    }
    
    Write-Host "Iniciando stress test completo..." -ForegroundColor Green
    Write-Host ""
    
    # Executar stress test
    Start-StressTest -Duration $Duration -Interval $Interval -Monitor $Monitor -Analyze $Analyze -Cleanup $Cleanup
    
    # Mostrar resultados
    Show-Results
    
    Write-Host "Stress test completo finalizado!" -ForegroundColor Green
}

# Executar função principal
Main 