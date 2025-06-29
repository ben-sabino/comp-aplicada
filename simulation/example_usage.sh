#!/bin/bash

# Script de exemplo para demonstrar o uso dos scripts de stress test
# Este script mostra diferentes cenários de teste

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== EXEMPLOS DE USO - STRESS TEST NAIVECOIN ===${NC}"
echo ""

# Função para mostrar exemplo
show_example() {
    local title="$1"
    local description="$2"
    local command="$3"
    
    echo -e "${BLUE}$title${NC}"
    echo -e "$description"
    echo -e "${YELLOW}Comando:${NC} $command"
    echo ""
}

# Exemplo 1: Teste básico
show_example "1. Teste Básico (5 minutos)" \
    "Executa um stress test básico por 5 minutos com intervalo de 5 segundos." \
    "./run_stress_test_complete.sh"

# Exemplo 2: Teste com monitoramento
show_example "2. Teste com Monitoramento" \
    "Executa stress test com monitoramento em tempo real." \
    "./run_stress_test_complete.sh -m"

# Exemplo 3: Teste intensivo
show_example "3. Teste Intensivo (10 minutos)" \
    "Executa stress test mais intensivo com intervalo de 2 segundos." \
    "./run_stress_test_complete.sh -d 600 -i 2"

# Exemplo 4: Teste completo
show_example "4. Teste Completo" \
    "Executa stress test completo com monitoramento e análise automática." \
    "./run_stress_test_complete.sh -d 600 -i 3 -m -a"

# Exemplo 5: Monitoramento apenas
show_example "5. Monitoramento Apenas" \
    "Executa apenas o monitoramento em tempo real." \
    "./realtime_monitor.sh"

# Exemplo 6: Análise de logs existentes
show_example "6. Análise de Logs" \
    "Analisa logs de um teste anterior e gera relatórios." \
    "./analyze_stress_test.sh -a"

# Exemplo 7: Teste com limpeza
show_example "7. Teste com Limpeza" \
    "Limpa logs antigos e executa teste completo." \
    "./run_stress_test_complete.sh -c -d 300 -m -a"

# Exemplo 8: Stress test individual
show_example "8. Stress Test Individual" \
    "Executa apenas o stress test sem monitoramento." \
    "./stress_test.sh -d 300 -i 5"

echo -e "${GREEN}=== COMO EXECUTAR ===${NC}"
echo ""
echo "1. Certifique-se de que a rede blockchain está rodando:"
echo "   cd .. && ./blockchain.ps1"
echo ""
echo "2. Navegue para o diretório de simulação:"
echo "   cd simulation"
echo ""
echo "3. Execute um dos exemplos acima"
echo ""
echo -e "${YELLOW}Dica:${NC} Para interromper qualquer teste, pressione Ctrl+C"
echo ""
echo -e "${CYAN}Para mais informações, consulte: STRESS_TEST_README.md${NC}" 