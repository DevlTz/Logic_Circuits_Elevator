# Relatório Geral do Trabalho

## 1. Resumo e Objetivos

O objetivo deste projeto é projetar e implementar em VHDL um sistema para controlar 3 elevadores em um edifício de 32 andares (0 a 31). O sistema é dividido em dois níveis hierárquicos, conforme especificado:

1.  **Nível 1 (Controlador Local):** Um controlador individual para cada elevador, responsável por gerenciar as operações físicas como acionar o motor, controlar a abertura e fechamento das portas, e registrar o andar atual.
2.  **Nível 2 (Escalonador / Pai):** Um supervisor global que gerencia todas as chamadas externas (botões de subir/descer dos andares), decide qual dos três elevadores deve atender a cada requisição e envia os comandos para os controladores locais.

O projeto faz uso das Máquinas de Estados Finitos (FSMs) para o controle dos componentes e que vão ser validados através de simulação com testbenches em VHDL.

---

## 2. Arquitetura Geral (Diagrama de Blocos)
A arquitetura do sistema segue o modelo Controlador de dois níveis exigido. O diagrama de blocos abaixo ilustra a conexão dos módulos principais:

![Diagrama](../diagramas_projeto/diagrama2710.png)

A arquitetura é composta por:

* **1x Módulo Escalonador (Supervisor):**
    * **Entradas:** `clk`, `rst`, todas as `Chamadas Externas (subir/descer)` e os sinais de `Status` (andar atual, direção, estado da porta) de todos os 3 elevadores.
    * **Lógica:** Implementará o algoritmo de escalonamento (descrito na Seção 4) para decidir qual elevador atenderá a chamada.
    * **Status Atual:** O arquivo `src/controllers/Escalonador.vhd` existe como um esqueleto (`entity`), e a lógica (arquitetura) está em fase de projeto.
* **3x Módulos Controladores Locais (Elevador):**
    * **Função:** O "cérebro" de cada elevador. Recebe `Chamadas Internas` e `Requisições` do Escalonador. Lê os `Sensores` e envia `Comandos` ao Motor e à Porta.
    * **Lógica Planejada:** Será implementado como uma FSM principal para gerenciar os estados: `IDLE` (Ocioso), `MOVENDO`, `ABRINDO_PORTA`, `PORTA_ABERTA` e `FECHANDO_PORTA`.
    * **Status Atual:** O arquivo `src/controllers/Elevador.vhd` existe, mas a lógica atual é só o protótipo inicial e será substituída pela FSM planejada.

* **3x Módulos de Componentes (Motor, Porta):**
    * São os "músculos" (componentes "burros") que obedecem aos comandos dos Controladores Locais.
    * O **Motor** possui sua própria FSM interna para garantir operação segura (ex: `PARADO`, `SUBINDO`, `DESCENDO`, `FREANDO`).

---

## 3. Interface de sinais usadas

A interface de sinais planejada para o módulo `top-level` (que conectará todos os blocos) é baseada nos arquivos `.vhd` existentes:

**Entradas Globais (do Testbench):**
* `clk`, `rst`: Clock global e reset.
* `chamadas_externas_subir [0..30]`: Botões de subida dos andares.
* `chamadas_externas_descer [1..31]`: Botões de descida dos andares.
* `chamadas_internas_E1, E2, E3 [0..31]`: Painéis internos de cada elevador.
* `sensor_andar_E1, E2, E3 [0..31]`: Sensores de posição (simulados).

**Saídas Globais (para Displays/Testbench):**
* `display_andar_E1, E2, E3`: Indicador de andar atual.
* `display_porta_E1, E2, E3`: Indicador de porta (aberta/fechada).
* `display_direcao_E1, E2, E3`: Indicador de movimento (subindo/descendo).

**Sinais Internos Chave (Entre Módulos):**
* `req_do_escal_E*`: Saída do Escalonador para a entrada do Controlador Local.
* `cmd_motor_E*`: Saída do Controlador Local para a entrada `comando` do Motor.
* `cmd_porta_E*`: Saída do Controlador Local para a entrada `abre` da Porta.
* `sensor_mov_E*`: Saída `em_movimento` do Motor, ligada de volta ao Controlador Local.
* `sensor_porta_E*`: Saída `porta_aberta` da Porta, ligada de volta ao Controlador Local (e ao Motor para segurança).

---


## 4. Estratégia de Escalonamento


---

## 5. Parâmetros adotados 

- **(nº de andares, tempos, etc.).**

---

## 6. Exemplos de simulação

- **Pelo menos três cenários com
capturas de forma de onda e explicação step-by-step
(ex.: chamada simultânea em andares diferentes).**

---

## 7. Problemas encontrados e decisões de projeto.


---

## 8. Instruções para reproduzir simulações.