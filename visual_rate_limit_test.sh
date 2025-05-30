#!/bin/bash

# Script para visualizar o rate limiting do Nginx em ação

echo "===== Demonstração de Rate Limiting do Nginx ====="
echo "Configuração: 1 request/segundo com burst de 5"
echo "------------------------------------------------"

# Função para fazer uma requisição e mostrar o status
make_request() {
  local result=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9999/)
  local timestamp=$(date +"%H:%M:%S.%3N")
  
  if [ "$result" == "200" ]; then
    echo -e "[$timestamp] Requisição $1: \e[32mSUCESSO\e[0m (Status: $result)"
  else
    echo -e "[$timestamp] Requisição $1: \e[31mBLOQUEADA\e[0m (Status: $result)"
  fi
}

echo -e "\n>> Teste 1: Envio de 10 requisições IMEDIATAMENTE"
echo "   (Deve permitir ~5 requisições no burst e bloquear as demais)"
echo "   ------------------------------------------------------"

for i in {1..10}; do
  make_request $i
done

echo -e "\n>> Teste 2: Envio de 5 requisições com INTERVALO de 1 segundo"
echo "   (Todas devem ser permitidas, pois respeitam o limite de 1 req/s)"
echo "   -------------------------------------------------------------"

for i in {1..5}; do
  sleep 1
  make_request $i
  sleep 1
done

echo -e "\n>> Teste 3: Teste de carga com wrk - 5 segundos, 10 conexões"
echo "   (Muitas requisições serão bloqueadas)"
echo "   ------------------------------------------------------"

wrk -t2 -c10 -d5s --latency http://localhost:9999/

echo -e "\n===== Teste de Rate Limiting Concluído ====="
