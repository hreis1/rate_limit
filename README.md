# Demonstração de API com Limitação de Taxa

Este projeto demonstra uma implementação simples de API com limitação de taxa usando:
- Ruby com framework Sinatra
- Nginx para limitação de taxa
- Docker Compose para orquestração

## Limites de Taxa

A API implementa o seguinte limite de taxa:
- 1 requisição por segundo com pico de 5 requisições

Quando os limites de taxa são excedidos, a API retorna um código de status 429 com uma mensagem.

## Endpoints Disponíveis

- `GET /`: Retorna uma resposta JSON com status da API, mensagem de boas-vindas, hora atual e versão

## Executando a Aplicação

```bash
docker compose up
```

A API estará disponível em http://localhost:9999

## Testando a Limitação de Taxa

O repositório inclui scripts para testar e visualizar a funcionalidade de limitação de taxa:

```bash
# Instalar a ferramenta wrk (ferramenta de benchmark HTTP)
sudo apt-get install -y wrk

# Executar o script de teste visual
./visual_rate_limit_test.sh
```

O script de teste executa três testes:
1. 10 requisições imediatas - demonstra o limite de pico
2. 5 requisições com 1 segundo de intervalo - demonstra o funcionamento normal
3. Teste de carga com wrk - demonstra o comportamento sob alta carga

Consulte o arquivo `RATE_LIMIT_INFO.md` para mais detalhes sobre a configuração da limitação de taxa.
