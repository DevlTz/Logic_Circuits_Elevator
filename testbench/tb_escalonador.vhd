library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_Escalonador is
end entity;

architecture sim of tb_Escalonador is

    constant CLK_PERIOD : time := 10 ns;

    -- sinais do testbench
    signal clk, rst : std_logic := '0';

    signal pos_elevador_1, pos_elevador_2, pos_elevador_3 : integer range 0 to 31 := 0;
    signal estado_elevador_1, estado_elevador_2, estado_elevador_3 : std_logic_vector(1 downto 0) := "00";
    signal elevador_pronto_1, elevador_pronto_2, elevador_pronto_3 : std_logic := '0';

    signal req_ext_1, req_ext_2, req_ext_3 : std_logic_vector(31 downto 0) := (others => '0');

    signal prox_andar_1, prox_andar_2, prox_andar_3 : integer range 0 to 31;

begin
    ---------------------------------------------------------------------
    -- Instancia do DUT
    ---------------------------------------------------------------------
    DUT : entity work.Escalonador
        port map (
            clk => clk,
            rst => rst,
            pos_elevador_1 => pos_elevador_1,
            estado_elevador_1 => estado_elevador_1,
            elevador_pronto_1 => elevador_pronto_1,
            pos_elevador_2 => pos_elevador_2,
            estado_elevador_2 => estado_elevador_2,
            elevador_pronto_2 => elevador_pronto_2,
            pos_elevador_3 => pos_elevador_3,
            estado_elevador_3 => estado_elevador_3,
            elevador_pronto_3 => elevador_pronto_3,
            requisicoes_externas_elevador_1 => req_ext_1,
            requisicoes_externas_elevador_2 => req_ext_2,
            requisicoes_externas_elevador_3 => req_ext_3,
            requisicao_andar_elevador_1 => prox_andar_1,
            requisicao_andar_elevador_2 => prox_andar_2,
            requisicao_andar_elevador_3 => prox_andar_3
        );

    ---------------------------------------------------------------------
    -- Geracao de clock
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
    -- Processo de estimulos (casos funcionais)
    ---------------------------------------------------------------------
    stimulus : process
    begin
        wait for 100 ns;
        report "================== INICIO DA SIMULACAO ==================";

        -------------------------------------------------------------------
        -- CASO 1: Requisicao externa simples para o elevador 1 (andar 5)
        -------------------------------------------------------------------
        req_ext_1(5) <= '1';
        report "CASO 1: Requisicao externa elevador 1 -> andar 5";
        wait for 100 ns;
        elevador_pronto_1 <= '1';  -- sinaliza pronto
        wait for CLK_PERIOD;
        elevador_pronto_1 <= '0';
        wait for 200 ns;
        req_ext_1(5) <= '0';
        wait for 200 ns;

        -------------------------------------------------------------------
        -- CASO 2: Requisicoes externas multiplas e simultaneas
        -------------------------------------------------------------------
        req_ext_1(3) <= '1';
        req_ext_2(7) <= '1';
        req_ext_3(2) <= '1';
        report "CASO 2: Requisicoes simultaneas: E1->3, E2->7, E3->2";
        wait for 100 ns;

        elevador_pronto_1 <= '1';
        elevador_pronto_2 <= '1';
        elevador_pronto_3 <= '1';
        wait for CLK_PERIOD;
        elevador_pronto_1 <= '0';
        elevador_pronto_2 <= '0';
        elevador_pronto_3 <= '0';
        wait for 200 ns;

        req_ext_1(3) <= '0';
        req_ext_2(7) <= '0';
        req_ext_3(2) <= '0';
        wait for 200 ns;

        -------------------------------------------------------------------
        -- CASO 3: SCAN - elevador subindo com multiplas requisicoes
        -------------------------------------------------------------------
        pos_elevador_1 <= 4;
        estado_elevador_1 <= "01"; -- subindo
        req_ext_1(6) <= '1';
        req_ext_1(2) <= '1';
        report "CASO 3: E1 subindo pos=4, requisicoes nos andares 2 e 6";
        wait for 100 ns;
        elevador_pronto_1 <= '1';
        wait for CLK_PERIOD;
        elevador_pronto_1 <= '0';
        wait for 200 ns;
        req_ext_1 <= (others => '0');
        wait for 200 ns;

        -------------------------------------------------------------------
        -- CASO 4: SCAN - elevador descendo com multiplas requisicoes
        -------------------------------------------------------------------
        pos_elevador_2 <= 8;
        estado_elevador_2 <= "10"; -- descendo
        req_ext_2(1) <= '1';
        req_ext_2(5) <= '1';
        report "CASO 4: E2 descendo pos=8, requisicoes nos andares 1 e 5";
        wait for 100 ns;
        elevador_pronto_2 <= '1';
        wait for CLK_PERIOD;
        elevador_pronto_2 <= '0';
        wait for 200 ns;
        req_ext_2 <= (others => '0');
        wait for 200 ns;

        -------------------------------------------------------------------
        -- CASO 5: Sem requisicoes, todos parados
        -------------------------------------------------------------------
        pos_elevador_1 <= 0;
        estado_elevador_1 <= "00";
        pos_elevador_2 <= 0;
        estado_elevador_2 <= "00";
        pos_elevador_3 <= 0;
        estado_elevador_3 <= "00";
        report "CASO 5: Sem requisicoes, elevadores parados";
        wait for 500 ns;

        report "================== FIM DA SIMULACAO ==================";
        wait;
    end process;

end architecture sim;