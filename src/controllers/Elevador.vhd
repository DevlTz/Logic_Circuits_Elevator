library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Elevador is
    generic (
        NUM_ANDARES : integer := 32;
        TEMPO_PORTA_ABERTA : integer := 10000
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;

        -- Interface com escalonador
        proximo_andar_escalonador : in integer range 0 to NUM_ANDARES-1;
        requisicoes_internas      : in std_logic_vector(NUM_ANDARES-1 downto 0);

        -- Sensores
        sensor_andar_atual        : in integer range 0 to NUM_ANDARES-1;

        -- Saídas para motor e porta
        comando_motor             : out std_logic_vector(1 downto 0);
        comando_porta             : out std_logic;

        -- Sinal de sincronização com escalonador
        elevador_pronto           : out std_logic;

        -- Estado interno
        andar_atual               : out integer range 0 to NUM_ANDARES-1; 
        estado_motor              : out std_logic_vector(1 downto 0); 
        estado_porta              : out std_logic;
        em_movimento              : out std_logic;  -- NOVO: indica se motor está girando
        
        -- Display de sete segmentos
        seg_MSD                   : out std_logic_vector(6 downto 0);
        seg_LSD                   : out std_logic_vector(6 downto 0)
    );
end entity;

architecture Behavioral of Elevador is

    signal requisicoes_totais     : std_logic_vector(NUM_ANDARES-1 downto 0);
    signal proximo_andar          : integer range 0 to NUM_ANDARES-1 := 0;
    signal direcao_atual          : std_logic_vector(1 downto 0) := "00";
    signal contador_porta         : integer range 0 to TEMPO_PORTA_ABERTA := 0;
    signal fila_interna_reg       : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');
    signal fila_escalonador_reg   : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');

    
    type T_ESTADO is (
        IDLE,
        PREPARANDO_MOVIMENTO,
        MOVENDO,
        FREANDO_MOTOR,
        ABRINDO_PORTA,
        PORTA_ABERTA,
        FECHANDO_PORTA
    );
    signal estado_atual, proximo_estado : T_ESTADO := IDLE;

    component Porta is
        port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            abre         : in  std_logic;
            motor_mov    : in  std_logic;
            porta_aberta : out std_logic
        );
    end component;

    component Motor is
        port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            comando      : in  std_logic_vector(1 downto 0);
            porta        : in  std_logic;
            em_movimento : out std_logic;
            direcao      : out std_logic_vector(1 downto 0);
            freio        : out std_logic
        );
    end component;

    component SeteSeg is
        generic (
            NUM_ANDARES : integer := 32
        );
        port (
            andar_atual : in  integer range 0 to NUM_ANDARES-1;
            seg_MSD     : out std_logic_vector(6 downto 0);
            seg_LSD     : out std_logic_vector(6 downto 0)
        );
    end component;

    signal sinal_porta_interna      : std_logic;
    signal sinal_movimento_interno  : std_logic;
    signal sinal_direcao_motor      : std_logic_vector(1 downto 0);
    signal sinal_freio_motor        : std_logic;
    
    signal comando_motor_s          : std_logic_vector(1 downto 0);
    signal comando_porta_s          : std_logic;
    -- signal andar_real               : integer range 0 to NUM_ANDARES-1 := 0;

    signal destino_reg : integer range 0 to NUM_ANDARES-1 := 0;

begin

    Porta_ins : Porta
        port map(
            clk          => clk,
            rst          => rst,
            abre         => comando_porta_s,
            motor_mov    => sinal_movimento_interno,
            porta_aberta => sinal_porta_interna
        );

    Motor_ins : Motor
        port map(
            clk          => clk,
            rst          => rst,
            comando      => comando_motor_s,
            porta        => sinal_porta_interna,
            em_movimento => sinal_movimento_interno,
            direcao      => sinal_direcao_motor,
            freio        => sinal_freio_motor
        );

    SeteSeg_ins : SeteSeg
        generic map(
            NUM_ANDARES => NUM_ANDARES
        )
        port map(
            andar_atual => sensor_andar_atual,
            seg_MSD     => seg_MSD,
            seg_LSD     => seg_LSD
        );

    -- Combina todas as requisições (internas + escalonador)
    requisicoes_totais <= fila_interna_reg or fila_escalonador_reg;

    -- ===============================
    -- LÓGICA DE SELEÇÃO DO PRÓXIMO ANDAR (ALGORITMO SCAN)
    -- ===============================
    process(requisicoes_totais, direcao_atual, sensor_andar_atual)        
        variable proximo_temp : integer := 0;
        variable achou_alvo   : boolean := false;
        variable distancia_min : integer := NUM_ANDARES;
    begin
        proximo_temp := sensor_andar_atual;        
        achou_alvo := false;

        -- Se está subindo, procura próxima requisição ACIMA
        if direcao_atual = "01" then
        for i in sensor_andar_atual + 1 to NUM_ANDARES-1 loop
            if requisicoes_totais(i) = '1' then
                proximo_temp := i;
                achou_alvo := true;
                report "SCAN: Subindo - Proximo andar: " & integer'image(i);
                exit;
            end if;
        end loop;
        -- Se está descendo, procura próxima requisição ABAIXO
        elsif direcao_atual = "10" then
            for i in sensor_andar_atual - 1 downto 0 loop
                if requisicoes_totais(i) = '1' then
                    proximo_temp := i;
                    achou_alvo := true;
                    report "SCAN: Descendo - Proximo andar: " & integer'image(i);
                    exit;
                end if;
            end loop;
        end if;

        -- Se não achou no sentido atual (ou está parado), procura o mais próximo
        if not achou_alvo then
            distancia_min := NUM_ANDARES;
            proximo_temp := sensor_andar_atual;
            for i in 0 to NUM_ANDARES-1 loop
                if requisicoes_totais(i) = '1' then
                    if abs(i - sensor_andar_atual) < distancia_min then
                        distancia_min := abs(i - sensor_andar_atual);
                        proximo_temp := i;
                        achou_alvo := true;
                    end if;
                end if;
            end loop;
            
            if achou_alvo then
                report "SCAN: Mudando direcao - Proximo andar mais proximo: " & integer'image(proximo_temp);
            end if;
        end if;

        proximo_andar <= proximo_temp;
    end process;

    -- ===============================
    -- MÁQUINA DE ESTADOS - LÓGICA COMBINACIONAL
    -- ===============================
    process(estado_atual, requisicoes_totais, sensor_andar_atual, sinal_porta_interna, 
            sinal_movimento_interno, proximo_andar, contador_porta)
    begin
        proximo_estado <= estado_atual;

        case estado_atual is

            when IDLE =>
                if requisicoes_totais(sensor_andar_atual) = '1' and sinal_porta_interna = '0' then
                    proximo_estado <= ABRINDO_PORTA;
                    report "FSM: IDLE -> ABRINDO_PORTA (requisicao no andar atual)";
                elsif requisicoes_totais /= std_logic_vector(to_unsigned(0, requisicoes_totais'length)) 
                      and sinal_porta_interna = '0' then
                    proximo_estado <= PREPARANDO_MOVIMENTO;
                    report "FSM: IDLE -> PREPARANDO_MOVIMENTO (ha requisicoes pendentes)";
                end if;

            when PREPARANDO_MOVIMENTO =>
                if sinal_porta_interna = '0' then
                    if proximo_andar > sensor_andar_atual then
                        proximo_estado <= MOVENDO;
                        report "FSM: PREPARANDO_MOVIMENTO -> MOVENDO (subindo para andar " & integer'image(proximo_andar) & ")";
                    elsif proximo_andar < sensor_andar_atual then
                        proximo_estado <= MOVENDO;
                        report "FSM: PREPARANDO_MOVIMENTO -> MOVENDO (descendo para andar " & integer'image(proximo_andar) & ")";
                    elsif requisicoes_totais(sensor_andar_atual) = '1' then
                        proximo_estado <= ABRINDO_PORTA;
                        report "FSM: PREPARANDO_MOVIMENTO -> ABRINDO_PORTA (ja esta no andar)";
                    else
                        proximo_estado <= IDLE;
                        report "FSM: PREPARANDO_MOVIMENTO -> IDLE (sem requisicoes validas)";
                    end if;
                else
                    proximo_estado <= IDLE;
                    report "FSM: PREPARANDO_MOVIMENTO -> IDLE (porta ainda aberta)";
                end if;

            when MOVENDO =>
                if sensor_andar_atual = proximo_andar then
                    proximo_estado <= FREANDO_MOTOR;
                    report "FSM: MOVENDO -> FREANDO_MOTOR (chegou ao andar destino " & integer'image(proximo_andar) & ")";
                elsif requisicoes_totais(sensor_andar_atual) = '1' then
                    proximo_estado <= FREANDO_MOTOR;
                    report "FSM: MOVENDO -> FREANDO_MOTOR (parada intermediaria no andar " & integer'image(sensor_andar_atual) & ")";
                end if;

            when FREANDO_MOTOR =>
                if sinal_movimento_interno = '0' then
                    if requisicoes_totais(sensor_andar_atual) = '1' then
                        proximo_estado <= ABRINDO_PORTA;
                        report "FSM: FREANDO_MOTOR -> ABRINDO_PORTA (motor parado, abrindo porta)";
                    elsif requisicoes_totais /= std_logic_vector(to_unsigned(0, requisicoes_totais'length)) then
                        proximo_estado <= PREPARANDO_MOVIMENTO;
                        report "FSM: FREANDO_MOTOR -> PREPARANDO_MOVIMENTO (motor parado, mais requisicoes)";
                    else
                        proximo_estado <= IDLE;
                        report "FSM: FREANDO_MOTOR -> IDLE (motor parado, sem mais requisicoes)";
                    end if;
                end if;

            when ABRINDO_PORTA =>
                if sinal_porta_interna = '1' then
                    proximo_estado <= PORTA_ABERTA;
                    report "FSM: ABRINDO_PORTA -> PORTA_ABERTA (porta totalmente aberta)";
                end if;

            when PORTA_ABERTA =>
                if contador_porta >= TEMPO_PORTA_ABERTA then
                    proximo_estado <= FECHANDO_PORTA;
                    report "FSM: PORTA_ABERTA -> FECHANDO_PORTA (timeout de " & integer'image(TEMPO_PORTA_ABERTA) & " ciclos)";
                end if;

            when FECHANDO_PORTA =>
                if sinal_porta_interna = '0' then
                    if requisicoes_totais /= std_logic_vector(to_unsigned(0, requisicoes_totais'length)) then
                        proximo_estado <= PREPARANDO_MOVIMENTO;
                        report "FSM: FECHANDO_PORTA -> PREPARANDO_MOVIMENTO (porta fechada, ha mais requisicoes)";
                    else
                        proximo_estado <= IDLE;
                        report "FSM: FECHANDO_PORTA -> IDLE (porta fechada, sem mais requisicoes)";
                    end if;
                end if;

            when others =>
                proximo_estado <= IDLE;
                report "FSM: Estado invalido, voltando para IDLE" severity warning;

        end case;
    end process;

    -- ===============================
    -- PROCESSO PRINCIPAL SINCRONIZADO
    -- ===============================
    process(clk, rst)
    begin
        if rst = '1' then
            estado_atual <= IDLE;
            contador_porta <= 0;
            direcao_atual <= "00";
            fila_interna_reg <= (others => '0');
            fila_escalonador_reg <= (others => '0');
            elevador_pronto <= '0';
            report "========== RESET ATIVADO ==========";
            
        elsif rising_edge(clk) then
            estado_atual <= proximo_estado;
            
            -- Registra requisições internas
            if requisicoes_internas /= (NUM_ANDARES-1 downto 0 => '0') then
                report "Requisicoes internas recebidas";
            end if;
            fila_interna_reg <= fila_interna_reg or requisicoes_internas;
            
            -- Registra requisição do escalonador (converte integer para bit)
            if proximo_andar_escalonador /= sensor_andar_atual then
                if fila_escalonador_reg(proximo_andar_escalonador) = '0' then
                    report "Escalonador solicitou andar: " & integer'image(proximo_andar_escalonador);
                end if;
                fila_escalonador_reg(proximo_andar_escalonador) <= '1';
            end if;
            
            -- Sinaliza quando completa um atendimento
            if estado_atual = FECHANDO_PORTA and proximo_estado = IDLE then
                elevador_pronto <= '1';
                report "========== ELEVADOR PRONTO (voltando para IDLE) ==========";
            elsif estado_atual = FECHANDO_PORTA and proximo_estado = PREPARANDO_MOVIMENTO then
                elevador_pronto <= '1';
                report "========== ELEVADOR PRONTO (preparando proximo movimento) ==========";
            else
                elevador_pronto <= '0';
            end if;
            
            -- Limpa requisições atendidas quando abre a porta
            if proximo_estado = ABRINDO_PORTA and estado_atual /= ABRINDO_PORTA then
                report "Atendendo andar " & integer'image(sensor_andar_atual) & " - Limpando requisicoes";
                if requisicoes_internas(sensor_andar_atual) = '0' then
                    fila_interna_reg(sensor_andar_atual) <= '0';
                end if;
                fila_escalonador_reg(sensor_andar_atual) <= '0';
            end if;

            -- Atualiza direção quando começa a mover
            if (estado_atual = PREPARANDO_MOVIMENTO and proximo_estado = MOVENDO) then
                if proximo_andar > sensor_andar_atual then
                    direcao_atual <= "01";
                    report "Direcao definida: SUBINDO (andar atual: " & integer'image(sensor_andar_atual) & 
                           " -> destino: " & integer'image(proximo_andar) & ")";
                elsif proximo_andar < sensor_andar_atual then
                    direcao_atual <= "10";
                    report "Direcao definida: DESCENDO (andar atual: " & integer'image(sensor_andar_atual) & 
                           " -> destino: " & integer'image(proximo_andar) & ")";
                else
                    direcao_atual <= "00";
                    report "Direcao definida: PARADO";
                end if;
            elsif proximo_estado = IDLE or proximo_estado = ABRINDO_PORTA then
                direcao_atual <= "00";
            end if;

            -- Timer da porta
            if estado_atual = PORTA_ABERTA then
                if contador_porta < TEMPO_PORTA_ABERTA then
                    contador_porta <= contador_porta + 1;
                end if;
            else
                contador_porta <= 0;
            end if;

        end if;
    end process;

    -- ===============================
    -- LÓGICA DE SAÍDA PARA COMANDOS
    -- ===============================
    process(estado_atual, direcao_atual, sensor_andar_atual, sinal_porta_interna,
        sinal_direcao_motor, sinal_movimento_interno)
    begin
        comando_motor_s <= "00";
        comando_porta_s <= '0';

        case estado_atual is
            when IDLE =>
                comando_motor_s <= "00";
                comando_porta_s <= '0';
            when PREPARANDO_MOVIMENTO =>
                comando_motor_s <= "00";
                comando_porta_s <= '0';
            when MOVENDO =>
                comando_motor_s <= direcao_atual;
                comando_porta_s <= '0';
            when FREANDO_MOTOR =>
                comando_motor_s <= "00";
                comando_porta_s <= '0';
            when ABRINDO_PORTA =>
                comando_motor_s <= "00";
                comando_porta_s <= '1';
            when FECHANDO_PORTA =>
                comando_motor_s <= "00";
                comando_porta_s <= '0';
            when PORTA_ABERTA =>
                comando_motor_s <= "00";
                comando_porta_s <= '1';
            when others =>
                comando_motor_s <= "00";
                comando_porta_s <= '0';
        end case;

       andar_atual  <= sensor_andar_atual;
        estado_porta <= sinal_porta_interna;
        -- estado_motor e em_movimento serão conectados por atribuições concorrentes (abaixo)

    end process;
    
    comando_motor <= comando_motor_s;
    comando_porta <= comando_porta_s;
    estado_motor <= sinal_direcao_motor;  -- Exemplo simples de estado do motor
    em_movimento <= sinal_movimento_interno;  -- NOVO: expõe o sinal do Motor

end architecture Behavioral;
