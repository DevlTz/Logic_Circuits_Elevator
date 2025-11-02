library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_Elevador is
end entity;

architecture sim of tb_Elevador is

    constant NUM_ANDARES_C      : integer := 8;
    constant TEMPO_PORTA_C      : integer := 50;
    constant CLK_PERIOD         : time := 10 ns;

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
    signal seg_MSD, seg_LSD     : std_logic_vector(6 downto 0);

begin
    ---------------------------------------------------------------------
    -- Instancia o DUT
    ---------------------------------------------------------------------
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
            seg_MSD                 => seg_MSD,
            seg_LSD                 => seg_LSD
        );

    ---------------------------------------------------------------------
    -- Geracao do Clock
    ---------------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    ---------------------------------------------------------------------
    -- Reset inicial
    ---------------------------------------------------------------------
    rst_process : process
    begin
        rst <= '1';
        wait for 50 ns;
        rst <= '0';
        report "=== RESET FINALIZADO ===";
        wait;
    end process;

    ---------------------------------------------------------------------
    -- Processo de estimulacao (testes funcionais)
    ---------------------------------------------------------------------
    stimulus : process
    begin
        wait for 100 ns;
        report "================== INICIO DA SIMULACAO ==================";

        -------------------------------------------------------------------
        -- CASO 1: Requisicao interna simples (andar 3)
        -------------------------------------------------------------------
        requisicoes_internas(3) <= '1';
        report "CASO 1: Requisicao interna no andar 3";
        wait for 100 ns;
        requisicoes_internas(3) <= '0';

        -- Simula o sensor indicando movimento até o andar 3
        for i in 0 to 3 loop
            sensor_andar_atual <= i;
            wait for 200 ns;
            report "Sensor -> andar " & integer'image(i);
        end loop;
        wait for 500 ns;

        -------------------------------------------------------------------
        -- CASO 2: Requisicao do escalonador (andar 6)
        -------------------------------------------------------------------
        proximo_andar_esc <= 6;
        report "CASO 2: Escalonador requisita o andar 6";
        wait for 100 ns;

        for i in 3 to 6 loop
            sensor_andar_atual <= i;
            wait for 200 ns;
            report "Sensor -> andar " & integer'image(i);
        end loop;
        wait for 500 ns;

        -------------------------------------------------------------------
        -- CASO 3: Requisicoes simultaneas internas e externas
        -------------------------------------------------------------------
        requisicoes_internas(1) <= '1';
        proximo_andar_esc <= 4;
        report "CASO 3: Requisicao interna no andar 1 e externa no andar 4";
        wait for 100 ns;
        requisicoes_internas(1) <= '0';

        -- Simula descendo pro andar 1 (CORRIGIDO)
        for i in 6 downto 1 loop
            sensor_andar_atual <= i;
            wait for 200 ns;
            report "Sensor -> andar " & integer'image(i);
        end loop;
        wait for 500 ns;

        -------------------------------------------------------------------
        -- CASO 4: Duas requisicoes internas empilhadas (andar 5 e 7)
        -------------------------------------------------------------------
        requisicoes_internas(5) <= '1';
        requisicoes_internas(7) <= '1';
        report "CASO 4: Duas requisicoes internas (andar 5 e 7)";
        wait for 100 ns;
        requisicoes_internas(5) <= '0';
        requisicoes_internas(7) <= '0';

        for i in 1 to 7 loop
            sensor_andar_atual <= i;
            wait for 200 ns;
            report "Sensor -> andar " & integer'image(i);
        end loop;
        wait for 500 ns;

        -------------------------------------------------------------------
        -- CASO 5: Escalonador manda voltar pro terreo (andar 0)
        -------------------------------------------------------------------
        proximo_andar_esc <= 0;
        report "CASO 5: Escalonador requisita retorno ao terreo (andar 0)";
        wait for 100 ns;

        -- Simula descendo para o terreo (CORRIGIDO)
        for i in 7 downto 0 loop
            sensor_andar_atual <= i;
            wait for 200 ns;
            report "Sensor -> andar " & integer'image(i);
        end loop;

        wait for 1 us;
        report "================== FIM DA SIMULACAO ==================";
        wait;
    end process;

end architecture sim;