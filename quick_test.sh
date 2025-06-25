#!/bin/bash

# Script de teste rápido da rede blockchain

echo "=== TESTE RÁPIDO DA REDE BLOCKCHAIN ==="
echo ""

# Verificar se Docker está rodando
if ! docker --version > /dev/null 2>&1; then
    echo "❌ Docker não está instalado ou não está rodando"
    exit 1
fi

if ! docker-compose --version > /dev/null 2>&1; then
    echo "❌ Docker Compose não está instalado"
    exit 1
fi

echo "✅ Docker e Docker Compose detectados"
echo ""

# Verificar se as portas estão livres
echo "Verificando portas..."
for port in 3001 3002 3003 3004 3005 6001 6002 6003 6004 6005; do
    if netstat -an 2>/dev/null | grep :$port > /dev/null 2>&1; then
        echo "⚠️  Porta $port já está em uso"
    else
        echo "✅ Porta $port está livre"
    fi
done

echo ""
echo "=== INICIANDO TESTE ==="

# Construir e iniciar containers
echo "Construindo e iniciando containers..."
docker-compose up -d --build

if [ $? -ne 0 ]; then
    echo "❌ Erro ao iniciar containers"
    exit 1
fi

echo "✅ Containers iniciados"
echo ""

# Aguardar nós ficarem online
echo "Aguardando nós ficarem online (30 segundos)..."
sleep 30

# Testar conectividade
echo ""
echo "=== TESTANDO CONECTIVIDADE ==="
for i in {1..5}; do
    port=$((3000 + i))
    if curl -s --max-time 5 "http://localhost:$port/blocks" > /dev/null; then
        echo "✅ Nó $i (porta $port) está online"
    else
        echo "❌ Nó $i (porta $port) está offline"
    fi
done

echo ""
echo "=== TESTE DE MINERAÇÃO ==="

# Minerar um bloco no nó 1
echo "Minerando bloco no nó 1..."
response=$(curl -s -X POST "http://localhost:3001/mineBlock")
if [ $? -eq 0 ]; then
    echo "✅ Bloco minerado com sucesso"
    echo "Resposta: $response"
else
    echo "❌ Erro ao minerar bloco"
fi

echo ""
echo "=== VERIFICANDO SINCRONIZAÇÃO ==="

# Aguardar sincronização
sleep 5

# Verificar se todos os nós têm o mesmo número de blocos
echo "Verificando se todos os nós estão sincronizados..."
for i in {1..5}; do
    port=$((3000 + i))
    blocks=$(curl -s "http://localhost:$port/blocks" 2>/dev/null | grep -o '"index":[0-9]*' | wc -l)
    echo "Nó $i tem $blocks blocos"
done

echo ""
echo "=== TESTE CONCLUÍDO ==="
echo ""
echo "Para continuar testando:"
echo "- Execute: docker logs naivecoin-simulator"
echo "- Acesse: http://localhost:3001/blocks"
echo "- Use: .\blockchain.ps1 -Action status"
echo ""
echo "Para parar tudo:"
echo "- Execute: docker-compose down"
