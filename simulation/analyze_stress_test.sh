#!/bin/bash

# Script para analisar os resultados do stress test
# Gera gráficos e relatórios detalhados de performance

set -e

# Configurações
LOG_DIR="./stress_test_logs"
ANALYSIS_DIR="./stress_test_analysis"
LATENCY_LOG="$LOG_DIR/latency.log"
RESOURCES_LOG="$LOG_DIR/resources.log"
PERFORMANCE_LOG="$LOG_DIR/performance.log"

# Criar diretório de análise
mkdir -p "$ANALYSIS_DIR"

# Função para verificar se os arquivos de log existem
check_logs() {
    if [ ! -f "$LATENCY_LOG" ]; then
        echo "Erro: Arquivo de latência não encontrado: $LATENCY_LOG"
        echo "Execute o stress test primeiro: ./stress_test.sh"
        exit 1
    fi
    
    if [ ! -f "$RESOURCES_LOG" ]; then
        echo "Erro: Arquivo de recursos não encontrado: $RESOURCES_LOG"
        exit 1
    fi
    
    if [ ! -f "$PERFORMANCE_LOG" ]; then
        echo "Erro: Arquivo de performance não encontrado: $PERFORMANCE_LOG"
        exit 1
    fi
}

# Função para gerar estatísticas de latência
analyze_latency() {
    echo "=== ANÁLISE DE LATÊNCIA ==="
    echo ""
    
    # Remover cabeçalho e analisar dados
    tail -n +2 "$LATENCY_LOG" > "$ANALYSIS_DIR/latency_data.csv"
    
    # Estatísticas por operação
    echo "Latência por tipo de operação:"
    echo "Operação | Média | Mín | Máx | Total"
    echo "---------|-------|-----|-----|------"
    
    for operation in "blocks" "balance" "mine" "peers" "transaction"; do
        if grep -q ",$operation," "$ANALYSIS_DIR/latency_data.csv"; then
            local avg=$(awk -F',' "\$3 == \"$operation\" {sum+=\$4; count++} END {if(count>0) printf \"%.2f\", sum/count}" "$ANALYSIS_DIR/latency_data.csv")
            local min=$(awk -F',' "\$3 == \"$operation\" {if(min==\"\" || \$4<min) min=\$4} END {print min}" "$ANALYSIS_DIR/latency_data.csv")
            local max=$(awk -F',' "\$3 == \"$operation\" {if(\$4>max) max=\$4} END {print max}" "$ANALYSIS_DIR/latency_data.csv")
            local total=$(grep -c ",$operation," "$ANALYSIS_DIR/latency_data.csv")
            
            printf "%-9s | %5s | %3s | %3s | %5s\n" "$operation" "$avg" "$min" "$max" "$total"
        fi
    done
    echo ""
    
    # Estatísticas por nó
    echo "Latência por nó:"
    echo "Nó | Média | Mín | Máx | Total"
    echo "---|-------|-----|-----|------"
    
    for node in "localhost:3001" "localhost:3002" "localhost:3003" "localhost:3004" "localhost:3005"; do
        if grep -q ",$node," "$ANALYSIS_DIR/latency_data.csv"; then
            local avg=$(awk -F',' "\$2 == \"$node\" {sum+=\$4; count++} END {if(count>0) printf \"%.2f\", sum/count}" "$ANALYSIS_DIR/latency_data.csv")
            local min=$(awk -F',' "\$2 == \"$node\" {if(min==\"\" || \$4<min) min=\$4} END {print min}" "$ANALYSIS_DIR/latency_data.csv")
            local max=$(awk -F',' "\$2 == \"$node\" {if(\$4>max) max=\$4} END {print max}" "$ANALYSIS_DIR/latency_data.csv")
            local total=$(grep -c ",$node," "$ANALYSIS_DIR/latency_data.csv")
            
            printf "%-13s | %5s | %3s | %3s | %5s\n" "$node" "$avg" "$min" "$max" "$total"
        fi
    done
    echo ""
    
    # Taxa de sucesso
    local total_ops=$(tail -n +2 "$LATENCY_LOG" | wc -l)
    local successful_ops=$(grep -c "SUCCESS" "$LATENCY_LOG")
    local error_ops=$(grep -c "ERROR" "$LATENCY_LOG")
    local success_rate=$(echo "scale=2; $successful_ops * 100 / $total_ops" | bc -l 2>/dev/null || echo "0")
    
    echo "Taxa de sucesso geral: ${success_rate}%"
    echo "Operações bem-sucedidas: $successful_ops"
    echo "Operações com erro: $error_ops"
    echo "Total de operações: $total_ops"
    echo ""
}

# Função para analisar recursos do sistema
analyze_resources() {
    echo "=== ANÁLISE DE RECURSOS DO SISTEMA ==="
    echo ""
    
    # Remover cabeçalho e analisar dados
    tail -n +2 "$RESOURCES_LOG" > "$ANALYSIS_DIR/resources_data.csv"
    
    # Estatísticas de CPU
    if command -v bc >/dev/null 2>&1; then
        local cpu_avg=$(awk -F',' '$2 != "N/A" {sum+=$2; count++} END {if(count>0) printf "%.2f", sum/count}' "$ANALYSIS_DIR/resources_data.csv")
        local cpu_max=$(awk -F',' '$2 != "N/A" {if($2>max) max=$2} END {print max}' "$ANALYSIS_DIR/resources_data.csv")
        local cpu_min=$(awk -F',' '$2 != "N/A" {if(min=="" || $2<min) min=$2} END {print min}' "$ANALYSIS_DIR/resources_data.csv")
        
        echo "CPU:"
        echo "  Média: ${cpu_avg}%"
        echo "  Máxima: ${cpu_max}%"
        echo "  Mínima: ${cpu_min}%"
        echo ""
    fi
    
    # Estatísticas de memória
    if command -v bc >/dev/null 2>&1; then
        local mem_avg=$(awk -F',' '$3 != "N/A" {sum+=$3; count++} END {if(count>0) printf "%.2f", sum/count}' "$ANALYSIS_DIR/resources_data.csv")
        local mem_max=$(awk -F',' '$3 != "N/A" {if($3>max) max=$3} END {print max}' "$ANALYSIS_DIR/resources_data.csv")
        local mem_min=$(awk -F',' '$3 != "N/A" {if(min=="" || $3<min) min=$3} END {print min}' "$ANALYSIS_DIR/resources_data.csv")
        
        echo "Memória:"
        echo "  Média: ${mem_avg}%"
        echo "  Máxima: ${mem_max}%"
        echo "  Mínima: ${mem_min}%"
        echo ""
    fi
    
    # Processos Node.js
    local node_avg=$(awk -F',' '{sum+=$4; count++} END {if(count>0) printf "%.2f", sum/count}' "$ANALYSIS_DIR/resources_data.csv")
    local node_max=$(awk -F',' '{if($4>max) max=$4} END {print max}' "$ANALYSIS_DIR/resources_data.csv")
    local node_min=$(awk -F',' '{if(min=="" || $4<min) min=$4} END {print min}' "$ANALYSIS_DIR/resources_data.csv")
    
    echo "Processos Node.js:"
    echo "  Média: ${node_avg}"
    echo "  Máximo: ${node_max}"
    echo "  Mínimo: ${node_min}"
    echo ""
    
    # Portas em uso
    local ports_avg=$(awk -F',' '{sum+=$5; count++} END {if(count>0) printf "%.2f", sum/count}' "$ANALYSIS_DIR/resources_data.csv")
    local ports_max=$(awk -F',' '{if($5>max) max=$5} END {print max}' "$ANALYSIS_DIR/resources_data.csv")
    local ports_min=$(awk -F',' '{if(min=="" || $5<min) min=$5} END {print min}' "$ANALYSIS_DIR/resources_data.csv")
    
    echo "Portas em uso:"
    echo "  Média: ${ports_avg}"
    echo "  Máximo: ${ports_max}"
    echo "  Mínimo: ${ports_min}"
    echo ""
}

# Função para gerar gráficos (se gnuplot estiver disponível)
generate_graphs() {
    if ! command -v gnuplot >/dev/null 2>&1; then
        echo "Gnuplot não encontrado. Pulando geração de gráficos."
        echo "Instale gnuplot para gerar gráficos: sudo apt-get install gnuplot"
        return
    fi
    
    echo "Gerando gráficos..."
    
    # Gráfico de latência ao longo do tempo
    cat > "$ANALYSIS_DIR/latency_plot.gp" << 'EOF'
set terminal png size 1200,800
set output 'latency_over_time.png'
set title 'Latência das Operações ao Longo do Tempo'
set xlabel 'Tempo'
set ylabel 'Latência (ms)'
set grid
set key outside

# Converter timestamp para segundos desde o início
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M:%S"

plot 'latency_data.csv' using 1:4 with points title 'Latência', \
     'latency_data.csv' using 1:4 smooth bezier title 'Tendência'
EOF

    # Gráfico de recursos do sistema
    cat > "$ANALYSIS_DIR/resources_plot.gp" << 'EOF'
set terminal png size 1200,800
set output 'system_resources.png'
set title 'Uso de Recursos do Sistema'
set xlabel 'Tempo'
set ylabel 'Uso (%)'
set grid
set key outside

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M:%S"

plot 'resources_data.csv' using 1:2 with lines title 'CPU (%)', \
     'resources_data.csv' using 1:3 with lines title 'Memória (%)'
EOF

    # Executar gnuplot
    cd "$ANALYSIS_DIR"
    gnuplot latency_plot.gp 2>/dev/null || echo "Erro ao gerar gráfico de latência"
    gnuplot resources_plot.gp 2>/dev/null || echo "Erro ao gerar gráfico de recursos"
    cd - > /dev/null
    
    echo "Gráficos gerados em $ANALYSIS_DIR/"
}

# Função para gerar relatório HTML
generate_html_report() {
    local html_file="$ANALYSIS_DIR/stress_test_report.html"
    
    cat > "$html_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Relatório de Stress Test - NaiveCoin</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .metric { display: inline-block; margin: 10px; padding: 10px; background-color: #e8f4f8; border-radius: 3px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Relatório de Stress Test - NaiveCoin</h1>
        <p>Data/Hora: $(date)</p>
    </div>
EOF

    # Adicionar estatísticas de latência
    {
        echo "    <div class='section'>"
        echo "        <h2>Estatísticas de Latência</h2>"
        echo "        <table>"
        echo "            <tr><th>Nó</th><th>Operações</th><th>Latência Média (ms)</th><th>Taxa de Sucesso (%)</th></tr>"
        
        for node in "localhost:3001" "localhost:3002" "localhost:3003" "localhost:3004" "localhost:3005"; do
            if [ -f "$ANALYSIS_DIR/latency_data.csv" ]; then
                local total_ops=$(grep -c ",$node," "$ANALYSIS_DIR/latency_data.csv")
                local successful_ops=$(grep ",$node," "$ANALYSIS_DIR/latency_data.csv" | grep -c "SUCCESS")
                local avg_latency=$(awk -F',' "\$2 == \"$node\" {sum+=\$4; count++} END {if(count>0) printf \"%.2f\", sum/count}" "$ANALYSIS_DIR/latency_data.csv")
                local success_rate=$(echo "scale=2; $successful_ops * 100 / $total_ops" | bc -l 2>/dev/null || echo "0")
                
                echo "            <tr>"
                echo "                <td>$node</td>"
                echo "                <td>$total_ops</td>"
                echo "                <td>${avg_latency}</td>"
                echo "                <td class='success'>${success_rate}%</td>"
                echo "            </tr>"
            fi
        done
        
        echo "        </table>"
        echo "    </div>"
    } >> "$html_file"

    # Adicionar estatísticas de recursos
    {
        echo "    <div class='section'>"
        echo "        <h2>Recursos do Sistema</h2>"
        
        if [ -f "$ANALYSIS_DIR/resources_data.csv" ]; then
            local cpu_avg=$(awk -F',' '$2 != "N/A" {sum+=$2; count++} END {if(count>0) printf "%.2f", sum/count}' "$ANALYSIS_DIR/resources_data.csv")
            local mem_avg=$(awk -F',' '$3 != "N/A" {sum+=$3; count++} END {if(count>0) printf "%.2f", sum/count}' "$ANALYSIS_DIR/resources_data.csv")
            
            echo "        <div class='metric'>"
            echo "            <strong>CPU Média:</strong> ${cpu_avg}%"
            echo "        </div>"
            echo "        <div class='metric'>"
            echo "            <strong>Memória Média:</strong> ${mem_avg}%"
            echo "        </div>"
        fi
        
        echo "    </div>"
    } >> "$html_file"

    # Finalizar HTML
    {
        echo "    <div class='section'>"
        echo "        <h2>Arquivos de Log</h2>"
        echo "        <ul>"
        echo "            <li><a href='../$LATENCY_LOG'>Log de Latência</a></li>"
        echo "            <li><a href='../$RESOURCES_LOG'>Log de Recursos</a></li>"
        echo "            <li><a href='../$PERFORMANCE_LOG'>Log de Performance</a></li>"
        echo "        </ul>"
        echo "    </div>"
        echo "</body>"
        echo "</html>"
    } >> "$html_file"
    
    echo "Relatório HTML gerado: $html_file"
}

# Função para mostrar ajuda
show_help() {
    echo "=== Análise de Stress Test - NaiveCoin ==="
    echo ""
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  -g, --graphs              Gerar gráficos (requer gnuplot)"
    echo "  -h, --html                Gerar relatório HTML"
    echo "  -a, --all                 Executar todas as análises"
    echo "  -h, --help                Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 -a                     # Análise completa"
    echo "  $0 --graphs               # Apenas gráficos"
    echo "  $0 --html                 # Apenas relatório HTML"
    echo ""
}

# Parse de argumentos
GENERATE_GRAPHS=false
GENERATE_HTML=false
ANALYZE_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--graphs)
            GENERATE_GRAPHS=true
            shift
            ;;
        -h|--html)
            GENERATE_HTML=true
            shift
            ;;
        -a|--all)
            ANALYZE_ALL=true
            shift
            ;;
        --help)
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

# Se nenhuma opção foi especificada, executar análise básica
if [ "$GENERATE_GRAPHS" = false ] && [ "$GENERATE_HTML" = false ] && [ "$ANALYZE_ALL" = false ]; then
    ANALYZE_ALL=true
fi

# Verificar se os logs existem
check_logs

echo "=== ANÁLISE DE STRESS TEST ==="
echo ""

# Executar análises
if [ "$ANALYZE_ALL" = true ] || [ "$GENERATE_GRAPHS" = false ] && [ "$GENERATE_HTML" = false ]; then
    analyze_latency
    analyze_resources
fi

if [ "$GENERATE_GRAPHS" = true ] || [ "$ANALYZE_ALL" = true ]; then
    generate_graphs
fi

if [ "$GENERATE_HTML" = true ] || [ "$ANALYZE_ALL" = true ]; then
    generate_html_report
fi

echo ""
echo "Análise concluída! Resultados salvos em: $ANALYSIS_DIR/" 