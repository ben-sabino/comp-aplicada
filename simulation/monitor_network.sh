#!/bin/bash

# Script de monitoramento da rede blockchain
NODES=("localhost:3001" "localhost:3002" "localhost:3003" "localhost:3004" "localhost:3005")

echo "=== Monitor da Rede Blockchain NaiveCoin ==="
echo "Pressione Ctrl+C para sair"

while true; do
    clear
    echo "=== STATUS DA REDE $(date) ==="
    echo ""
    
    for i in "${!NODES[@]}"; do
        node=${NODES[$i]}
        node_num=$((i + 1))
        
        echo "--- Nó $node_num ($node) ---"
        
        # Verificar se o nó está online
        if curl -s --max-time 2 "http://$node/blocks" > /dev/null; then
            # Obter informações do nó
            address=$(curl -s --max-time 2 "http://$node/address" 2>/dev/null | grep -o '"address":"[^"]*"' | cut -d'"' -f4)
            balance=$(curl -s --max-time 2 "http://$node/balance" 2>/dev/null | grep -o '"balance":[0-9]*' | cut -d':' -f2)
            blocks=$(curl -s --max-time 2 "http://$node/blocks" 2>/dev/null | grep -o '"index":[0-9]*' | wc -l)
            peers_raw=$(curl -s --max-time 2 "http://$node/peers" 2>/dev/null)
            peers=$(echo "$peers_raw" | grep -o ',' | wc -l)
            if [ ! -z "$peers_raw" ] && [ "$peers_raw" != "[]" ]; then
                peers=$((peers + 1))
            else
                peers=0
            fi
            
            echo "Status: 🟢 ONLINE"
            echo "Endereço: ${address:-'N/A'}"
            echo "Saldo: ${balance:-0} coins"
            echo "Blocos: ${blocks:-0}"
            echo "Peers: $peers"
        else
            echo "Status: 🔴 OFFLINE"
        fi
        echo ""
    done
    
    # Mostrar últimos blocos do nó 1
    echo "--- Últimos 3 Blocos (Nó 1) ---"
    latest_blocks=$(curl -s --max-time 3 "http://localhost:3001/blocks" 2>/dev/null | tail -20)
    if [ ! -z "$latest_blocks" ]; then
        echo "$latest_blocks" | grep -E '"index"|"hash"|"timestamp"' | tail -9
    else
        echo "Não foi possível obter informações dos blocos"
    fi
    
    echo ""
    echo "=== Pool de Transações (Nó 1) ==="
    tx_pool=$(curl -s --max-time 3 "http://localhost:3001/transactionPool" 2>/dev/null)
    if [ ! -z "$tx_pool" ] && [ "$tx_pool" != "[]" ]; then
        echo "$tx_pool"
    else
        echo "Pool de transações vazio"
    fi
    
    sleep 5
done
