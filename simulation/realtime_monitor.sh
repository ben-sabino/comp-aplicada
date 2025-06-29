#!/bin/bash

# Script de monitoramento em tempo real para a rede blockchain
# Mostra métricas de performance, latência e recursos do sistema

set -e

# Configurações
NODES=("localhost:3001" "localhost:3002" "localhost:3003" "localhost:3004" "localhost:3005")
LOG_FILE="./realtime_monitor.log"
UPDATE_INTERVAL=2

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para limpar tela
clear_screen() {
    clear
    echo -e "${CYAN}=== MONITORAMENTO EM TEMPO REAL - NAIVECOIN ===${NC}"
    echo -e "Atualizado em: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "Pressione Ctrl+C para sair"
    echo ""
}

# Função para medir latência de uma operação
measure_latency() {
    local node=$1
    local operation=$2
    local start_time=$(date +%s%3N)
    
    case $operation in
        "blocks")
            response=$(curl -s --max-time 3 "http://$node/blocks" 2>/dev/null)
            ;;
        "balance")
            response=$(curl -s --max-time 3 "http://$node/balance" 2>/dev/null)
            ;;
        *)
            response=""
            ;;
    esac
    
    local end_time=$(date +%s%3N)
    local latency=$((end_time - start_time))
    
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        echo "SUCCESS:$latency"
    else
        echo "ERROR:$latency"
    fi
}

# Função para obter informações de um nó
get_node_info() {
    local node=$1
    local node_num=$2
    
    # Verificar se o nó está online
    local blocks_response=$(curl -s --max-time 2 "http://$node/blocks" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$blocks_response" ]; then
        echo -e "${RED}Nó $node_num ($node): OFFLINE${NC}"
        return
    fi
    
    # Obter informações básicas
    local address=$(curl -s --max-time 2 "http://$node/address" 2>/dev/null | grep -o '"address":"[^"]*"' | cut -d'"' -f4)
    local balance=$(curl -s --max-time 2 "http://$node/balance" 2>/dev/null | grep -o '"balance":[0-9]*' | cut -d':' -f2)
    local blocks=$(echo "$blocks_response" | grep -o '"index":[0-9]*' | wc -l)
    local peers_raw=$(curl -s --max-time 2 "http://$node/peers" 2>/dev/null)
    local peers=$(echo "$peers_raw" | grep -o ',' | wc -l)
    if [ ! -z "$peers_raw" ] && [ "$peers_raw" != "[]" ]; then
        peers=$((peers + 1))
    else
        peers=0
    fi
    
    # Medir latência
    local blocks_latency=$(measure_latency "$node" "blocks")
    local balance_latency=$(measure_latency "$node" "balance")
    
    local blocks_status=$(echo "$blocks_latency" | cut -d':' -f1)
    local blocks_time=$(echo "$blocks_latency" | cut -d':' -f2)
    local balance_status=$(echo "$balance_latency" | cut -d':' -f1)
    local balance_time=$(echo "$balance_latency" | cut -d':' -f2)
    
    # Determinar cor baseada na latência
    local blocks_color=$GREEN
    local balance_color=$GREEN
    
    if [ "$blocks_time" -gt 1000 ]; then
        blocks_color=$RED
    elif [ "$blocks_time" -gt 500 ]; then
        blocks_color=$YELLOW
    fi
    
    if [ "$balance_time" -gt 1000 ]; then
        balance_color=$RED
    elif [ "$balance_time" -gt 500 ]; then
        balance_color=$YELLOW
    fi
    
    # Mostrar informações do nó
    echo -e "${GREEN}Nó $node_num ($node): ONLINE${NC}"
    echo -e "  ${BLUE}Endereço:${NC} ${address:-'N/A'}"
    echo -e "  ${BLUE}Saldo:${NC} ${balance:-0} coins"
    echo -e "  ${BLUE}Blocos:${NC} $blocks"
    echo -e "  ${BLUE}Peers:${NC} $peers"
    echo -e "  ${BLUE}Latência:${NC} Blocks: ${blocks_color}${blocks_time}ms${NC}, Balance: ${balance_color}${balance_time}ms${NC}"
    echo ""
}

# Função para obter recursos do sistema
get_system_resources() {
    echo -e "${PURPLE}=== RECURSOS DO SISTEMA ===${NC}"
    
    # CPU
    if command -v top >/dev/null 2>&1; then
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        local cpu_color=$GREEN
        if (( $(echo "$cpu_usage > 80" | bc -l) )); then
            cpu_color=$RED
        elif (( $(echo "$cpu_usage > 60" | bc -l) )); then
            cpu_color=$YELLOW
        fi
        echo -e "  ${BLUE}CPU:${NC} ${cpu_color}${cpu_usage}%${NC}"
    fi
    
    # Memória
    if command -v free >/dev/null 2>&1; then
        local mem_info=$(free -m | grep Mem)
        local mem_total=$(echo $mem_info | awk '{print $2}')
        local mem_used=$(echo $mem_info | awk '{print $3}')
        local mem_usage=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc -l 2>/dev/null || echo "0")
        local mem_color=$GREEN
        if (( $(echo "$mem_usage > 80" | bc -l) )); then
            mem_color=$RED
        elif (( $(echo "$mem_usage > 60" | bc -l) )); then
            mem_color=$YELLOW
        fi
        echo -e "  ${BLUE}Memória:${NC} ${mem_color}${mem_usage}%${NC} (${mem_used}MB/${mem_total}MB)"
    fi
    
    # Processos Node.js
    local node_processes=$(ps aux | grep -c "[n]ode" || echo "0")
    echo -e "  ${BLUE}Processos Node.js:${NC} $node_processes"
    
    # Portas em uso
    local ports_in_use=$(netstat -tuln 2>/dev/null | grep -E ":300[1-5]" | wc -l || echo "0")
    echo -e "  ${BLUE}Portas blockchain:${NC} $ports_in_use/5"
    echo ""
}

# Função para mostrar estatísticas de rede
show_network_stats() {
    echo -e "${PURPLE}=== ESTATÍSTICAS DE REDE ===${NC}"
    
    local total_blocks=0
    local total_balance=0
    local online_nodes=0
    
    for node in "${NODES[@]}"; do
        local blocks_response=$(curl -s --max-time 2 "http://$node/blocks" 2>/dev/null)
        if [ $? -eq 0 ] && [ ! -z "$blocks_response" ]; then
            local blocks=$(echo "$blocks_response" | grep -o '"index":[0-9]*' | wc -l)
            local balance=$(curl -s --max-time 2 "http://$node/balance" 2>/dev/null | grep -o '"balance":[0-9]*' | cut -d':' -f2)
            
            total_blocks=$((total_blocks + blocks))
            total_balance=$((total_balance + balance))
            online_nodes=$((online_nodes + 1))
        fi
    done
    
    echo -e "  ${BLUE}Nós online:${NC} $online_nodes/${#NODES[@]}"
    echo -e "  ${BLUE}Total de blocos:${NC} $total_blocks"
    echo -e "  ${BLUE}Total de coins:${NC} $total_balance"
    echo ""
}

# Função para mostrar pool de transações
show_transaction_pool() {
    echo -e "${PURPLE}=== POOL DE TRANSAÇÕES ===${NC}"
    
    local total_transactions=0
    
    for node in "${NODES[@]}"; do
        local tx_pool=$(curl -s --max-time 2 "http://$node/transactionPool" 2>/dev/null)
        if [ $? -eq 0 ] && [ ! -z "$tx_pool" ] && [ "$tx_pool" != "[]" ]; then
            local tx_count=$(echo "$tx_pool" | grep -o '"id"' | wc -l)
            total_transactions=$((total_transactions + tx_count))
        fi
    done
    
    if [ $total_transactions -gt 0 ]; then
        echo -e "  ${YELLOW}Transações pendentes:${NC} $total_transactions"
    else
        echo -e "  ${GREEN}Nenhuma transação pendente${NC}"
    fi
    echo ""
}

# Função para mostrar últimas transações
show_recent_transactions() {
    echo -e "${PURPLE}=== ÚLTIMAS TRANSAÇÕES ===${NC}"
    
    # Obter últimos blocos do nó 1
    local latest_blocks=$(curl -s --max-time 3 "http://localhost:3001/blocks" 2>/dev/null)
    if [ ! -z "$latest_blocks" ]; then
        local recent_txs=$(echo "$latest_blocks" | grep -A 5 -B 5 '"transactions"' | tail -10)
        if [ ! -z "$recent_txs" ]; then
            echo "$recent_txs" | grep -E '"fromAddress"|"toAddress"|"amount"' | head -6
        else
            echo -e "  ${BLUE}Nenhuma transação recente${NC}"
        fi
    else
        echo -e "  ${RED}Não foi possível obter transações${NC}"
    fi
    echo ""
}

# Função para log de eventos
log_event() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

# Função para capturar sinais e fazer cleanup
cleanup() {
    echo ""
    echo -e "${YELLOW}Monitoramento interrompido.${NC}"
    log_event "Monitoramento interrompido pelo usuário"
    exit 0
}

# Configurar trap para capturar Ctrl+C
trap cleanup SIGINT SIGTERM

# Função principal de monitoramento
run_monitor() {
    log_event "Iniciando monitoramento em tempo real"
    
    while true; do
        clear_screen
        
        # Mostrar recursos do sistema
        get_system_resources
        
        # Mostrar estatísticas de rede
        show_network_stats
        
        # Mostrar informações de cada nó
        echo -e "${PURPLE}=== STATUS DOS NÓS ===${NC}"
        for i in "${!NODES[@]}"; do
            get_node_info "${NODES[$i]}" $((i + 1))
        done
        
        # Mostrar pool de transações
        show_transaction_pool
        
        # Mostrar últimas transações
        show_recent_transactions
        
        # Aguardar próxima atualização
        sleep $UPDATE_INTERVAL
    done
}

# Função para mostrar ajuda
show_help() {
    echo "=== Monitoramento em Tempo Real - NaiveCoin ==="
    echo ""
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  -i, --interval SECONDS    Intervalo de atualização (padrão: 2)"
    echo "  -l, --log FILE            Arquivo de log (padrão: ./realtime_monitor.log)"
    echo "  -h, --help                Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 -i 1                   # Atualização a cada segundo"
    echo "  $0 --log monitor.log      # Log personalizado"
    echo ""
}

# Parse de argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interval)
            UPDATE_INTERVAL="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
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
if ! [[ "$UPDATE_INTERVAL" =~ ^[0-9]+$ ]] || [ "$UPDATE_INTERVAL" -lt 1 ]; then
    echo "Erro: Intervalo deve ser um número positivo"
    exit 1
fi

# Verificar se os nós estão disponíveis
echo -e "${CYAN}Verificando conectividade com os nós...${NC}"
for node in "${NODES[@]}"; do
    if curl -s --max-time 2 "http://$node/blocks" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $node está online${NC}"
    else
        echo -e "${RED}✗ $node está offline${NC}"
    fi
done
echo ""

# Iniciar monitoramento
run_monitor 