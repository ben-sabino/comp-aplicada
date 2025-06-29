#!/bin/bash

# Script principal para executar stress test completo
# Coordena stress test, monitoramento e análise

set -e

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STRESS_TEST_SCRIPT="$SCRIPT_DIR/stress_test.sh"
MONITOR_SCRIPT="$SCRIPT_DIR/realtime_monitor.sh"
ANALYSIS_SCRIPT="$SCRIPT_DIR/analyze_stress_test.sh"
LOG_DIR="./stress_test_logs"
ANALYSIS_DIR="./stress_test_analysis"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    STRESS TEST COMPLETO                      ║"
    echo "║                        NAIVECOIN                             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Função para verificar dependências
check_dependencies() {
    echo -e "${BLUE}Verificando dependências...${NC}"
    
    local missing_deps=()
    
    # Verificar curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    # Verificar bc (para cálculos)
    if ! command -v bc >/dev/null 2>&1; then
        missing_deps+=("bc")
    fi
    
    # Verificar netstat
    if ! command -v netstat >/dev/null 2>&1; then
        missing_deps+=("net-tools")
    fi
    
    # Verificar scripts
    if [ ! -f "$STRESS_TEST_SCRIPT" ]; then
        missing_deps+=("stress_test.sh")
    fi
    
    if [ ! -f "$MONITOR_SCRIPT" ]; then
        missing_deps+=("realtime_monitor.sh")
    fi
    
    if [ ! -f "$ANALYSIS_SCRIPT" ]; then
        missing_deps+=("analyze_stress_test.sh")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Dependências faltando:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  - $dep"
        done
        echo ""
        echo -e "${YELLOW}Para instalar no Ubuntu/Debian:${NC}"
        echo "  sudo apt-get update && sudo apt-get install curl bc net-tools"
        echo ""
        echo -e "${YELLOW}Para instalar no CentOS/RHEL:${NC}"
        echo "  sudo yum install curl bc net-tools"
        echo ""
        return 1
    fi
    
    echo -e "${GREEN}✓ Todas as dependências estão disponíveis${NC}"
    return 0
}

# Função para verificar se os nós estão rodando
check_nodes() {
    echo -e "${BLUE}Verificando se os nós estão rodando...${NC}"
    
    local nodes=("localhost:3001" "localhost:3002" "localhost:3003" "localhost:3004" "localhost:3005")
    local online_count=0
    
    for node in "${nodes[@]}"; do
        if curl -s --max-time 3 "http://$node/blocks" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓ $node está online${NC}"
            online_count=$((online_count + 1))
        else
            echo -e "  ${RED}✗ $node está offline${NC}"
        fi
    done
    
    if [ $online_count -eq 0 ]; then
        echo -e "${RED}Nenhum nó está rodando!${NC}"
        echo -e "${YELLOW}Inicie os nós primeiro:${NC}"
        echo "  cd .. && ./blockchain.ps1"
        echo "  ou"
        echo "  cd .. && docker-compose up -d"
        return 1
    elif [ $online_count -lt ${#nodes[@]} ]; then
        echo -e "${YELLOW}Apenas $online_count de ${#nodes[@]} nós estão online${NC}"
        echo -e "${YELLOW}Recomendado: iniciar todos os nós para melhor teste${NC}"
    else
        echo -e "${GREEN}✓ Todos os nós estão online${NC}"
    fi
    
    return 0
}

# Função para executar stress test
run_stress_test() {
    local duration=$1
    local interval=$2
    
    echo -e "${BLUE}Iniciando stress test...${NC}"
    echo -e "  Duração: $duration segundos"
    echo -e "  Intervalo: $interval segundos"
    echo ""
    
    # Executar stress test em background
    "$STRESS_TEST_SCRIPT" -d "$duration" -i "$interval" &
    local stress_pid=$!
    
    echo -e "${GREEN}Stress test iniciado (PID: $stress_pid)${NC}"
    echo -e "${YELLOW}Pressione Ctrl+C para interromper${NC}"
    echo ""
    
    # Aguardar stress test terminar
    wait $stress_pid
    
    echo -e "${GREEN}Stress test concluído!${NC}"
}

# Função para executar monitoramento em paralelo
run_monitoring() {
    local duration=$1
    
    echo -e "${BLUE}Iniciando monitoramento em tempo real...${NC}"
    
    # Executar monitor em background
    "$MONITOR_SCRIPT" -i 1 &
    local monitor_pid=$!
    
    echo -e "${GREEN}Monitor iniciado (PID: $monitor_pid)${NC}"
    
    # Aguardar duração do teste
    sleep $duration
    
    # Parar monitor
    kill $monitor_pid 2>/dev/null || true
    echo -e "${GREEN}Monitor parado${NC}"
}

# Função para executar análise
run_analysis() {
    echo -e "${BLUE}Executando análise dos resultados...${NC}"
    
    # Aguardar um pouco para garantir que os logs foram escritos
    sleep 5
    
    # Executar análise completa
    "$ANALYSIS_SCRIPT" -a
    
    echo -e "${GREEN}Análise concluída!${NC}"
}

# Função para mostrar resultados
show_results() {
    echo -e "${CYAN}=== RESULTADOS DO STRESS TEST ===${NC}"
    echo ""
    
    if [ -f "$LOG_DIR/stress_test_report.txt" ]; then
        echo -e "${BLUE}Relatório de texto:${NC}"
        cat "$LOG_DIR/stress_test_report.txt"
        echo ""
    fi
    
    if [ -f "$ANALYSIS_DIR/stress_test_report.html" ]; then
        echo -e "${BLUE}Relatório HTML:${NC} $ANALYSIS_DIR/stress_test_report.html"
        echo ""
    fi
    
    echo -e "${BLUE}Arquivos de log:${NC}"
    echo "  - Log principal: $LOG_DIR/stress_test.log"
    echo "  - Log de latência: $LOG_DIR/latency.log"
    echo "  - Log de recursos: $LOG_DIR/resources.log"
    echo "  - Log de performance: $LOG_DIR/performance.log"
    echo ""
    
    echo -e "${BLUE}Arquivos de análise:${NC}"
    echo "  - Diretório: $ANALYSIS_DIR/"
    if [ -f "$ANALYSIS_DIR/latency_over_time.png" ]; then
        echo "  - Gráfico de latência: $ANALYSIS_DIR/latency_over_time.png"
    fi
    if [ -f "$ANALYSIS_DIR/system_resources.png" ]; then
        echo "  - Gráfico de recursos: $ANALYSIS_DIR/system_resources.png"
    fi
    echo ""
}

# Função para limpar logs antigos
cleanup_old_logs() {
    echo -e "${BLUE}Limpando logs antigos...${NC}"
    
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null || true
        echo -e "${GREEN}Logs antigos removidos${NC}"
    fi
}

# Função para capturar sinais e fazer cleanup
cleanup() {
    echo ""
    echo -e "${YELLOW}Interrompendo stress test...${NC}"
    
    # Parar processos em background
    pkill -f "stress_test.sh" 2>/dev/null || true
    pkill -f "realtime_monitor.sh" 2>/dev/null || true
    
    echo -e "${GREEN}Processos parados${NC}"
    exit 0
}

# Configurar trap para capturar Ctrl+C
trap cleanup SIGINT SIGTERM

# Função para mostrar ajuda
show_help() {
    echo "=== Stress Test Completo - NaiveCoin ==="
    echo ""
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  -d, --duration SECONDS    Duração do teste (padrão: 300)"
    echo "  -i, --interval SECONDS    Intervalo entre operações (padrão: 5)"
    echo "  -m, --monitor             Executar monitoramento em paralelo"
    echo "  -a, --analyze             Executar análise após o teste"
    echo "  -c, --cleanup             Limpar logs antigos antes do teste"
    echo "  -h, --help                Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 -d 600 -i 3 -m -a     # 10 min, intervalo 3s, com monitor e análise"
    echo "  $0 --duration 1800       # 30 minutos"
    echo "  $0 -m                    # Com monitoramento em tempo real"
    echo ""
}

# Parse de argumentos
DURATION=300
INTERVAL=5
RUN_MONITOR=false
RUN_ANALYSIS=false
CLEANUP_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -m|--monitor)
            RUN_MONITOR=true
            shift
            ;;
        -a|--analyze)
            RUN_ANALYSIS=true
            shift
            ;;
        -c|--cleanup)
            CLEANUP_LOGS=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validar parâmetros
if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 1 ]; then
    echo -e "${RED}Erro: Duração deve ser um número positivo${NC}"
    exit 1
fi

if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 1 ]; then
    echo -e "${RED}Erro: Intervalo deve ser um número positivo${NC}"
    exit 1
fi

# Mostrar banner
show_banner

# Verificar dependências
if ! check_dependencies; then
    exit 1
fi

# Verificar nós
if ! check_nodes; then
    exit 1
fi

# Limpar logs antigos se solicitado
if [ "$CLEANUP_LOGS" = true ]; then
    cleanup_old_logs
fi

echo -e "${GREEN}Iniciando stress test completo...${NC}"
echo ""

# Executar stress test
if [ "$RUN_MONITOR" = true ]; then
    # Executar monitoramento em paralelo
    run_monitoring $DURATION &
    local monitor_pid=$!
    
    # Executar stress test
    run_stress_test $DURATION $INTERVAL
    
    # Aguardar monitor terminar
    wait $monitor_pid
else
    # Executar apenas stress test
    run_stress_test $DURATION $INTERVAL
fi

# Executar análise se solicitado
if [ "$RUN_ANALYSIS" = true ]; then
    run_analysis
fi

# Mostrar resultados
show_results

echo -e "${GREEN}Stress test completo finalizado!${NC}" 