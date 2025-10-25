# Sistema Multi-Elevador com Escalonador Global

## 1. Estrutura Geral
- **Sistema:** 3 elevadores + 1 escalonador global (dispatcher).  
- **Elevadores:** “executores burros” — recebem comandos do escalonador e reportam status físico.  
- **Escalonador:** inteligente — decide qual elevador atende cada requisição externa, baseado em posição, direção e estado.  

---

## 2. Elevador (executor)
### Estados
1. **OCIOSO / PARADO** → motor desligado, portas fechadas.  
2. **MOVIMENTO (SUBINDO/DESCENDO)** → motor ligado na direção recebida.  
3. **PARADO NO ANDAR** → motor desligado, portas abertas.  
4. **PORTA ABERTA / ABRINDO / FECHANDO** → temporizador controla duração de abertura; sensor de presença mantém porta aberta se necessário.  

### Entradas
- `prox_andar` (do escalonador) → destino do elevador.  
- `s_movimento` → direção do motor (00=parado, 01=subindo, 10=descendo).  
- `andar_sensor` → sensor de piso atual.  
- `sensor_porta` → indica se a porta está aberta ou fechada.  

### Saídas
- `andar_atual` → reporta posição atual para o escalonador.  
- `estado_motor` → indica movimento atual.  
- `estado_porta` → indica estado físico da porta.  

### Regras locais
1. **Motor só se move se porta estiver fechada.**  
2. **Ao chegar no andar do pedido:** parar motor, abrir porta, iniciar temporizador.  
3. **Atualizar `andar_atual` a cada pulso de sensor**.  
4. **Fechar porta automaticamente** após temporizador, a menos que haja presença detectada ou botão de abrir/fechar.  

---

## 3. Escalonador (dispatcher global)
### Função
- Recebe todas as requisições externas (botões UP/DOWN).  
- Mantém **status de cada elevador**: posição, direção, estado, fila interna.  
- Decide **qual elevador atende qual requisição**, usando critérios de proximidade e direção.  

### Lógica de seleção
1. **Todos os elevadores no mesmo sentido:**
   - Pedido à frente → escolher o mais próximo que ainda vai passar pelo andar.  
   - Pedido atrás → esperar a inversão de sentido; escolher o que vai chegar primeiro.  
2. **Elevadores em sentidos diferentes:**  
   - Escolher o que já está indo na direção da requisição e mais próximo do andar.  
3. **Elevador ocioso disponível:**  
   - Priorizar o mais próximo do andar do pedido.  
4. **Desempate:**  
   - Preferir direção igual à requisição → distância mínima → ordem fixa (E1>E2>E3).  

### Comunicação
- Envia `prox_andar` e `s_movimento` para cada elevador.  
- Recebe `andar_atual`, `estado_motor`, `estado_porta` e novos pedidos internos de cada elevador.  

---

## 4. Fluxo de operação (resumido)
1. **Inicialização:** elevadores ociosos, portas fechadas, filas vazias.  
2. **Recepção de requisições:** atualiza fila UP/DOWN interna e global.  
3. **Decisão de direção:** manter sentido atual ou inverter, dependendo das filas.  
4. **Movimento:** motor acionado conforme `prox_andar`.  
5. **Chegada:** sensor indica andar → parar motor → abrir porta → temporizador.  
6. **Porta:** abre, mantém aberta enquanto houver presença ou comando → fecha automaticamente.  
7. **Atualização de status:** elevador reporta andar atual e estado ao escalonador.  
8. **Loop do escalonador:** verifica todas as requisições → envia novas ordens → repete.  
9. **Coordenação multi-elevador:** dispatcher decide qual elevador atende qual chamada, garantindo eficiência e evitando conflitos.  

---

## 5. Observações importantes
- **Elevadores não tomam decisões de rota**; toda lógica de escalonamento é externa.  
- **Sensores e temporizadores garantem segurança física**, independentemente das ordens.  
- **Sistema contínuo:** nunca para até desligamento manual, podendo atender requisições em tempo real.  
