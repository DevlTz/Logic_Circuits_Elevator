library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Elevador is
    generic (
        NUM_ANDARES : integer := 32;
        -- Tempo que a porta fica aberta (em ciclos de clock)
        TEMPO_PORTA_ABERTA : integer := 10000 -- Exemplo
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;

        -- Requisições
        requisicoes_escalonador : in std_logic_vector(NUM_ANDARES-1 downto 0); -- externas
        requisicoes_internas    : in std_logic_vector(NUM_ANDARES-1 downto 0); -- botões da cabine

        -- Sensores
        -- NOTA: sensor_porta_aberta e sensor_movimento NÃO SÃO MAIS ENTRADAS,
        -- vão ser gerados pelos componentes internos Motor e Porta.
        sensor_andar_atual      : in integer range 0 to NUM_ANDARES-1;

        -- Saídas para motor e porta
        comando_motor           : out std_logic_vector(1 downto 0); -- 00=parado, 01=subindo, 10=descendo
        comando_porta           : out std_logic;                    -- 0=fechada, 1=abrindo

         -- Estado interno
        andar_atual             : out integer range 0 to NUM_ANDARES-1; 
        estado_motor            : out std_logic_vector(1 downto 0); 
        estado_porta            : out std_logic                     
    );
end entity;

architecture Behavioral of Elevador is

    signal requisicoes_totais : std_logic_vector(NUM_ANDARES-1 downto 0);
    signal proximo_andar : integer range 0 to NUM_ANDARES-1 := 0;
    signal direcao_atual      : std_logic_vector(1 downto 0) := "00";
    signal contador_porta     : integer range 0 to TEMPO_PORTA_ABERTA := 0; -- Timer da porta
    signal fila_interna_reg : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');
    
    -- Estados da FSM
    type T_ESTADO is (
        IDLE,             -- Ocioso, esperando chamadas
        PREPARANDO_MOVIMENTO,   -- Porta fechada, decidindo direção e iniciando motor
        MOVENDO,          -- Motor ativo, subindo ou descendo
        FREANDO_MOTOR,    -- Comando PARAR enviado ao motor, esperando confirmação de parada
        ABRINDO_PORTA,    -- Comando ABRIR enviado à porta, esperando confirmação de abertura
        PORTA_ABERTA,     -- Porta aberta, aguardando temporizador
        FECHANDO_PORTA    -- Comando FECHAR enviado à porta, esperando confirmação de fechamento
    );
    signal estado_atual, proximo_estado : T_ESTADO := IDLE;

    component Porta is
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            abre        : in  std_logic; -- 1 = abrir, 0 = fechar
            motor_mov   : in  std_logic; -- 1 = motor em movimento, 0 = motor parado
            porta_aberta : out std_logic -- 1 = aberta, 0 = fechada
        );
    end component;

    component Motor is
        port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            comando      : in  std_logic_vector(1 downto 0);
            porta        : in  std_logic;
            em_movimento : out std_logic; -- 1 = movendo, 0 = parado
            direcao      : out std_logic_vector(1 downto 0); -- mesma codificação do comando
            freio        : out std_logic
        );
    end component;

    -- Sinais internos pra ser sensores
    signal sinal_porta_interna : std_logic;     -- ligando a saida porta_aberta da Porta_ins
    signal sinal_movimento_interno : std_logic; -- ligando a saida em_movimento do Motor_ins
    signal sinal_direcao_motor : std_logic_vector(1 downto 0); -- ligando a saida direcao do Motor_ins
    signal sinal_freio_motor : std_logic;       -- ligando a saida freio do Motor_ins
    
    signal comando_motor_s : std_logic_vector(1 downto 0);
    signal comando_porta_s : std_logic;

begin

    Porta_ins : Porta
        port map(
            clk          => clk,
            rst          => rst,
            abre         => comando_porta_s,
            motor_mov    => sinal_movimento_interno, -- Usa o sinal interno do motor
            porta_aberta => sinal_porta_interna      -- Saída vai para o sinal interno
        );

    Motor_ins : Motor
        port map(
            clk          => clk,
            rst          => rst,
            comando      => comando_motor_s,
            porta        => sinal_porta_interna,      -- Usa o sinal interno da porta
            em_movimento => sinal_movimento_interno, -- Saída vai para o sinal interno
            direcao      => sinal_direcao_motor,     -- Saída vai para o sinal interno
            freio        => sinal_freio_motor       -- Ligado a um sinal interno
        );

    requisicoes_totais <= fila_interna_reg or requisicoes_escalonador;

    -- Calcular o Próximo Andar
    -- Lógica simples: Se movendo, continua na direção. Se parado, vai para a mais próxima.
    process(requisicoes_totais, direcao_atual, sensor_andar_atual)
        variable proximo_temp : integer := sensor_andar_atual;
        variable achou_alvo : boolean := false;
        variable distancia_min : integer := NUM_ANDARES;
    begin
        -- Se estiver subindo, procura o próximo pedido ACIMA
        if direcao_atual = "01" then
            for i in sensor_andar_atual + 1 to NUM_ANDARES-1 loop
                if requisicoes_totais(i) = '1' then
                    proximo_temp := i;
                    achou_alvo := true;
                    exit; -- Sai do loop assim que achar o primeiro na direção
                end if;
            end loop;
        -- Se estiver descendo, procura o próximo pedido ABAIXO
        elsif direcao_atual = "10" then
             for i in sensor_andar_atual - 1 downto 0 loop
                if requisicoes_totais(i) = '1' then
                    proximo_temp := i;
                    achou_alvo := true;
                    exit;
                end if;
            end loop;
        end if;

        -- Se não achou alvo no sentido atual (ou está parado), procure o mais próximo
        if not achou_alvo then
            distancia_min := NUM_ANDARES; -- Reseta distância mínima
            proximo_temp := sensor_andar_atual; -- Default é ficar onde está
            achou_alvo := false; -- Garante que achou_alvo é resetado
            for i in 0 to NUM_ANDARES-1 loop
                 if requisicoes_totais(i) = '1' then
                     if abs(i - sensor_andar_atual) < distancia_min then
                         distancia_min := abs(i - sensor_andar_atual);
                         proximo_temp := i;
                         achou_alvo := true; -- Marca que achou um alvo
                     -- Se a distância for a mesma, mantém o primeiro encontrado (pode otimizar)
                     elsif abs(i- sensor_andar_atual) = distancia_min and not achou_alvo then
                         proximo_temp := i;
                         achou_alvo := true;
                     end if;
                 end if;
            end loop;
            -- Se mesmo assim não achou nenhum alvo, garante que fica no andar atual
            if not achou_alvo then
                 proximo_temp := sensor_andar_atual;
            end if;
        end if;

        proximo_andar <= proximo_temp;

    end process;


    -- Próximo Estado da FSM
    process(estado_atual, requisicoes_totais, sensor_andar_atual, sinal_porta_interna, sinal_movimento_interno, proximo_andar, contador_porta, direcao_atual)
    begin
        -- Comportamento Padrão: Manter o estado
        proximo_estado <= estado_atual;

        case estado_atual is

            when IDLE =>
                -- Se houver requisição no andar atual E a porta estiver fechada
                if requisicoes_totais(sensor_andar_atual) = '1' and sinal_porta_interna = '0' then
                    proximo_estado <= ABRINDO_PORTA;
                -- Se houver requisição em outro andar E a porta estiver fechada
                elsif requisicoes_totais /= std_logic_vector(to_unsigned(0, requisicoes_totais'length)) and sinal_porta_interna = '0' then
                    proximo_estado <= PREPARANDO_MOVIMENTO;
                end if;

            when PREPARANDO_MOVIMENTO =>
                -- Garante que a porta esteja fechada antes de mover
                if sinal_porta_interna = '0' then
                    -- Decide a direção com base no alvo
                    if proximo_andar > sensor_andar_atual then
                        proximo_estado <= MOVENDO;
                    elsif proximo_andar < sensor_andar_atual then
                        proximo_estado <= MOVENDO;
                    else -- O alvo é o andar atual
                        if requisicoes_totais(sensor_andar_atual) = '1' then
                            proximo_estado <= ABRINDO_PORTA;
                        else
                             proximo_estado <= IDLE; -- Não há mais o que fazer aqui
                        end if;
                    end if;
                -- Se a porta não estiver fechada (?), volta pra IDLE por segurança
                else
                    proximo_estado <= IDLE;
                end if;

            when MOVENDO =>
                -- Se chegou ao andar alvo
                if sensor_andar_atual = proximo_andar then
                    proximo_estado <= FREANDO_MOTOR; -- Manda parar o motor
                end if;

            when FREANDO_MOTOR =>
                -- Espera o motor confirmar que parou (sinal_movimento_interno vai para '0')
                if sinal_movimento_interno = '0' then
                     -- Se parou no andar que tinha requisição, abre a porta
                     if requisicoes_totais(sensor_andar_atual) = '1' then
                         proximo_estado <= ABRINDO_PORTA;
                     -- Se parou por outro motivo ou não há requisição neste andar
                     else
                         if requisicoes_totais /= std_logic_vector(to_unsigned(0, requisicoes_totais'length)) then
                             proximo_estado <= PREPARANDO_MOVIMENTO; -- Verifica se há outro alvo
                         else
                             proximo_estado <= IDLE;
                         end if;
                     end if;
                end if;

            when ABRINDO_PORTA =>
                -- Espera o sensor da porta confirmar que abriu
                if sinal_porta_interna = '1' then
                    proximo_estado <= PORTA_ABERTA;
                end if;

            when PORTA_ABERTA =>
                -- Espera o temporizador terminar
                if contador_porta >= TEMPO_PORTA_ABERTA then -- >= é mais seguro que =
                    proximo_estado <= FECHANDO_PORTA;
                end if;
                -- TODO: Sensor de presença para manter aberta ( NÂO TENHO CERTEZA SE A GENTE CONSEGUE ISSO ANTES DE TUDO, MAS>>>>>>>...)

            when FECHANDO_PORTA =>
                -- Espera o sensor da porta confirmar que fechou
                if sinal_porta_interna = '0' then
                    -- Decide o que fazer depois de fechar
                    if requisicoes_totais /= std_logic_vector(to_unsigned(0, requisicoes_totais'length)) then
                         proximo_estado <= PREPARANDO_MOVIMENTO; -- tem mais trabalho para ser feito // avisa
                    else
                         proximo_estado <= IDLE;           -- Voltar ao parado
                    end if;
                end if;
                -- TODO: Sensor de obstrução para reabrir (Mesma coisinha do uqe falei ali em cima... '-')

            when others =>
                proximo_estado <= IDLE;

        end case;
    end process;

    process(clk, rst)
    begin
        if rst = '1' then
            estado_atual <= IDLE;
            contador_porta <= 0;
            direcao_atual <= "00";
            fila_interna_reg <= (others => '0'); -- Limpa a fila no rst
        elsif rising_edge(clk) then
            -- Atualiza o Estado Atual
            estado_atual <= proximo_estado;

            fila_interna_reg <= fila_interna_reg or requisicoes_internas;
            
            if proximo_estado = ABRINDO_PORTA then
                fila_interna_reg(sensor_andar_atual) <= '0';
            end if;

            -- Atualiza a Direção Atual (apenas quando começa a mover)
            if (estado_atual = PREPARANDO_MOVIMENTO and proximo_estado = MOVENDO) then
                 if proximo_andar > sensor_andar_atual then
                     direcao_atual <= "01";
                 elsif proximo_andar < sensor_andar_atual then
                     direcao_atual <= "10";
                 else
                     direcao_atual <= "00"; -- Caso não deva mover
                 end if;
            -- Zera a direção quando efetivamente para (transição para IDLE ou ABRIR)
            elsif proximo_estado = IDLE or proximo_estado = ABRINDO_PORTA then
                 direcao_atual <= "00";
            end if;

            -- Lógica do Contador da Porta
            if estado_atual = PORTA_ABERTA then
                if contador_porta < TEMPO_PORTA_ABERTA then
                    contador_porta <= contador_porta + 1;
                end if;
            else
                contador_porta <= 0; -- Zera o contador em qualquer outro estado
            end if;

        end if;
    end process;

    -- Lógica de Saída pra definir Comandos e Status Externo
    process(estado_atual, direcao_atual, sensor_andar_atual, sinal_porta_interna)
    begin
        -- Saídas de Comando (Defaults)
        comando_motor_s <= "00"; -- Default: Parado
        comando_porta_s <= '0';  -- Default: Fechar/Manter Fechada

        -- Define comandos com base no estado atual
        case estado_atual is
            when IDLE =>
                comando_motor_s <= "00";
                comando_porta_s <= '0';
            when PREPARANDO_MOVIMENTO =>
                comando_motor_s <= "00";
                comando_porta_s <= '0';
            when MOVENDO =>
                comando_motor_s <= direcao_atual; -- Envia comando SUBIR ou DESCER
                comando_porta_s <= '0';
            when FREANDO_MOTOR =>
                comando_motor_s <= "00"; -- Envia comando PARAR
                comando_porta_s <= '0';
            when ABRINDO_PORTA =>
                comando_motor_s <= "00";
                comando_porta_s <= '1';  -- Envia comando ABRIR
            when PORTA_ABERTA =>
                comando_motor_s <= "00";
                comando_porta_s <= '1';  -- Mantém comando ABRIR
            when FECHANDO_PORTA =>
                comando_motor_s <= "00";
                comando_porta_s <= '0';  -- Envia comando FECHAR
            when others =>
                comando_motor_s <= "00";
                comando_porta_s <= '0';
        end case;

        -- Saídas de Status Externas
        andar_atual  <= sensor_andar_atual;      -- Volta o andar lido do sensor externo
        estado_porta <= sinal_porta_interna;     -- Diz o estado da porta lido
        estado_motor <= direcao_atual;           -- Diz o movimento da fsm

    end process;
    comando_motor <= comando_motor_s;
    comando_porta <= comando_porta_s;

end architecture Behavioral;