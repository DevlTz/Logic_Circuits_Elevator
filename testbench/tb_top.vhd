library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_top is
end entity;

architecture sim of tb_top is
    constant CLK_PERIOD : time := 10 ns;

    -- sinais de clock e reset (mantidos, pois o conflito é menos comum)
    signal clk, rst : std_logic := '0';

    -- SINAIS DE REQUISIÇÕES EXTERNAS (RENOMEADOS com 'tb_')
    signal tb_req_ext_1, tb_req_ext_2, tb_req_ext_3 : std_logic_vector(31 downto 0) := (others => '0');

    -- SINAIS DE MONITORAMENTO (RENOMEADOS com 'tb_')
    signal tb_prox_andar_1, tb_prox_andar_2, tb_prox_andar_3 : integer range 0 to 31;
    signal tb_pos_elevador_1, tb_pos_elevador_2, tb_pos_elevador_3 : integer range 0 to 31 := 0;
    signal tb_estado_elevador_1, tb_estado_elevador_2, tb_estado_elevador_3 : std_logic_vector(1 downto 0) := "00";
    signal tb_elevador_pronto_1, tb_elevador_pronto_2, tb_elevador_pronto_3 : std_logic := '0';

begin

    ---------------------------------------------------------------------
    -- Instancia do Top-level
    -- O lado esquerdo é o nome do PORTO do DUT, o lado direito é o SINAL do TB
    ---------------------------------------------------------------------
    DUT : entity work.Top
        port map (
            clk => clk,
            rst => rst,
            
            -- REQUISIÇÕES EXTERNAS
            req_ext_1 => tb_req_ext_1,
            req_ext_2 => tb_req_ext_2,
            req_ext_3 => tb_req_ext_3,
            
            -- SAÍDAS (MONITORAMENTO)
            prox_andar_1 => tb_prox_andar_1,
            prox_andar_2 => tb_prox_andar_2,
            prox_andar_3 => tb_prox_andar_3,
            pos_elevador_1 => tb_pos_elevador_1,
            pos_elevador_2 => tb_pos_elevador_2,
            pos_elevador_3 => tb_pos_elevador_3,
            estado_elevador_1 => tb_estado_elevador_1,
            estado_elevador_2 => tb_estado_elevador_2,
            estado_elevador_3 => tb_estado_elevador_3,
            
            -- SINAIS DE CONTROLE DO TB (entrada no DUT)
            elevador_pronto_1 => tb_elevador_pronto_1,
            elevador_pronto_2 => tb_elevador_pronto_2,
            elevador_pronto_3 => tb_elevador_pronto_3
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
    -- Casos funcionais (com os novos nomes dos sinais)
    ---------------------------------------------------------------------
    stimulus : process
    begin
        wait for 100 ns;
        report "=== INICIO DA SIMULACAO TOP-LEVEL ===";

        -- CASO 1: Requisicao simples no elevador 1
        tb_req_ext_1(5) <= '1';
        wait for 200 ns;
        tb_elevador_pronto_1 <= '1'; wait for CLK_PERIOD;
        tb_elevador_pronto_1 <= '0';
        wait for 200 ns;
        tb_req_ext_1(5) <= '0';
        wait for 200 ns;

        -- CASO 2: Requisicoes externas simultaneas para todos elevadores
        tb_req_ext_1(3) <= '1';
        tb_req_ext_2(7) <= '1';
        tb_req_ext_3(2) <= '1';
        wait for 100 ns;
        tb_elevador_pronto_1 <= '1';
        tb_elevador_pronto_2 <= '1';
        tb_elevador_pronto_3 <= '1';
        wait for CLK_PERIOD;
        tb_elevador_pronto_1 <= '0';
        tb_elevador_pronto_2 <= '0';
        tb_elevador_pronto_3 <= '0';
        wait for 200 ns;
        tb_req_ext_1 <= (others => '0');
        tb_req_ext_2 <= (others => '0');
        tb_req_ext_3 <= (others => '0');
        wait for 200 ns;

        -- CASO 3: SCAN subindo
        tb_pos_elevador_1 <= 4;
        tb_estado_elevador_1 <= "01"; -- subindo
        tb_req_ext_1(6) <= '1';
        tb_req_ext_1(2) <= '1';
        wait for 200 ns;
        tb_elevador_pronto_1 <= '1'; wait for CLK_PERIOD;
        tb_elevador_pronto_1 <= '0';
        wait for 200 ns;
        tb_req_ext_1 <= (others => '0');
        wait for 200 ns;

        -- CASO 4: SCAN descendo
        tb_pos_elevador_2 <= 8;
        tb_estado_elevador_2 <= "10"; -- descendo
        tb_req_ext_2(1) <= '1';
        tb_req_ext_2(5) <= '1';
        wait for 200 ns;
        tb_elevador_pronto_2 <= '1'; wait for CLK_PERIOD;
        tb_elevador_pronto_2 <= '0';
        wait for 200 ns;
        tb_req_ext_2 <= (others => '0');
        wait for 200 ns;

        -- CASO 5: Requisicoes misturadas para todos elevadores
        tb_pos_elevador_1 <= 2; tb_estado_elevador_1 <= "01";
        tb_pos_elevador_2 <= 6; tb_estado_elevador_2 <= "10";
        tb_pos_elevador_3 <= 0; tb_estado_elevador_3 <= "00";
        tb_req_ext_1(4) <= '1'; tb_req_ext_1(0) <= '1';
        tb_req_ext_2(3) <= '1'; tb_req_ext_2(7) <= '1';
        tb_req_ext_3(2) <= '1';
        wait for 300 ns;
        tb_elevador_pronto_1 <= '1';
        tb_elevador_pronto_2 <= '1';
        tb_elevador_pronto_3 <= '1';
        wait for CLK_PERIOD;
        tb_elevador_pronto_1 <= '0';
        tb_elevador_pronto_2 <= '0';
        tb_elevador_pronto_3 <= '0';
        wait for 300 ns;
        tb_req_ext_1 <= (others => '0'); tb_req_ext_2 <= (others => '0'); tb_req_ext_3 <= (others => '0');
        wait for 300 ns;

        -- CASO 6: Sem requisicoes, todos parados
        tb_pos_elevador_1 <= 0; tb_estado_elevador_1 <= "00";
        tb_pos_elevador_2 <= 0; tb_estado_elevador_2 <= "00";
        tb_pos_elevador_3 <= 0; tb_estado_elevador_3 <= "00";
        wait for 500 ns;

        report "=== FIM DA SIMULACAO TOP-LEVEL ===";
        wait;
    end process;

end architecture;