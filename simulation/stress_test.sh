#!/bin/bash

# Script de Stress Test para a Rede Blockchain NaiveCoin
# Monitora latência, recursos do sistema e performance

set -e

# Configurações
NODES=("localhost:3001" "localhost:3002" "localhost:3003" "localhost:3004" "localhost:3005")
LOG_DIR="./stress_test_logs"
RESULTS_FILE="$LOG_DIR/stress_test_results.json"
LATENCY_LOG="$LOG_DIR/latency.log"
RESOURCES_LOG="$LOG_DIR/resources.log"
PERFORMANCE_LOG="$LOG_DIR/performance.log"

# Criar diretório de logs
mkdir -p "$LOG_DIR"

# Contadores para estatísticas
declare -A operation_counters
declare -A latency_sum
declare -A latency_count
declare -A error_count

# Inicializar contadores
for node in "${NODES[@]}"; do
    operation_counters[$node]=0
    latency_sum[$node]=0
    latency_count[$node]=0
    error_count[$node]=0
done

# Função para log com timestamp
log_message() {
    local level=$1
    local message=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] [$level] $message" | tee -a "$LOG_DIR/stress_test.log"
}

# Função para medir latência de uma operação
measure_latency() {
    local node=$1
    local operation=$2
    local start_time=$(date +%s%3N)
    
    case $operation in
        "blocks")
            response=$(curl -s --max-time 10 "http://$node/blocks")
            ;;
        "balance")
            response=$(curl -s --max-time 10 "http://$node/balance")
            ;;
        "mine")
            response=$(curl -s --max-time 30 -X POST "http://$node/mineBlock")
            ;;
        "peers")
            response=$(curl -s --max-time 10 "http://$node/peers")
            ;;
        *)
            response=""
            ;;
    esac
    
    local end_time=$(date +%s%3N)
    local latency=$((end_time - start_time))
    
    # Verificar se a operação foi bem-sucedida
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        latency_sum[$node]=$((${latency_sum[$node]} + latency))
        latency_count[$node]=$((${latency_count[$node]} + 1))
        operation_counters[$node]=$((${operation_counters[$node]} + 1))
        echo "$(date '+%Y-%m-%d %H:%M:%S.%3N'),$node,$operation,$latency,SUCCESS" >> "$LATENCY_LOG"
    else
        error_count[$node]=$((${error_count[$node]} + 1))
        echo "$(date '+%Y-%m-%d %H:%M:%S.%3N'),$node,$operation,$latency,ERROR" >> "$LATENCY_LOG"
    fi
    
    return $latency
}

# Função para monitorar recursos do sistema
monitor_resources() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # CPU e Memória
    if command -v top >/dev/null 2>&1; then
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        local mem_info=$(free -m | grep Mem)
        local mem_total=$(echo $mem_info | awk '{print $2}')
        local mem_used=$(echo $mem_info | awk '{print $3}')
        local mem_usage=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc -l 2>/dev/null || echo "0")
    else
        local cpu_usage="N/A"
        local mem_usage="N/A"
    fi
    
    # Processos Node.js
    local node_processes=$(ps aux | grep -c "[n]ode" || echo "0")
    
    # Portas em uso
    local ports_in_use=$(netstat -tuln 2>/dev/null | grep -E ":300[1-5]" | wc -l || echo "0")
    
    echo "$timestamp,$cpu_usage,$mem_usage,$node_processes,$ports_in_use" >> "$RESOURCES_LOG"
}

# Função para obter endereço de um nó
get_node_address() {
    local node=$1
    curl -s --max-time 5 "http://$node/address" | grep -o '"address":"[^"]*"' | cut -d'"' -f4
}

# Função para enviar transação com medição de latência
send_transaction_with_latency() {
    local from_node=$1
    local to_address=$2
    local amount=$3
    
    local start_time=$(date +%s%3N)
    
    response=$(curl -s --max-time 30 -X POST -H "Content-Type: application/json" \
        -d "{\"address\":\"$to_address\",\"amount\":$amount}" \
        "http://$from_node/mineTransaction")
    
    local end_time=$(date +%s%3N)
    local latency=$((end_time - start_time))
    
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        latency_sum[$from_node]=$((${latency_sum[$from_node]} + latency))
        latency_count[$from_node]=$((${latency_count[$from_node]} + 1))
        operation_counters[$from_node]=$((${operation_counters[$from_node]} + 1))
        echo "$(date '+%Y-%m-%d %H:%M:%S.%3N'),$from_node,transaction,$latency,SUCCESS" >> "$LATENCY_LOG"
        log_message "INFO" "Transação enviada: $from_node -> $to_address ($amount coins) - Latência: ${latency}ms"
    else
        error_count[$from_node]=$((${error_count[$from_node]} + 1))
        echo "$(date '+%Y-%m-%d %H:%M:%S.%3N'),$from_node,transaction,$latency,ERROR" >> "$LATENCY_LOG"
        log_message "ERROR" "Erro ao enviar transação: $from_node -> $to_address ($amount coins)"
    fi
}

# Função para calcular estatísticas
calculate_statistics() {
    echo "=== ESTATÍSTICAS DE PERFORMANCE ==="
    echo ""
    
    for node in "${NODES[@]}"; do
        local total_ops=${operation_counters[$node]}
        local total_errors=${error_count[$node]}
        local total_latency=${latency_sum[$node]}
        local latency_count_val=${latency_count[$node]}
        
        if [ $latency_count_val -gt 0 ]; then
            local avg_latency=$((total_latency / latency_count_val))
            local success_rate=$(echo "scale=2; ($total_ops - $total_errors) * 100 / $total_ops" | bc -l 2>/dev/null || echo "0")
        else
            local avg_latency=0
            local success_rate=0
        fi
        
        echo "Nó: $node"
        echo "  Operações totais: $total_ops"
        echo "  Erros: $total_errors"
        echo "  Taxa de sucesso: ${success_rate}%"
        echo "  Latência média: ${avg_latency}ms"
        echo ""
        
        # Salvar no arquivo de performance
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$node,$total_ops,$total_errors,$success_rate,$avg_latency" >> "$PERFORMANCE_LOG"
    done
}

# Função para gerar relatório final
generate_report() {
    local report_file="$LOG_DIR/stress_test_report.txt"
    
    {
        echo "=== RELATÓRIO DE STRESS TEST ==="
        echo "Data/Hora: $(date)"
        echo "Duração: $1 segundos"
        echo ""
        echo "=== RESUMO EXECUTIVO ==="
        
        local total_operations=0
        local total_errors=0
        
        for node in "${NODES[@]}"; do
            total_operations=$((total_operations + ${operation_counters[$node]}))
            total_errors=$((total_errors + ${error_count[$node]}))
        done
        
        local overall_success_rate=$(echo "scale=2; ($total_operations - $total_errors) * 100 / $total_operations" | bc -l 2>/dev/null || echo "0")
        
        echo "Total de operações: $total_operations"
        echo "Total de erros: $total_errors"
        echo "Taxa de sucesso geral: ${overall_success_rate}%"
        echo ""
        
        echo "=== DETALHES POR NÓ ==="
        for node in "${NODES[@]}"; do
            local total_ops=${operation_counters[$node]}
            local total_errors=${error_count[$node]}
            local total_latency=${latency_sum[$node]}
            local latency_count_val=${latency_count[$node]}
            
            if [ $latency_count_val -gt 0 ]; then
                local avg_latency=$((total_latency / latency_count_val))
                local success_rate=$(echo "scale=2; ($total_ops - $total_errors) * 100 / $total_ops" | bc -l 2>/dev/null || echo "0")
            else
                local avg_latency=0
                local success_rate=0
            fi
            
            echo "Nó: $node"
            echo "  Operações: $total_ops"
            echo "  Erros: $total_errors"
            echo "  Taxa de sucesso: ${success_rate}%"
            echo "  Latência média: ${avg_latency}ms"
            echo ""
        done
        
        echo "=== ARQUIVOS DE LOG ==="
        echo "Log principal: $LOG_DIR/stress_test.log"
        echo "Log de latência: $LATENCY_LOG"
        echo "Log de recursos: $RESOURCES_LOG"
        echo "Log de performance: $PERFORMANCE_LOG"
        echo "Relatório: $report_file"
        
    } > "$report_file"
    
    log_message "INFO" "Relatório gerado: $report_file"
}

# Função principal de stress test
run_stress_test() {
    local duration=$1
    local interval=$2
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    log_message "INFO" "Iniciando stress test por $duration segundos com intervalo de $interval segundos"
    log_message "INFO" "Logs serão salvos em: $LOG_DIR"
    
    # Inicializar arquivos de log
    echo "timestamp,node,operation,latency_ms,status" > "$LATENCY_LOG"
    echo "timestamp,cpu_usage,memory_usage,node_processes,ports_in_use" > "$RESOURCES_LOG"
    echo "timestamp,node,total_operations,errors,success_rate,avg_latency_ms" > "$PERFORMANCE_LOG"
    
    # Aguardar nós ficarem online
    log_message "INFO" "Aguardando nós ficarem online..."
    for node in "${NODES[@]}"; do
        while ! curl -s --max-time 5 "http://$node/blocks" > /dev/null; do
            log_message "INFO" "Aguardando nó $node..."
            sleep 2
        done
        log_message "INFO" "Nó $node está online!"
    done
    
    # Coletar endereços dos nós
    declare -A NODE_ADDRESSES
    for node in "${NODES[@]}"; do
        address=$(get_node_address "$node")
        NODE_ADDRESSES[$node]=$address
        log_message "INFO" "Nó $node: $address"
    done
    
    # Loop principal do stress test
    while [ $(date +%s) -lt $end_time ]; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        log_message "INFO" "Executando ciclo de stress test (${elapsed}s/${duration}s)"
        
        # Monitorar recursos
        monitor_resources
        
        # Operações de leitura (baixa latência esperada)
        for node in "${NODES[@]}"; do
            measure_latency "$node" "blocks" &
            measure_latency "$node" "balance" &
            measure_latency "$node" "peers" &
        done
        wait
        
        # Operações de mineração (alta latência esperada)
        for node in "${NODES[@]}"; do
            measure_latency "$node" "mine" &
        done
        wait
        
        # Transações entre nós
        for i in "${!NODES[@]}"; do
            local from_node=${NODES[$i]}
            local next_index=$(((i + 1) % ${#NODES[@]}))
            local to_node=${NODES[$next_index]}
            local to_address=${NODE_ADDRESSES[$to_node]}
            
            if [ ! -z "$to_address" ]; then
                local amount=$((RANDOM % 10 + 1))
                send_transaction_with_latency "$from_node" "$to_address" "$amount" &
            fi
        done
        wait
        
        # Mostrar estatísticas parciais a cada 30 segundos
        if [ $((elapsed % 30)) -eq 0 ]; then
            calculate_statistics
        fi
        
        sleep $interval
    done
    
    local total_duration=$((end_time - start_time))
    log_message "INFO" "Stress test concluído após $total_duration segundos"
    
    # Gerar relatório final
    calculate_statistics
    generate_report $total_duration
    
    log_message "INFO" "Stress test finalizado. Verifique os logs em $LOG_DIR"
}

# Função para mostrar ajuda
show_help() {
    echo "=== Stress Test para Rede Blockchain NaiveCoin ==="
    echo ""
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  -d, --duration SECONDS    Duração do teste em segundos (padrão: 300)"
    echo "  -i, --interval SECONDS    Intervalo entre operações (padrão: 5)"
    echo "  -h, --help               Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 -d 600 -i 3          # 10 minutos com intervalo de 3s"
    echo "  $0 --duration 1800      # 30 minutos"
    echo ""
}

# Função para limpar logs antigos
cleanup_old_logs() {
    if [ -d "$LOG_DIR" ]; then
        log_message "INFO" "Limpando logs antigos..."
        find "$LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null || true
    fi
}

# Função para capturar sinais e fazer cleanup
cleanup() {
    log_message "INFO" "Interrompendo stress test..."
    calculate_statistics
    generate_report $(($(date +%s) - start_time))
    exit 0
}

# Configurar trap para capturar Ctrl+C
trap cleanup SIGINT SIGTERM

# Parse de argumentos
DURATION=300
INTERVAL=5

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
    echo "Erro: Duração deve ser um número positivo"
    exit 1
fi

if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 1 ]; then
    echo "Erro: Intervalo deve ser um número positivo"
    exit 1
fi

# Iniciar stress test
cleanup_old_logs
start_time=$(date +%s)
run_stress_test $DURATION $INTERVAL 