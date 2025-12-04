library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_Elevador is
end entity;

architecture sim of tb_Elevador is
    constant NUM_ANDARES_C : integer := 8;
    constant TEMPO_PORTA_C : integer := 50;
    constant CLK_PERIOD    : time := 10 ns;
    constant CICLOS_POR_ANDAR : integer := 100; -- Tempo para trocar de andar

    signal clk, rst             : std_logic := '0';
    signal requisicoes_internas : std_logic_vector(NUM_ANDARES_C-1 downto 0) := (others => '0');
    signal proximo_andar_esc    : integer range 0 to NUM_ANDARES_C-1 := 0;
    signal sensor_andar_atual   : integer range 0 to NUM_ANDARES_C-1 := 0;

    signal comando_motor        : std_logic_vector(1 downto 0);
    signal comando_porta        : std_logic;
    signal elevador_pronto      : std_logic;
    signal andar_atual          : integer range 0 to NUM_ANDARES_C-1;
    signal estado_motor         : std_logic_vector(1 downto 0);
    signal estado_porta         : std_logic;
    signal em_movimento         : std_logic; -- Adicionado
    signal seg_MSD, seg_LSD     : std_logic_vector(6 downto 0);

    -- Sinais para simular movimento físico
    signal contador_movimento : integer := 0;

begin
    DUT : entity work.Elevador
        generic map (
            NUM_ANDARES => NUM_ANDARES_C,
            TEMPO_PORTA_ABERTA => TEMPO_PORTA_C
        )
        port map (
            clk                     => clk,
            rst                     => rst,
            proximo_andar_escalonador => proximo_andar_esc,
            requisicoes_internas    => requisicoes_internas,
            sensor_andar_atual      => sensor_andar_atual,
            comando_motor           => comando_motor,
            comando_porta           => comando_porta,
            elevador_pronto         => elevador_pronto,
            andar_atual             => andar_atual,
            estado_motor            => estado_motor,
            estado_porta            => estado_porta,
            em_movimento            => em_movimento, -- Conectado
            seg_MSD                 => seg_MSD,
            seg_LSD                 => seg_LSD
        );

    -- Clock
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Reset
    rst_process : process
    begin
        rst <= '1';
        wait for 50 ns;
        rst <= '0';
        report "=== RESET FINALIZADO ===";
        wait;
    end process;

    movimento_fisico : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sensor_andar_atual <= 0;
                contador_movimento <= 0;
            else
                -- Se motor está em movimento, simula troca de andar
                if comando_motor = "01" then -- Subindo
                    if contador_movimento < CICLOS_POR_ANDAR then
                        contador_movimento <= contador_movimento + 1;
                    else
                        if sensor_andar_atual < NUM_ANDARES_C - 1 then
                            sensor_andar_atual <= sensor_andar_atual + 1;
                            report "Sensor: Subiu para andar " & integer'image(sensor_andar_atual + 1);
                        end if;
                        contador_movimento <= 0;
                    end if;
                    
                elsif comando_motor = "10" then -- Descendo
                    if contador_movimento < CICLOS_POR_ANDAR then
                        contador_movimento <= contador_movimento + 1;
                    else
                        if sensor_andar_atual > 0 then
                            sensor_andar_atual <= sensor_andar_atual - 1;
                            report "Sensor: Desceu para andar " & integer'image(sensor_andar_atual - 1);
                        end if;
                        contador_movimento <= 0;
                    end if;
                    
                else -- Motor parado
                    contador_movimento <= 0;
                end if;
            end if;
        end if;
    end process;

    -- Estímulos
    stimulus : process
    begin
        wait for 100 ns;
        report "================== INICIO DA SIMULACAO ==================";

        -- CASO 1: Requisição interna simples (andar 3)
        report "CASO 1: Requisicao interna no andar 3";
        requisicoes_internas(3) <= '1';
        wait for 50 ns;
        requisicoes_internas(3) <= '0';
        
        -- Espera elevador chegar e abrir porta
        wait until sensor_andar_atual = 3;
        report "Chegou ao andar 3";
        wait until estado_porta = '1';
        report "Porta abriu no andar 3";
        wait until estado_porta = '0';
        report "Porta fechou";
        wait for 200 ns;

        -- CASO 2: Requisição do escalonador (andar 6)
        report "CASO 2: Escalonador requisita o andar 6";
        proximo_andar_esc <= 6;
        wait for 100 ns;
        
        wait until sensor_andar_atual = 6;
        report "Chegou ao andar 6";
        wait until estado_porta = '1';
        report "Porta abriu no andar 6";
        wait until estado_porta = '0';
        report "Porta fechou";
        wait for 200 ns;

        -- CASO 3: Voltar para andar 1
        report "CASO 3: Requisicao para andar 1";
        requisicoes_internas(1) <= '1';
        wait for 50 ns;
        requisicoes_internas(1) <= '0';
        
        wait until sensor_andar_atual = 1;
        report "Chegou ao andar 1";
        wait for 500 ns;

        -- CASO 4: Múltiplas requisições (andar 5 e 7)
        report "CASO 4: Duas requisicoes (andar 5 e 7)";
        requisicoes_internas(5) <= '1';
        requisicoes_internas(7) <= '1';
        wait for 50 ns;
        requisicoes_internas(5) <= '0';
        requisicoes_internas(7) <= '0';
        
        wait until sensor_andar_atual = 5;
        report "Parada no andar 5";
        wait for 500 ns;
        
        wait until sensor_andar_atual = 7;
        report "Chegou ao andar 7";
        wait for 500 ns;

        -- CASO 5: Retorno ao térreo
        report "CASO 5: Retorno ao terreo";
        proximo_andar_esc <= 0;
        wait for 100 ns;
        
        wait until sensor_andar_atual = 0;
        report "Retornou ao terreo";

        wait for 1 us;
        report "================== FIM DA SIMULACAO ==================";
        wait;
    end process;

end architecture sim;
