#!/bin/bash

# Script para testar e demonstrar o logging de rate limiting

echo "========== TESTE DE LOGGING DE RATE LIMITING =========="
echo "Este script irá gerar requisições para demonstrar o logging"
echo "========================================================"

# Função para simular diferentes cenários
simulate_different_ips() {
    echo ""
    echo "🔄 Simulando requisições de diferentes IPs usando User-Agent..."
    echo "Nota: O Nginx está configurado para usar \$binary_remote_addr (IP real)"
    echo ""
    
    for i in {1..15}; do
        echo "Requisição $i com User-Agent personalizado:"
        curl -s -w "Status: %{http_code}\n" \
             -H "User-Agent: TestClient-$i" \
             http://localhost:9999/ > /dev/null
        
        # Pequena pausa para ver o comportamento
        if [ $((i % 5)) -eq 0 ]; then
            echo "--- Pausando 2 segundos ---"
            sleep 2
        fi
    done
}

# Função para burst de requisições
generate_burst() {
    echo ""
    echo "💥 Gerando burst de 20 requisições rápidas..."
    echo ""
    
    for i in {1..20}; do
        echo -n "Req $i: "
        curl -s -w "%{http_code}" http://localhost:9999/ > /dev/null
        echo ""
        
        # Sem delay para forçar rate limiting
    done
}

# Função para requisições com diferentes patterns
test_patterns() {
    echo ""
    echo "📊 Testando diferentes padrões de requisições..."
    echo ""
    
    echo "1. Rajada inicial (10 requisições):"
    for i in {1..10}; do
        echo -n "$i "
        curl -s -w "%{http_code}" http://localhost:9999/ > /dev/null
        echo -n " "
    done
    echo ""
    
    echo ""
    echo "2. Aguardando 3 segundos..."
    sleep 3
    
    echo ""
    echo "3. Requisições com intervalo (5 requisições, 1s cada):"
    for i in {1..5}; do
        echo -n "Req $i: "
        curl -s -w "%{http_code}" http://localhost:9999/ > /dev/null
        echo ""
        sleep 1
    done
    
    echo ""
    echo "4. Nova rajada para testar logging (15 requisições):"
    for i in {1..15}; do
        echo -n "$i "
        curl -s -w "%{http_code}" http://localhost:9999/ > /dev/null
        echo -n " "
    done
    echo ""
}

# Execução do teste
echo "Iniciando teste em 3 segundos..."
echo "Certifique-se de que a aplicação está rodando (sudo docker compose up)"
echo ""
sleep 3

# Executa diferentes testes
generate_burst
test_patterns

echo ""
echo "========== TESTE CONCLUÍDO =========="
echo ""
echo "Para ver os logs de rate limiting, execute:"
echo "  ./monitor_rate_limit.sh check   - Ver estatísticas"
echo "  ./monitor_rate_limit.sh report  - Gerar relatório completo"
echo ""
echo "Para monitorar em tempo real:"
echo "  ./monitor_rate_limit.sh monitor"
