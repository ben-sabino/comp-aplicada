# Stress Test Suite - NaiveCoin

Este conjunto de scripts fornece uma solução completa para realizar stress tests na rede blockchain NaiveCoin, incluindo monitoramento de latência, recursos do sistema e análise detalhada de performance.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Scripts Disponíveis](#scripts-disponíveis)
- [Instalação e Dependências](#instalação-e-dependências)
- [Uso Rápido](#uso-rápido)
- [Documentação Detalhada](#documentação-detalhada)
- [Exemplos de Uso](#exemplos-de-uso)
- [Interpretação dos Resultados](#interpretação-dos-resultados)
- [Troubleshooting](#troubleshooting)

## 🎯 Visão Geral

O sistema de stress test foi projetado para:

- **Medir latência** de todas as operações blockchain
- **Monitorar recursos** do sistema em tempo real
- **Gerar relatórios** detalhados de performance
- **Analisar tendências** através de gráficos
- **Detectar gargalos** na rede

## 📁 Scripts Disponíveis

### 1. `run_stress_test_complete.sh` (Principal)
Script coordenador que executa todo o processo de stress test.

### 2. `stress_test.sh`
Script principal de stress test que executa operações intensivas na rede.

### 3. `realtime_monitor.sh`
Monitoramento em tempo real com interface colorida.

### 4. `analyze_stress_test.sh`
Análise dos logs e geração de relatórios e gráficos.

## 🔧 Instalação e Dependências

### Dependências do Sistema

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install curl bc net-tools gnuplot

# CentOS/RHEL
sudo yum install curl bc net-tools gnuplot

# macOS
brew install curl bc gnuplot
```

### Verificação de Dependências

```bash
cd naivecoin/simulation
./run_stress_test_complete.sh --help
```

## 🚀 Uso Rápido

### 1. Iniciar a Rede Blockchain

```bash
# Opção 1: Usando PowerShell
cd naivecoin
./blockchain.ps1

# Opção 2: Usando Docker
cd naivecoin
docker-compose up -d
```

### 2. Executar Stress Test Completo

```bash
cd naivecoin/simulation
./run_stress_test_complete.sh -d 600 -i 3 -m -a
```

Este comando executa:
- Stress test por 10 minutos
- Intervalo de 3 segundos entre operações
- Monitoramento em tempo real
- Análise automática dos resultados

## 📖 Documentação Detalhada

### `run_stress_test_complete.sh`

Script principal que coordena todo o processo.

**Opções:**
- `-d, --duration SECONDS`: Duração do teste (padrão: 300)
- `-i, --interval SECONDS`: Intervalo entre operações (padrão: 5)
- `-m, --monitor`: Executar monitoramento em paralelo
- `-a, --analyze`: Executar análise após o teste
- `-c, --cleanup`: Limpar logs antigos antes do teste

**Exemplos:**
```bash
# Teste básico de 5 minutos
./run_stress_test_complete.sh

# Teste intensivo de 30 minutos
./run_stress_test_complete.sh -d 1800 -i 2

# Teste completo com monitoramento e análise
./run_stress_test_complete.sh -d 600 -i 3 -m -a
```

### `stress_test.sh`

Script de stress test que executa operações intensivas.

**Operações Executadas:**
- Consulta de blocos (baixa latência)
- Consulta de saldo (baixa latência)
- Consulta de peers (baixa latência)
- Mineração de blocos (alta latência)
- Transações entre nós (latência variável)

**Logs Gerados:**
- `stress_test.log`: Log principal
- `latency.log`: Medições de latência
- `resources.log`: Uso de recursos do sistema
- `performance.log`: Estatísticas de performance

### `realtime_monitor.sh`

Monitoramento em tempo real com interface colorida.

**Métricas Monitoradas:**
- Status dos nós (online/offline)
- Latência de operações
- Uso de CPU e memória
- Processos Node.js ativos
- Portas em uso
- Pool de transações
- Últimas transações

**Opções:**
- `-i, --interval SECONDS`: Intervalo de atualização (padrão: 2)
- `-l, --log FILE`: Arquivo de log personalizado

### `analyze_stress_test.sh`

Análise dos resultados e geração de relatórios.

**Funcionalidades:**
- Análise estatística de latência
- Análise de recursos do sistema
- Geração de gráficos (requer gnuplot)
- Relatórios HTML
- Relatórios de texto

**Opções:**
- `-g, --graphs`: Gerar gráficos
- `-h, --html`: Gerar relatório HTML
- `-a, --all`: Executar todas as análises

## 💡 Exemplos de Uso

### Cenário 1: Teste Básico
```bash
# Executar teste básico de 5 minutos
./run_stress_test_complete.sh
```

### Cenário 2: Teste Intensivo
```bash
# Teste de 30 minutos com intervalo de 2 segundos
./run_stress_test_complete.sh -d 1800 -i 2 -m -a
```

### Cenário 3: Monitoramento Apenas
```bash
# Apenas monitoramento em tempo real
./realtime_monitor.sh -i 1
```

### Cenário 4: Análise de Logs Existentes
```bash
# Analisar logs de um teste anterior
./analyze_stress_test.sh -a
```

### Cenário 5: Teste com Limpeza
```bash
# Limpar logs antigos e executar teste
./run_stress_test_complete.sh -c -d 600 -m -a
```

## 📊 Interpretação dos Resultados

### Métricas de Latência

| Operação | Latência Esperada | Status |
|----------|-------------------|--------|
| blocks   | < 100ms          | 🟢 Excelente |
| balance  | < 100ms          | 🟢 Excelente |
| peers    | < 100ms          | 🟢 Excelente |
| mine     | 1000-5000ms      | 🟡 Normal |
| transaction | 500-2000ms    | 🟡 Normal |

### Indicadores de Performance

**🟢 Excelente:**
- Taxa de sucesso > 95%
- Latência média < 500ms
- CPU < 60%
- Memória < 70%

**🟡 Atenção:**
- Taxa de sucesso 80-95%
- Latência média 500-2000ms
- CPU 60-80%
- Memória 70-85%

**🔴 Crítico:**
- Taxa de sucesso < 80%
- Latência média > 2000ms
- CPU > 80%
- Memória > 85%

### Arquivos de Saída

```
stress_test_logs/
├── stress_test.log          # Log principal
├── latency.log              # Medições de latência
├── resources.log            # Recursos do sistema
├── performance.log          # Estatísticas de performance
└── stress_test_report.txt   # Relatório de texto

stress_test_analysis/
├── latency_data.csv         # Dados de latência para análise
├── resources_data.csv       # Dados de recursos
├── latency_over_time.png    # Gráfico de latência
├── system_resources.png     # Gráfico de recursos
└── stress_test_report.html  # Relatório HTML
```

## 🔍 Troubleshooting

### Problema: Nós não estão respondendo
```bash
# Verificar se os nós estão rodando
curl http://localhost:3001/blocks

# Reiniciar a rede
cd naivecoin
./blockchain.ps1
```

### Problema: Dependências faltando
```bash
# Verificar dependências
./run_stress_test_complete.sh --help

# Instalar dependências (Ubuntu/Debian)
sudo apt-get install curl bc net-tools gnuplot
```

### Problema: Logs não são gerados
```bash
# Verificar permissões
ls -la *.sh

# Tornar scripts executáveis
chmod +x *.sh
```

### Problema: Gráficos não são gerados
```bash
# Verificar se gnuplot está instalado
which gnuplot

# Instalar gnuplot
sudo apt-get install gnuplot
```

### Problema: Performance ruim
1. Verificar recursos do sistema
2. Reduzir intervalo entre operações
3. Verificar conectividade de rede
4. Monitorar logs de erro

## 📈 Melhores Práticas

### Para Testes de Desenvolvimento
- Duração: 5-10 minutos
- Intervalo: 3-5 segundos
- Monitoramento: Sim
- Análise: Sim

### Para Testes de Produção
- Duração: 30-60 minutos
- Intervalo: 1-2 segundos
- Monitoramento: Sim
- Análise: Sim
- Limpeza: Sim

### Para Testes de Estresse
- Duração: 2-4 horas
- Intervalo: 1 segundo
- Monitoramento: Sim
- Análise: Sim
- Limpeza: Sim

## 🤝 Contribuição

Para contribuir com melhorias nos scripts:

1. Teste suas mudanças localmente
2. Documente novas funcionalidades
3. Mantenha compatibilidade com sistemas existentes
4. Adicione testes para novas funcionalidades

## 📄 Licença

Este projeto está sob a mesma licença do NaiveCoin principal.

---

**Nota:** Este conjunto de scripts foi desenvolvido para testar a implementação educacional do NaiveCoin. Para uso em produção, considere ferramentas profissionais de stress testing. 