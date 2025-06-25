#!/bin/bash

# Script para operações manuais na rede blockchain

show_help() {
    echo "=== Utilitários da Rede Blockchain NaiveCoin ==="
    echo ""
    echo "Uso: $0 [comando] [parâmetros]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  status                    - Mostra o status de todos os nós"
    echo "  balance [nó]             - Mostra o saldo de um nó (1-5)"
    echo "  mine [nó]                - Minera um bloco em um nó"
    echo "  send [nó_origem] [nó_destino] [quantidade] - Envia transação"
    echo "  blocks [nó]              - Mostra a blockchain de um nó"
    echo "  peers [nó]               - Mostra os peers conectados"
    echo "  address [nó]             - Mostra o endereço de um nó"
    echo "  tx_pool [nó]             - Mostra o pool de transações"
    echo ""
    echo "Exemplos:"
    echo "  $0 status"
    echo "  $0 balance 1"
    echo "  $0 mine 2"
    echo "  $0 send 1 2 10"
    echo ""
}

get_node_url() {
    case $1 in
        1) echo "localhost:3001" ;;
        2) echo "localhost:3002" ;;
        3) echo "localhost:3003" ;;
        4) echo "localhost:3004" ;;
        5) echo "localhost:3005" ;;
        *) echo ""; return 1 ;;
    esac
}

get_node_address() {
    local node_url=$(get_node_url $1)
    if [ -z "$node_url" ]; then
        echo "Nó inválido: $1"
        return 1
    fi
    curl -s "http://$node_url/address" | grep -o '"address":"[^"]*"' | cut -d'"' -f4
}

case $1 in
    "status")
        echo "=== STATUS DA REDE ==="
        for i in {1..5}; do
            node_url=$(get_node_url $i)
            echo "--- Nó $i ($node_url) ---"
            
            if curl -s --max-time 2 "http://$node_url/blocks" > /dev/null; then
                address=$(curl -s "http://$node_url/address" | grep -o '"address":"[^"]*"' | cut -d'"' -f4)
                balance=$(curl -s "http://$node_url/balance" | grep -o '"balance":[0-9]*' | cut -d':' -f2)
                blocks=$(curl -s "http://$node_url/blocks" | grep -o '"index":[0-9]*' | wc -l)
                peers=$(curl -s "http://$node_url/peers" | grep -o ',' | wc -l)
                peers=$((peers + 1))
                
                echo "Status: ONLINE"
                echo "Endereço: $address"
                echo "Saldo: $balance coins"
                echo "Blocos: $blocks"
                echo "Peers: $peers"
            else
                echo "Status: OFFLINE"
            fi
            echo ""
        done
        ;;
        
    "balance")
        if [ -z "$2" ]; then
            echo "Uso: $0 balance [nó]"
            exit 1
        fi
        node_url=$(get_node_url $2)
        if [ -z "$node_url" ]; then
            echo "Nó inválido: $2"
            exit 1
        fi
        echo "Saldo do nó $2:"
        curl -s "http://$node_url/balance"
        echo ""
        ;;
        
    "mine")
        if [ -z "$2" ]; then
            echo "Uso: $0 mine [nó]"
            exit 1
        fi
        node_url=$(get_node_url $2)
        if [ -z "$node_url" ]; then
            echo "Nó inválido: $2"
            exit 1
        fi
        echo "Minerando bloco no nó $2..."
        curl -s -X POST "http://$node_url/mineBlock"
        echo ""
        ;;
        
    "send")
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "Uso: $0 send [nó_origem] [nó_destino] [quantidade]"
            exit 1
        fi
        
        from_url=$(get_node_url $2)
        to_address=$(get_node_address $3)
        amount=$4
        
        if [ -z "$from_url" ] || [ -z "$to_address" ]; then
            echo "Nó inválido"
            exit 1
        fi
        
        echo "Enviando $amount coins do nó $2 para o nó $3..."
        curl -s -X POST -H "Content-Type: application/json" \
            -d "{\"address\":\"$to_address\",\"amount\":$amount}" \
            "http://$from_url/mineTransaction"
        echo ""
        ;;
        
    "blocks")
        if [ -z "$2" ]; then
            echo "Uso: $0 blocks [nó]"
            exit 1
        fi
        node_url=$(get_node_url $2)
        if [ -z "$node_url" ]; then
            echo "Nó inválido: $2"
            exit 1
        fi
        echo "Blockchain do nó $2:"
        curl -s "http://$node_url/blocks" | python3 -m json.tool 2>/dev/null || curl -s "http://$node_url/blocks"
        ;;
        
    "peers")
        if [ -z "$2" ]; then
            echo "Uso: $0 peers [nó]"
            exit 1
        fi
        node_url=$(get_node_url $2)
        if [ -z "$node_url" ]; then
            echo "Nó inválido: $2"
            exit 1
        fi
        echo "Peers do nó $2:"
        curl -s "http://$node_url/peers"
        echo ""
        ;;
        
    "address")
        if [ -z "$2" ]; then
            echo "Uso: $0 address [nó]"
            exit 1
        fi
        node_url=$(get_node_url $2)
        if [ -z "$node_url" ]; then
            echo "Nó inválido: $2"
            exit 1
        fi
        echo "Endereço do nó $2:"
        curl -s "http://$node_url/address"
        echo ""
        ;;
        
    "tx_pool")
        if [ -z "$2" ]; then
            echo "Uso: $0 tx_pool [nó]"
            exit 1
        fi
        node_url=$(get_node_url $2)
        if [ -z "$node_url" ]; then
            echo "Nó inválido: $2"
            exit 1
        fi
        echo "Pool de transações do nó $2:"
        curl -s "http://$node_url/transactionPool"
        echo ""
        ;;
        
    *)
        show_help
        ;;
esac
