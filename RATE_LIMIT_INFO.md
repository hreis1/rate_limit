# Configuração de Rate Limiting no Nginx

Este documento explica como o rate limiting está configurado no Nginx da nossa aplicação.

## Configuração Atual

No arquivo `nginx.conf`, o rate limiting está configurado da seguinte maneira:

```nginx
# Define rate limiting zones
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=1r/s;

# Na location /
limit_req zone=api_limit burst=5 nodelay;
```

## Explicação dos Parâmetros

- **limit_req_zone**: Define uma zona de limitação de requisições
  - `$binary_remote_addr`: Chave para limitação (endereço IP do cliente)
  - `zone=api_limit:10m`: Nome da zona (api_limit) e tamanho em memória (10MB)
  - `rate=1r/s`: Taxa máxima de requisições (1 por segundo)

- **limit_req**: Aplica a limitação em uma location específica
  - `zone=api_limit`: Zona a ser usada
  - `burst=5`: Permite um burst de 5 requisições acima do limite
  - `nodelay`: Processa requisições de burst imediatamente (sem enfileiramento)

## Como Funciona

1. **Taxa Base**: O sistema permite 1 requisição por segundo por IP.
2. **Burst**: Permite até 5 requisições adicionais em rajada.
3. **Resposta de Erro**: Quando o limite é excedido, retorna código 429 com mensagem JSON.

## Visualização do Comportamento

```
Tempo (s) | Requisições | Comportamento
----------|-------------|-------------
0         | 1           | Aceita (dentro da taxa normal)
0         | 2-6         | Aceita (usando o burst de 5)
0         | 7+          | Rejeita com 429
1         | 1           | Aceita (nova janela de tempo)
```

## Monitoramento

As requisições rejeitadas podem ser monitoradas através:

1. Cabeçalhos personalizados em cada resposta:
   - `X-RateLimit-Limit: 1`

2. Logs do Nginx (quando habilitados)

## Testes Realizados

Executamos testes com a ferramenta `wrk` que mostram claramente o comportamento:
- Burst inicial de 6 requisições aceitas
- Rejeição de requisições além do limite
- Aceitação de 1 req/s quando respeitado o intervalo
