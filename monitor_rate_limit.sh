#!/bin/bash

# Script para monitorar logs de rate limiting do Nginx

SCRIPT_DIR="/home/paulo/rate_limit"
HOST_LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$HOST_LOG_DIR/rate_limit_violations.log" 
GENERAL_LOG="$HOST_LOG_DIR/rate_limit.log"

echo "========== Monitor de Rate Limiting =========="
echo "Data/Hora: $(date)"
echo ""

# Função para verificar se os arquivos de log existem no container
check_logs_in_container() {
    echo "Verificando logs no container..."
    
    # Verifica se o container nginx está rodando
    if ! sudo docker ps | grep -q "rate_limit-nginx"; then
        echo "❌ Container nginx não está rodando!"
        echo "Execute: sudo docker compose up -d"
        return 1
    fi
    
    # Cria os diretórios de log se não existirem
    sudo docker exec rate_limit-nginx-1 mkdir -p /var/log/nginx
    
    echo "✅ Container nginx está rodando"
    return 0
}

# Função para mostrar estatísticas dos logs
show_log_stats() {
    echo "📊 Estatísticas de Rate Limiting:"
    echo "--------------------------------"
    
    # Total de requisições bloqueadas
    if [ -f "$LOG_FILE" ]; then
        local blocked_count=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
        echo "Total de requisições bloqueadas: $blocked_count"
        
        # IPs únicos que foram bloqueados
        if [ "$blocked_count" -gt 0 ]; then
            echo ""
            echo "🚫 IPs que excederam o limite:"
            awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr || echo "Nenhum registro encontrado"
        fi
    else
        echo "Arquivo de log $LOG_FILE não encontrado"
        echo "Total de requisições bloqueadas: 0"
    fi
    
    echo ""
}

# Função para mostrar logs em tempo real
monitor_real_time() {
    echo "🔍 Monitoramento em tempo real (Ctrl+C para sair)"
    echo "Faça algumas requisições para ver os logs..."
    echo "Exemplo: curl http://localhost:9999/"
    echo ""
    
    # Monitora os logs em tempo real
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE" &
    else
        echo "Arquivo de log $LOG_FILE não encontrado"
        echo "Aguardando logs..." 
        touch "$LOG_FILE"
        tail -f "$LOG_FILE" &
    fi
    
    local tail_pid=$!
    
    # Captura Ctrl+C para parar o monitoramento
    trap "kill $tail_pid 2>/dev/null; echo ''; echo 'Monitoramento interrompido.'; exit 0" INT
    
    # Aguarda indefinidamente
    wait $tail_pid
}

# Função para gerar relatório de logs
generate_report() {
    local report_file="$SCRIPT_DIR/rate_limit_report.txt"
    
    echo "📋 Gerando relatório..."
    
    {
        echo "========== RELATÓRIO DE RATE LIMITING =========="
        echo "Gerado em: $(date)"
        echo "=============================================="
        echo ""
        
        echo "CONFIGURAÇÃO ATUAL:"
        echo "- Limite: 1 requisição por segundo"
        echo "- Burst: 5 requisições"
        echo "- Resposta de erro: 429"
        echo ""
        
        echo "ESTATÍSTICAS:"
        if [ -f "$LOG_FILE" ]; then
            local blocked_count=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
            echo "Total de bloqueios: $blocked_count"
            echo ""
            
            if [ "$blocked_count" -gt 0 ]; then
                echo "IPs BLOQUEADOS (quantidade de bloqueios):"
                awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr
                echo ""
                
                echo "ÚLTIMOS 10 BLOQUEIOS:"
                tail -n 10 "$LOG_FILE"
            else
                echo "Nenhum bloqueio registrado ainda."
            fi
        else
            echo "Arquivo de log não encontrado."
            echo "Total de bloqueios: 0"
        fi
        
        echo ""
        echo "=========================================="
        
    } > "$report_file"
    
    echo "✅ Relatório salvo em: $report_file"
    echo ""
    cat "$report_file"
}

# Menu principal
case "${1:-menu}" in
    "check")
        check_logs_in_container
        show_log_stats
        ;;
    "monitor")
        check_logs_in_container
        monitor_real_time
        ;;
    "report")
        check_logs_in_container
        generate_report
        ;;
    "menu"|*)
        echo "Opções disponíveis:"
        echo "  ./monitor_rate_limit.sh check   - Verificar status e estatísticas"
        echo "  ./monitor_rate_limit.sh monitor - Monitorar logs em tempo real"
        echo "  ./monitor_rate_limit.sh report  - Gerar relatório completo"
        echo ""
        echo "Executando verificação básica..."
        echo ""
        check_logs_in_container
        show_log_stats
        ;;
esac
