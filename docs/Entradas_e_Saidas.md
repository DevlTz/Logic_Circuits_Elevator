# Resumo de Entradas e Saídas dos Módulos

## Motor
**Entradas:**
- clk : std_logic  
- rst : std_logic  
- comando : std_logic_vector(1 downto 0)  (00=parado, 01=subir, 10=descer)  

**Saídas:**
- em_movimento : std_logic  (1 = movendo, 0 = parado)  
- direcao : std_logic_vector(1 downto 0)  (mesma codificação do comando)  

---

## Painel
**Entradas:**
- clk : std_logic  
- rst : std_logic  
- andar : integer 0..31 (botão pressionado)  
- press : std_logic (1 = botão pressionado)  

**Saídas:**
- requisicao : std_logic_vector(31 downto 0)  (bit correspondente ao andar solicitado)  

---

## Porta
**Entradas:**
- clk : std_logic  
- rst : std_logic  
- abre : std_logic  (1 = abrir, 0 = fechar)  

**Saídas:**
- porta_aberta : std_logic  (1 = aberta, 0 = fechada)  

---

## Elevador
**Entradas:**
- clk : std_logic  
- rst : std_logic  
- requisicoes_escalonador : std_logic_vector(31 downto 0)  (externas)  
- requisicoes_internas : std_logic_vector(31 downto 0)  (botões da cabine)  
- sensor_andar_atual : integer 0..31  
- sensor_porta_aberta : std_logic  
- sensor_movimento : std_logic  

**Saídas:**
- comando_motor : std_logic_vector(1 downto 0)  (00=parado, 01=subindo, 10=descendo)  
- comando_porta : std_logic  (0=fechada, 1=abrindo)  
- andar_atual : integer 0..31  
- estado_motor : std_logic_vector(1 downto 0)  
- estado_porta : std_logic  

---

## Escalonador
**Entradas:**
- clk : std_logic  
- rst : std_logic  
- pos_elevador_1 : integer 0..10  
- pos_elevador_2 : integer 0..10  
- pos_elevador_3 : integer 0..10  
- estado_elevador_1 : std_logic_vector(1 downto 0)  
- estado_elevador_2 : std_logic_vector(1 downto 0)  
- estado_elevador_3 : std_logic_vector(1 downto 0)  
- requisicoes_externas_elevador_1 : std_logic_vector(31 downto 0)  
- requisicoes_externas_elevador_2 : std_logic_vector(31 downto 0)  
- requisicoes_externas_elevador_3 : std_logic_vector(31 downto 0)  

**Saídas:**
- requisicao_andar_elevador_1 : integer 0..10  
- requisicao_andar_elevador_2 : integer 0..10  
- requisicao_andar_elevador_3 : integer 0..10  
