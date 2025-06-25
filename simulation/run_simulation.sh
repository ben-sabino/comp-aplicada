#!/bin/bash

# Script principal de simulação da rede blockchain
echo "=== Iniciando Simulação da Rede Blockchain NaiveCoin ==="

# Lista de nós
NODES=("node1:3001" "node2:3001" "node3:3001" "node4:3001" "node5:3001")

# Função para aguardar que todos os nós estejam online
wait_for_nodes() {
    echo "Aguardando todos os nós ficarem online..."
    for node in "${NODES[@]}"; do
        while ! curl -s "http://$node/blocks" > /dev/null; do
            echo "Aguardando nó $node..."
            sleep 2
        done
        echo "Nó $node está online!"
    done
    echo "Todos os nós estão online!"
}

# Função para obter o endereço de um nó
get_node_address() {
    local node=$1
    curl -s "http://$node/address" | grep -o '"address":"[^"]*"' | cut -d'"' -f4
}

# Função para obter o saldo de um nó
get_node_balance() {
    local node=$1
    curl -s "http://$node/balance" | grep -o '"balance":[0-9]*' | cut -d':' -f2
}

# Função para minerar um bloco
mine_block() {
    local node=$1
    echo "Minerando bloco no nó $node..."
    response=$(curl -s -X POST "http://$node/mineBlock")
    if [ $? -eq 0 ]; then
        echo "Bloco minerado com sucesso no nó $node!"
        echo "Resposta: $response"
    else
        echo "Erro ao minerar bloco no nó $node"
    fi
}

# Função para enviar transação
send_transaction() {
    local from_node=$1
    local to_address=$2
    local amount=$3
    
    echo "Enviando $amount coins do nó $from_node para $to_address..."
    response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "{\"address\":\"$to_address\",\"amount\":$amount}" \
        "http://$from_node/sendTransaction")
    
    if [ $? -eq 0 ]; then
        echo "Transação enviada com sucesso!"
        echo "Resposta: $response"
    else
        echo "Erro ao enviar transação"
    fi
}

# Função para minerar transação diretamente
mine_transaction() {
    local from_node=$1
    local to_address=$2
    local amount=$3
    
    echo "Minerando transação: $amount coins do nó $from_node para $to_address..."
    response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "{\"address\":\"$to_address\",\"amount\":$amount}" \
        "http://$from_node/mineTransaction")
    
    if [ $? -eq 0 ]; then
        echo "Transação minerada com sucesso!"
        echo "Resposta: $response"
    else
        echo "Erro ao minerar transação"
    fi
}

# Função para mostrar status da rede
show_network_status() {
    echo ""
    echo "=== STATUS DA REDE ==="
    for node in "${NODES[@]}"; do
        echo "--- Nó $node ---"
        address=$(get_node_address "$node")
        balance=$(get_node_balance "$node")
        blocks=$(curl -s "http://$node/blocks" | grep -o '"index":[0-9]*' | wc -l)
        peers=$(curl -s "http://$node/peers" | grep -o ',' | wc -l)
        peers=$((peers + 1))
        
        echo "Endereço: $address"
        echo "Saldo: $balance coins"
        echo "Blocos na chain: $blocks"
        echo "Peers conectados: $peers"
        echo ""
    done
}

# Aguardar nós ficarem online
wait_for_nodes

echo ""
echo "=== FASE 1: Mineração inicial ==="
# Dar tempo para os nós se conectarem
sleep 5

# Minerar alguns blocos iniciais para gerar coins
mine_block "node1:3001"
sleep 3
mine_block "node2:3001"
sleep 3
mine_block "node3:3001"
sleep 3

show_network_status

echo ""
echo "=== FASE 2: Coletando endereços dos nós ==="
declare -A NODE_ADDRESSES
for node in "${NODES[@]}"; do
    address=$(get_node_address "$node")
    NODE_ADDRESSES[$node]=$address
    echo "Nó $node: $address"
done

echo ""
echo "=== FASE 3: Realizando transações entre nós ==="

# Aguardar sincronização
sleep 5

# Transação 1: node1 -> node2
mine_transaction "node1:3001" "${NODE_ADDRESSES[node2:3001]}" 10
sleep 3

# Transação 2: node2 -> node3
mine_transaction "node2:3001" "${NODE_ADDRESSES[node3:3001]}" 5
sleep 3

# Transação 3: node3 -> node4
mine_transaction "node3:3001" "${NODE_ADDRESSES[node4:3001]}" 3
sleep 3

# Transação 4: node4 -> node5
mine_transaction "node4:3001" "${NODE_ADDRESSES[node5:3001]}" 2
sleep 3

# Transação 5: node5 -> node1
mine_transaction "node5:3001" "${NODE_ADDRESSES[node1:3001]}" 1
sleep 3

echo ""
echo "=== FASE 4: Mais mineração distribuída ==="

# Minerar alguns blocos adicionais em diferentes nós
mine_block "node4:3001"
sleep 3
mine_block "node5:3001"
sleep 3
mine_block "node1:3001"
sleep 3

show_network_status

echo ""
echo "=== FASE 5: Rodada adicional de transações ==="

# Segunda rodada de transações
mine_transaction "node1:3001" "${NODE_ADDRESSES[node3:3001]}" 7
sleep 3
mine_transaction "node2:3001" "${NODE_ADDRESSES[node4:3001]}" 4
sleep 3
mine_transaction "node3:3001" "${NODE_ADDRESSES[node5:3001]}" 6
sleep 3

echo ""
echo "=== STATUS FINAL DA REDE ==="
show_network_status

echo ""
echo "=== DETALHES DA BLOCKCHAIN ==="
for node in "${NODES[@]}"; do
    echo "--- Blockchain do nó $node ---"
    curl -s "http://$node/blocks" | head -20
    echo ""
done

echo ""
echo "=== Simulação concluída! ==="
echo "A rede blockchain está funcionando com 5 nós."
echo "Transações foram realizadas e blocos foram minerados."
echo "Você pode continuar monitorando a rede acessando:"
echo "- Nó 1: http://localhost:3001"
echo "- Nó 2: http://localhost:3002"
echo "- Nó 3: http://localhost:3003"
echo "- Nó 4: http://localhost:3004"
echo "- Nó 5: http://localhost:3005"

# Manter o simulador ativo para monitoramento contínuo
echo ""
echo "=== Modo de monitoramento contínuo ativado ==="
while true; do
    sleep 30
    echo "$(date): Rede ativa - $(curl -s http://node1:3001/blocks | grep -o '"index":[0-9]*' | wc -l) blocos na chain"
done
