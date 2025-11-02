library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_top is
end entity;

architecture sim of tb_top is
    constant CLK_PERIOD : time := 10 ns;
    constant NUM_ANDARES : integer := 32;
    constant TEMPO_PORTA_ABERTA : integer := 10000;  -- 100 us
    constant TEMPO_ENTRE_ANDARES : integer := 1000;  -- 10 us por andar

    -- Sinais de clock e reset
    signal clk, rst : std_logic := '0';

    -- Sinais de requisições externas (ENTRADAS no DUT)
    signal tb_req_ext_1 : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');
    signal tb_req_ext_2 : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');
    signal tb_req_ext_3 : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');

    -- Sinais de monitoramento (SAÍDAS do DUT)
    signal tb_prox_andar_1, tb_prox_andar_2, tb_prox_andar_3 : integer range 0 to NUM_ANDARES-1;
    signal tb_pos_elevador_1, tb_pos_elevador_2, tb_pos_elevador_3 : integer range 0 to NUM_ANDARES-1;
    signal tb_estado_elevador_1, tb_estado_elevador_2, tb_estado_elevador_3 : std_logic_vector(1 downto 0);
    signal tb_elevador_pronto_1, tb_elevador_pronto_2, tb_elevador_pronto_3 : std_logic;
    
    signal simulacao_terminada : boolean := false;

begin

    ---------------------------------------------------------------------
    -- Instância do Top-level (DUT)
    ---------------------------------------------------------------------
    DUT : entity work.Top
        generic map (
            NUM_ANDARES => NUM_ANDARES,
            TEMPO_PORTA_ABERTA => TEMPO_PORTA_ABERTA,
            TEMPO_ENTRE_ANDARES => TEMPO_ENTRE_ANDARES
        )
        port map (
            clk => clk,
            rst => rst,
            
            -- ENTRADAS: Requisições externas
            req_ext_1 => tb_req_ext_1,
            req_ext_2 => tb_req_ext_2,
            req_ext_3 => tb_req_ext_3,
            
            -- SAÍDAS: Monitoramento
            prox_andar_1 => tb_prox_andar_1,
            prox_andar_2 => tb_prox_andar_2,
            prox_andar_3 => tb_prox_andar_3,
            
            pos_elevador_1 => tb_pos_elevador_1,
            pos_elevador_2 => tb_pos_elevador_2,
            pos_elevador_3 => tb_pos_elevador_3,
            
            estado_elevador_1 => tb_estado_elevador_1,
            estado_elevador_2 => tb_estado_elevador_2,
            estado_elevador_3 => tb_estado_elevador_3,
            
            elevador_pronto_1 => tb_elevador_pronto_1,
            elevador_pronto_2 => tb_elevador_pronto_2,
            elevador_pronto_3 => tb_elevador_pronto_3
        );

    ---------------------------------------------------------------------
    -- Geração de clock
    ---------------------------------------------------------------------
    clk_process : process
    begin
        while not simulacao_terminada loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    ---------------------------------------------------------------------
    -- Reset inicial
    ---------------------------------------------------------------------
    rst_process : process
    begin
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        report "=== RESET FINALIZADO ===";
        wait;
    end process;

    ---------------------------------------------------------------------
    -- Casos de teste
    ---------------------------------------------------------------------
    stimulus : process
        -- Procedure para esperar o elevador chegar ao destino
        procedure espera_elevador_chegar(
            signal pos : in integer;
            constant destino : integer;
            constant elevador_id : integer;
            constant timeout : time := 200 us
        ) is
            variable tempo_inicio : time;
        begin
            tempo_inicio := now;
            report "[TB] Esperando Elevador " & integer'image(elevador_id) & 
                   " chegar ao andar " & integer'image(destino);
            
            while pos /= destino loop
                wait for CLK_PERIOD;
                if (now - tempo_inicio) > timeout then
                    report "[TB] TIMEOUT! Elevador " & integer'image(elevador_id) & 
                           " nao chegou ao andar " & integer'image(destino) severity error;
                    exit;
                end if;
            end loop;
            
            report "[TB] Elevador " & integer'image(elevador_id) & 
                   " CHEGOU ao andar " & integer'image(pos);
        end procedure;
        
    begin
        wait for 200 ns;
        report "========================================";
        report "=== INICIO DA SIMULACAO TOP-LEVEL ===";
        report "========================================";
        wait for 100 ns;

        -------------------------------------------------------------------
        -- CASO 1: Requisição simples - Elevador 1 vai ao andar 5
        -------------------------------------------------------------------
        report "========================================";
        report "CASO 1: Requisicao E1 -> andar 5";
        report "========================================";
        tb_req_ext_1(5) <= '1';
        wait for 1 us;  -- Tempo para sistema processar
        
        -- Espera o elevador chegar
        espera_elevador_chegar(tb_pos_elevador_1, 5, 1, 200 us);
        
        -- Espera a porta abrir/fechar (TEMPO_PORTA_ABERTA + margem)
        wait for 120 us;
        
        -- Remove requisição
        tb_req_ext_1(5) <= '0';
        wait for 2 us;
        
        report "[TB] CASO 1 concluido - E1 final no andar " & integer'image(tb_pos_elevador_1);
        wait for 10 us;

        -------------------------------------------------------------------
        -- CASO 2: Requisições simultâneas para todos elevadores
        -------------------------------------------------------------------
        report "========================================";
        report "CASO 2: Requisicoes simultaneas";
        report "  E1 -> andar 3";
        report "  E2 -> andar 7"; 
        report "  E3 -> andar 2";
        report "========================================";
        
        tb_req_ext_1(3) <= '1';
        tb_req_ext_2(7) <= '1';
        tb_req_ext_3(2) <= '1';
        wait for 1 us;
        
        -- Espera todos chegarem (em paralelo)
        espera_elevador_chegar(tb_pos_elevador_1, 3, 1, 200 us);
        espera_elevador_chegar(tb_pos_elevador_2, 7, 2, 200 us);
        espera_elevador_chegar(tb_pos_elevador_3, 2, 3, 200 us);
        
        wait for 120 us;  -- Tempo para portas
        
        tb_req_ext_1(3) <= '0';
        tb_req_ext_2(7) <= '0';
        tb_req_ext_3(2) <= '0';
        wait for 2 us;
        
        report "[TB] CASO 2 concluido";
        report "  E1 em: " & integer'image(tb_pos_elevador_1);
        report "  E2 em: " & integer'image(tb_pos_elevador_2);
        report "  E3 em: " & integer'image(tb_pos_elevador_3);
        wait for 10 us;

        -------------------------------------------------------------------
        -- CASO 3: Múltiplas requisições no mesmo elevador (algoritmo SCAN)
        -------------------------------------------------------------------
        report "========================================";
        report "CASO 3: Multiplas requisicoes E1";
        report "  Requisicoes: andares 10 e 15";
        report "========================================";
        
        tb_req_ext_1(10) <= '1';
        tb_req_ext_1(15) <= '1';
        wait for 1 us;
        
        -- Espera passar pelo primeiro andar (10)
        espera_elevador_chegar(tb_pos_elevador_1, 10, 1, 300 us);
        wait for 120 us;  -- Porta abre/fecha
        
        -- Espera chegar no segundo andar (15)
        espera_elevador_chegar(tb_pos_elevador_1, 15, 1, 300 us);
        wait for 120 us;  -- Porta abre/fecha
        
        tb_req_ext_1(10) <= '0';
        tb_req_ext_1(15) <= '0';
        wait for 2 us;
        
        report "[TB] CASO 3 concluido - E1 em andar " & integer'image(tb_pos_elevador_1);
        wait for 10 us;

        -------------------------------------------------------------------
        -- CASO 4: Teste de descida
        -------------------------------------------------------------------
        report "========================================";
        report "CASO 4: Teste de descida - E2";
        report "  E2 em: " & integer'image(tb_pos_elevador_2) & " -> andar 2";
        report "========================================";
        
        tb_req_ext_2(2) <= '1';
        wait for 1 us;
        
        espera_elevador_chegar(tb_pos_elevador_2, 2, 2, 300 us);
        wait for 120 us;
        
        tb_req_ext_2(2) <= '0';
        wait for 2 us;
        
        report "[TB] CASO 4 concluido - E2 em andar " & integer'image(tb_pos_elevador_2);
        wait for 10 us;

        -------------------------------------------------------------------
        -- CASO 5: Stress test - requisições rápidas e consecutivas
        -------------------------------------------------------------------
        report "========================================";
        report "CASO 5: Stress test - E3";
        report "  Requisicoes: 5 -> 1 -> 8";
        report "========================================";
        
        tb_req_ext_3(5) <= '1';
        wait for 1 us;
        espera_elevador_chegar(tb_pos_elevador_3, 5, 3, 200 us);
        wait for 120 us;
        tb_req_ext_3(5) <= '0';
        
        tb_req_ext_3(1) <= '1';
        wait for 1 us;
        espera_elevador_chegar(tb_pos_elevador_3, 1, 3, 200 us);
        wait for 120 us;
        tb_req_ext_3(1) <= '0';
        
        tb_req_ext_3(8) <= '1';
        wait for 1 us;
        espera_elevador_chegar(tb_pos_elevador_3, 8, 3, 300 us);
        wait for 120 us;
        tb_req_ext_3(8) <= '0';
        
        report "[TB] CASO 5 concluido - E3 em andar " & integer'image(tb_pos_elevador_3);
        wait for 10 us;

        -------------------------------------------------------------------
        -- Resumo Final
        -------------------------------------------------------------------
        report "========================================";
        report "=== SIMULACAO CONCLUIDA COM SUCESSO ===";
        report "========================================";
        report "Posicoes finais:";
        report "  Elevador 1: andar " & integer'image(tb_pos_elevador_1);
        report "  Elevador 2: andar " & integer'image(tb_pos_elevador_2);
        report "  Elevador 3: andar " & integer'image(tb_pos_elevador_3);
        report "========================================";
        
        simulacao_terminada <= true;
        wait;
    end process;

    ---------------------------------------------------------------------
    -- Processo de monitoramento contínuo (opcional)
    ---------------------------------------------------------------------
    monitor : process(clk)
    begin
        if rising_edge(clk) then
            -- Detecta mudanças de andar
            if tb_pos_elevador_1'event then
                report "[MONITOR] E1 agora em andar " & integer'image(tb_pos_elevador_1);
            end if;
            if tb_pos_elevador_2'event then
                report "[MONITOR] E2 agora em andar " & integer'image(tb_pos_elevador_2);
            end if;
            if tb_pos_elevador_3'event then
                report "[MONITOR] E3 agora em andar " & integer'image(tb_pos_elevador_3);
            end if;
        end if;
    end process;

end architecture;