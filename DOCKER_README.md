# Simulação de Rede Blockchain NaiveCoin com Docker

Esta configuração cria uma rede blockchain completa com 5 nós interconectados, simulando transações e mineração automaticamente.

## 🚀 Como executar

### Pré-requisitos
- Docker e Docker Compose instalados
- Portas 3001-3005 e 6001-6005 livres

### Iniciando a rede

1. **Construir e iniciar todos os nós:**
```bash
docker-compose up --build
```

2. **Executar em segundo plano:**
```bash
docker-compose up -d --build
```

### 📊 Monitoramento da rede

#### Acessar via browser
- **Nó 1:** http://localhost:3001
- **Nó 2:** http://localhost:3002  
- **Nó 3:** http://localhost:3003
- **Nó 4:** http://localhost:3004
- **Nó 5:** http://localhost:3005

#### Endpoints disponíveis para cada nó:
- `/blocks` - Ver toda a blockchain
- `/balance` - Ver saldo do nó
- `/address` - Ver endereço do nó
- `/peers` - Ver peers conectados
- `/transactionPool` - Ver transações pendentes

#### Script de monitoramento contínuo
```bash
# No Windows (PowerShell)
docker exec -it naivecoin-simulator bash /app/simulation/monitor_network.sh

# Ou execute o script local (se tiver bash instalado)
bash simulation/monitor_network.sh
```

## 🔧 Operações manuais

### Usando o utilitário blockchain_utils.sh

```bash
# Ver status de todos os nós
bash simulation/blockchain_utils.sh status

# Ver saldo de um nó específico (1-5)
bash simulation/blockchain_utils.sh balance 1

# Minerar um bloco em um nó
bash simulation/blockchain_utils.sh mine 2

# Enviar transação entre nós
bash simulation/blockchain_utils.sh send 1 2 10

# Ver blockchain completa de um nó
bash simulation/blockchain_utils.sh blocks 1

# Ver peers conectados
bash simulation/blockchain_utils.sh peers 1
```

### Usando curl diretamente

```bash
# Ver blockchain do nó 1
curl http://localhost:3001/blocks

# Ver saldo do nó 2
curl http://localhost:3002/balance

# Minerar bloco no nó 3
curl -X POST http://localhost:3003/mineBlock

# Enviar transação do nó 1 para endereço específico
curl -X POST -H "Content-Type: application/json" \
  -d '{"address":"ENDEREÇO_DESTINO","amount":10}' \
  http://localhost:3001/mineTransaction
```

## 🎯 O que a simulação faz automaticamente

1. **Inicialização:** Aguarda todos os 5 nós ficarem online
2. **Conexão P2P:** Conecta todos os nós entre si automaticamente
3. **Mineração inicial:** Minera blocos para gerar coins iniciais
4. **Transações:** Realiza transações entre os nós
5. **Mineração distribuída:** Distribui a mineração entre diferentes nós
6. **Monitoramento:** Monitora continuamente o status da rede

## 📁 Estrutura dos arquivos

```
naivecoin/
├── Dockerfile                 # Container principal dos nós
├── Dockerfile.simulator       # Container do simulador
├── docker-compose.yml         # Orquestração dos containers
├── simulation/
│   ├── run_simulation.sh      # Script principal de simulação
│   ├── monitor_network.sh     # Monitoramento contínuo
│   └── blockchain_utils.sh    # Utilitários para operações manuais
├── wallets/                   # Carteiras separadas para cada nó
│   ├── node1/
│   ├── node2/
│   ├── node3/
│   ├── node4/
│   └── node5/
└── src/                       # Código fonte do blockchain
```

## 🔍 Logs e debugging

### Ver logs de um nó específico:
```bash
docker logs naivecoin-node1
docker logs naivecoin-node2
# ... etc
```

### Ver logs do simulador:
```bash
docker logs naivecoin-simulator
```

### Acessar container interativamente:
```bash
docker exec -it naivecoin-node1 sh
```

## 🛑 Parar a simulação

```bash
# Parar todos os containers
docker-compose down

# Parar e remover volumes (reseta carteiras)
docker-compose down -v

# Limpar tudo (containers, imagens, volumes)
docker-compose down -v --rmi all
```

## 🔄 Reiniciar apenas um nó

```bash
# Reiniciar nó específico
docker-compose restart node1

# Parar nó específico
docker-compose stop node2

# Iniciar nó específico
docker-compose start node3
```

## 📈 Casos de teste

A simulação automaticamente testa:

1. **Consenso distribuído:** Todos os nós mantêm a mesma blockchain
2. **Transações:** Transferência de coins entre diferentes carteiras
3. **Mineração competitiva:** Diferentes nós podem minerar blocos
4. **Sincronização P2P:** Novos blocos são propagados para toda a rede
5. **Tolerância a falhas:** A rede continua funcionando mesmo se alguns nós falharem

## 🚨 Troubleshooting

### Problema: Portas já em uso
```bash
# Verificar que processos estão usando as portas
netstat -ano | findstr :3001
netstat -ano | findstr :6001

# Matar processo específico (substitua PID)
taskkill /PID <PID> /F
```

### Problema: Nós não se conectam
- Verificar se todos os containers estão rodando: `docker-compose ps`
- Verificar logs dos containers: `docker logs naivecoin-node1`
- Reiniciar a rede: `docker-compose restart`

### Problema: Transações não funcionam
- Verificar se os nós têm saldo suficiente
- Verificar se os endereços estão corretos
- Aguardar a sincronização da rede (alguns segundos)

## 🎓 Conceitos demonstrados

Esta simulação demonstra conceitos fundamentais de blockchain:

- **Descentralização:** Múltiplos nós independentes
- **Consenso:** Todos os nós concordam com o estado da blockchain
- **Criptografia:** Transações assinadas digitalmente
- **Proof of Work:** Mineração para adicionar novos blocos
- **P2P Network:** Comunicação direta entre nós
- **Imutabilidade:** Histórico de transações não pode ser alterado
- **Transparência:** Toda a blockchain é pública e auditável
