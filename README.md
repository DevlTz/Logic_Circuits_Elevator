<div aligh=center style="padding-bottom: 80px;">
<img align="right" alt="logo imd" height="60" src="docs/assets/dimap.png">

<img align="left" alt="logo ufrn" height="60" src="docs/assets/ufrn-logo.png">
</div>

<div align=center>

#  Sistema de Controle de Elevadores em VHDL

</div>

> Para mais detalhes acesse o [relatório](docs/report/Trabalho_Circuitos.pdf).

Este repositório contém o projeto de um sistema para controle de **três elevadores** em um edifício de **32 andares (0 a 31)**, implementado na linguagem **VHDL**. O sistema utiliza uma arquitetura hierárquica de dois níveis com Máquinas de Estados Finitos (FSMs) para gerenciamento.

**Autores:** Luisa Ferreira de Souza Santos, Cícero Paulino de OLiveira Filho, Kauã do Vale Ferreira, Ryan David dos Santos Silvestre
**Professor:** Márcio Eduardo Kreutz
**Data:** Outubro de 2025

---

##  Resumo e Objetivos

O objetivo principal do projeto é desenvolver um sistema robusto e eficiente para controlar a operação de múltiplos elevadores. A arquitetura é rigidamente dividida para garantir modularidade e clareza:

1.  **Nível 1 (Controlador Local - 3x):** Gerencia as operações físicas de um elevador individual (motor, portas, registro de andar).
2.  **Nível 2 (Escalonador / Supervisor - 1x):** Gerencia todas as chamadas externas, decide qual dos três elevadores deve atender a cada requisição e distribui comandos para os controladores locais.

Todo o projeto é validado através de simulação com *testbenches* em VHDL.

---

##  Arquitetura Geral (Diagrama de Blocos)

A arquitetura segue o modelo de controle de dois níveis.

![Diagrama de blocos do sistema de controle de três elevadores.](diagrama2710.png)

### Módulos Principais

| Módulo | Função | Lógica Principal |
| :--- | :--- | :--- |
| **Escalonador (Supervisor)** | Gerencia chamadas externas, aplica o algoritmo de escalonamento e distribui requisições aos elevadores. | Lógica de seleção e FSM de alto nível. |
| **Controlador Local (3x)** | Coordena a operação de cada elevador (motor e porta). Recebe chamadas internas e requisições do Escalonador. | FSM principal com estados: `IDLE`, `MOVENDO`, `ABRINDO_PORTA`, `PORTA_ABERTA`, `FECHANDO_PORTA`. |
| **Componentes (Motor, Porta)** | Componentes "executores" que obedecem aos comandos dos Controladores Locais. | FSM para o Motor (`PARADO`, `SUBINDO`, `DESCENDO`, `FREANDO`) e lógica sequencial para a Porta. |

---

##  Interface de Sinais (Top-Level)

O módulo `top-level` é o ponto de conexão de todos os blocos. A interface de sinais inclui:

### Entradas Globais (do Testbench)
* `clk`, `rst`: Clock global e reset.
* `chamadas_externas_subir [0..30]`: Botões de subida dos andares.
* `chamadas_externas_descer [1..31]`: Botões de descida dos andares.
* `chamadas_internas_E1, E2, E3 [0..31]`: Painéis internos de cada elevador.
* `sensor_andar_E1, E2, E3 [0..31]`: Sensores de posição (simulados).

### Saídas Globais (para Displays/Testbench)
* `display_andar_E1, E2, E3`: Indicador de andar atual.
* `display_porta_E1, E2, E3`: Indicador de porta (aberta ou fechada).
* `display_direcao_E1, E2, E3`: Indicador de movimento (subindo ou descendo).

---

##  Estratégia de Escalonamento

O projeto utiliza primariamente o método de **Scan (Elevador Varredura)**.

### Método *Scan*
Consiste em percorrer todos os andares em um único sentido (para cima ou para baixo), atendendo todas as requisições no caminho. A direção só é invertida ao atingir os limites do edifício (térreo ou cobertura) ou a última requisição pendente naquela direção.

### Alternativas Consideradas e Decisão
Foram avaliadas variantes do *Scan* e a abordagem de **Precedência e Proximidade** (que analisa custo/eficiência para cada chamada).
* O **Scan** básico foi escolhido por sua simplicidade de implementação.
* A abordagem por **Proximidade e Precedência**, embora mais eficiente em termos de tempo de espera, foi considerada excessivamente complexa para a implementação estrutural em VHDL do projeto.

---

##  Parâmetros Adotados

| Parâmetro | Valor | Notas |
| :--- | :--- | :--- |
| **Número de Andares** | 32 (0 a 31) | |
| **Timer da Porta** | 250.000.000 ciclos de clock | Equivalente a 5 segundos com clock de 50MHz. |
| **Outros** | Tempos de abertura/fechamento de porta, tempo de deslocamento entre andares, etc. | Definidos nos módulos Motor e Porta. |

---

##  Instruções para Reproduzir as Simulações

```

# Clone o repositório:
git clone https://github.com/DevlTz/Logic_Circuits_Elevator.git

# Torne o script executável:
chmod u+x testbench.sh

# Rode o script
./testbench.sh

```

##  Exemplos de Simulação (Para Inclusão Futura)

O relatório final deverá incluir capturas de tela das formas de onda e a explicação detalhada de pelo menos três cenários:

* Chamadas simultâneas em andares diferentes.
* Conflito de chamadas no mesmo andar.
* Teste de segurança da porta durante o movimento do elevador.
