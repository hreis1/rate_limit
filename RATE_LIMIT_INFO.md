# Detalhes da Configuração de Limitação de Taxa

Este documento explica a implementação de limitação de taxa utilizada nesta API.

## Configuração do Nginx

A limitação de taxa é implementada no Nginx utilizando o módulo `limit_req`. Abaixo estão os principais componentes da configuração:

### 1. Definição da Zona de Limitação

```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=1r/s;
```

- `$binary_remote_addr`: Utiliza o endereço IP do cliente como identificador para a limitação
- `zone=api_limit:10m`: Define uma zona chamada "api_limit" com 10MB de memória compartilhada
- `rate=1r/s`: Define o limite de 1 requisição por segundo

### 2. Aplicação da Limitação na Rota

```nginx
limit_req zone=api_limit burst=5 nodelay;
```

- `zone=api_limit`: Aplica a zona de limitação definida anteriormente
- `burst=5`: Permite um pico de até 5 requisições simultâneas
- `nodelay`: As requisições de burst são processadas imediatamente, sem atraso

### 3. Configuração de Resposta para Limite Excedido

```nginx
limit_req_status 429;
error_page 429 = @limit_exceeded;
```

- `limit_req_status 429`: Define o código de status HTTP 429 (Too Many Requests) para quando o limite é excedido
- `error_page 429 = @limit_exceeded`: Redireciona para um location personalizado quando o limite é excedido

### 4. Resposta Personalizada para Limite Excedido

```nginx
location @limit_exceeded {
    access_log /var/log/nginx/rate_limit_violations.log rate_limit_log;
    default_type application/json;
    return 429 '{"status":"error","message":"Rate limit exceeded. Please try again later.","timestamp":"$time_iso8601","client_ip":"$remote_addr"}';
}
```

- Registra as violações de limite em um arquivo de log específico
- Retorna uma resposta JSON com informações sobre o erro
- Mantém o código de status 429 (Too Many Requests)

## Registro de Logs

Três tipos de logs são mantidos:

1. **Logs Gerais**: `/var/log/nginx/rate_limit.log`
   - Registra todas as requisições com o formato personalizado

2. **Logs de Violações**: `/var/log/nginx/rate_limit_violations.log`
   - Registra apenas as requisições que excederam o limite de taxa

3. **Logs de Erro**: `/var/log/nginx/error.log`
   - Registra erros do Nginx, incluindo mensagens sobre limitação de taxa

## Formato de Log Personalizado

```nginx
log_format rate_limit_log '$remote_addr - [$time_local] "$request" '
                          'rate_limited status=$status '
                          'user_agent="$http_user_agent" '
                          'referer="$http_referer"';
```

Este formato inclui:
- Endereço IP do cliente
- Timestamp da requisição
- Detalhes da requisição (método, URL, protocolo)
- Status HTTP da resposta
- User Agent do cliente
- Referer (se disponível)

## Proteção Contra Bypass

### Uso de $binary_remote_addr

O uso de `$binary_remote_addr` em vez de `$remote_addr` é mais eficiente em termos de memória e previne ataques que tentam esgotar a memória da zona de limitação.

### Configurações de Proxy

```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

Estas configurações garantem que o endereço IP real do cliente seja preservado corretamente quando a requisição passa pelo proxy.

## Monitoramento e Testes

### Script de Monitoramento

O script `monitor_rate_limit.sh` permite monitorar os logs de limitação de taxa em tempo real:

```bash
./monitor_rate_limit.sh
```

### Script de Teste Visual

O script `visual_rate_limit_test.sh` demonstra o comportamento da limitação de taxa com diferentes padrões de requisições:

```bash
./visual_rate_limit_test.sh
```

## Configuração para Ambientes de Produção

Para ambientes de produção, considere ajustar os seguintes parâmetros:

1. **Tamanho da Zona de Memória**: Aumente para valores maiores que 10MB se esperar um alto volume de clientes únicos.

2. **Taxa e Burst**: Ajuste com base nas capacidades do seu backend e nas necessidades do seu aplicativo.

3. **Zonas Múltiplas**: Considere usar zonas de limitação diferentes para diferentes endpoints ou tipos de usuários.

## Limitações e Considerações

- Esta implementação usa o endereço IP como identificador, o que pode ser restritivo para redes com NAT.
- Para aplicativos autenticados, considere usar o ID do usuário como chave de limitação em vez do IP.
- O módulo `limit_req` do Nginx é baseado no algoritmo "leaky bucket", que tem comportamentos específicos sob carga.
