library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_top is
end entity;

architecture sim of tb_top is
    constant CLK_PERIOD : time := 10 ns;
    constant NUM_ANDARES : integer := 32;
    constant TEMPO_PORTA_ABERTA : integer := 50;  -- REDUZIDO para testar mais rápido
    constant TEMPO_ENTRE_ANDARES : integer := 100;  -- REDUZIDO para testar mais rápido

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

        -- Procedure CORRIGIDA: Espera elevador chegar ao destino
        procedure espera_elevador_chegar(
            signal pos : in integer;
            signal pronto : in std_logic;
            constant destino : integer;
            constant elevador_id : integer;
            constant timeout : time := 1 ms
        ) is
            variable tempo_passado : time := 0 ns;
        begin
            report "[TB] Esperando Elevador " & integer'image(elevador_id) & 
                   " chegar ao andar " & integer'image(destino);

            -- Espera o elevador chegar E ficar pronto
            while pos /= destino or pronto /= '1' loop
                wait for CLK_PERIOD;
                tempo_passado := tempo_passado + CLK_PERIOD;
                
                if tempo_passado > timeout then
                    report "[TB] TIMEOUT! Elevador " & integer'image(elevador_id) & 
                           " nao chegou ao andar " & integer'image(destino) & 
                           " (pos atual = " & integer'image(pos) & 
                           ", pronto = " & std_logic'image(pronto) & ")" 
                           severity error;
                    exit;
                end if;
            end loop;

            if pos = destino and pronto = '1' then
                report "[TB] Elevador " & integer'image(elevador_id) & 
                       " CHEGOU ao andar " & integer'image(destino) & " e esta PRONTO";
            end if;
        end procedure;

        -- Procedure para limpar todas as requisições
        procedure limpar_requisicoes is
        begin
            tb_req_ext_1 <= (others => '0');
            tb_req_ext_2 <= (others => '0');
            tb_req_ext_3 <= (others => '0');
            wait for 10 * CLK_PERIOD;
        end procedure;

    begin
        wait for 200 ns;
        report "=== INICIO DA SIMULACAO TOP-LEVEL ===";
        wait for 100 ns;

        -- CASO 1: Requisição simples E1 -> andar 5
        report "========================================";
        report "CASO 1: Requisicao E1 -> andar 5";
        report "========================================";
        tb_req_ext_1(5) <= '1';
        wait for 50 * CLK_PERIOD;  -- Tempo para o sistema processar
        espera_elevador_chegar(tb_pos_elevador_1, tb_elevador_pronto_1, 5, 1, 500 us);
        limpar_requisicoes;
        wait for 50 * CLK_PERIOD;

        -- CASO 2: Requisições simultâneas
        report "========================================";
        report "CASO 2: Requisicoes simultaneas";
        report "========================================";
        tb_req_ext_1(3) <= '1';
        tb_req_ext_2(7) <= '1';
        tb_req_ext_3(2) <= '1';
        wait for 50 * CLK_PERIOD;
        
        espera_elevador_chegar(tb_pos_elevador_1, tb_elevador_pronto_1, 3, 1, 500 us);
        espera_elevador_chegar(tb_pos_elevador_2, tb_elevador_pronto_2, 7, 2, 500 us);
        espera_elevador_chegar(tb_pos_elevador_3, tb_elevador_pronto_3, 2, 3, 500 us);
        
        limpar_requisicoes;
        wait for 50 * CLK_PERIOD;

        -- CASO 3: Múltiplas requisições E1 (10 e 15)
        report "========================================";
        report "CASO 3: Multiplas requisicoes E1 (10 e 15)";
        report "========================================";
        tb_req_ext_1(10) <= '1';
        tb_req_ext_1(15) <= '1';
        wait for 50 * CLK_PERIOD;
        
        -- Espera chegar no primeiro andar (mais próximo = 10)
        espera_elevador_chegar(tb_pos_elevador_1, tb_elevador_pronto_1, 10, 1, 1 ms);
        wait for 50 * CLK_PERIOD;
        
        -- Espera chegar no segundo andar
        espera_elevador_chegar(tb_pos_elevador_1, tb_elevador_pronto_1, 15, 1, 1 ms);
        
        limpar_requisicoes;
        wait for 50 * CLK_PERIOD;

        -- CASO 4: Teste descida E2 -> andar 2
        report "========================================";
        report "CASO 4: Teste descida E2 -> andar 2";
        report "========================================";
        tb_req_ext_2(2) <= '1';
        wait for 50 * CLK_PERIOD;
        espera_elevador_chegar(tb_pos_elevador_2, tb_elevador_pronto_2, 2, 2, 1 ms);
        limpar_requisicoes;
        wait for 50 * CLK_PERIOD;

        -- CASO 5: Stress test E3 (5 -> 1 -> 8)
        report "========================================";
        report "CASO 5: Stress test E3 (5 -> 1 -> 8)";
        report "========================================";
        
        -- Primeiro destino: andar 5
        tb_req_ext_3(5) <= '1';
        wait for 50 * CLK_PERIOD;
        espera_elevador_chegar(tb_pos_elevador_3, tb_elevador_pronto_3, 5, 3, 500 us);
        tb_req_ext_3(5) <= '0';
        wait for 50 * CLK_PERIOD;

        -- Segundo destino: andar 1
        tb_req_ext_3(1) <= '1';
        wait for 50 * CLK_PERIOD;
        espera_elevador_chegar(tb_pos_elevador_3, tb_elevador_pronto_3, 1, 3, 1 ms);
        tb_req_ext_3(1) <= '0';
        wait for 50 * CLK_PERIOD;

        -- Terceiro destino: andar 8
        tb_req_ext_3(8) <= '1';
        wait for 50 * CLK_PERIOD;
        espera_elevador_chegar(tb_pos_elevador_3, tb_elevador_pronto_3, 8, 3, 1 ms);
        tb_req_ext_3(8) <= '0';
        wait for 50 * CLK_PERIOD;

        -- Final
        report "========================================";
        report "=== SIMULACAO CONCLUIDA COM SUCESSO ===";
        report "========================================";
        report "Posicoes finais:";
        report "  E1: " & integer'image(tb_pos_elevador_1) & 
               " (pronto=" & std_logic'image(tb_elevador_pronto_1) & ")";
        report "  E2: " & integer'image(tb_pos_elevador_2) & 
               " (pronto=" & std_logic'image(tb_elevador_pronto_2) & ")";
        report "  E3: " & integer'image(tb_pos_elevador_3) & 
               " (pronto=" & std_logic'image(tb_elevador_pronto_3) & ")";
        
        simulacao_terminada <= true;
        wait;
    end process;

    ---------------------------------------------------------------------
    -- Monitoramento detalhado
    ---------------------------------------------------------------------
    monitor : process(clk)
        variable last_pos_1, last_pos_2, last_pos_3 : integer := -1;
        variable last_pronto_1, last_pronto_2, last_pronto_3 : std_logic := '0';
    begin
        if rising_edge(clk) then
            -- Monitora mudanças de posição
            if tb_pos_elevador_1 /= last_pos_1 then
                report "[MONITOR] E1 moveu para andar " & integer'image(tb_pos_elevador_1) &
                       " | Estado: " & integer'image(to_integer(unsigned(tb_estado_elevador_1)));
                last_pos_1 := tb_pos_elevador_1;
            end if;
            
            if tb_pos_elevador_2 /= last_pos_2 then
                report "[MONITOR] E2 moveu para andar " & integer'image(tb_pos_elevador_2) &
                       " | Estado: " & integer'image(to_integer(unsigned(tb_estado_elevador_2)));
                last_pos_2 := tb_pos_elevador_2;
            end if;
            
            if tb_pos_elevador_3 /= last_pos_3 then
                report "[MONITOR] E3 moveu para andar " & integer'image(tb_pos_elevador_3) &
                       " | Estado: " & integer'image(to_integer(unsigned(tb_estado_elevador_3)));
                last_pos_3 := tb_pos_elevador_3;
            end if;

            -- Monitora mudanças no sinal 'pronto'
            if tb_elevador_pronto_1 /= last_pronto_1 then
                report "[MONITOR] E1 pronto mudou para " & std_logic'image(tb_elevador_pronto_1);
                last_pronto_1 := tb_elevador_pronto_1;
            end if;
            
            if tb_elevador_pronto_2 /= last_pronto_2 then
                report "[MONITOR] E2 pronto mudou para " & std_logic'image(tb_elevador_pronto_2);
                last_pronto_2 := tb_elevador_pronto_2;
            end if;
            
            if tb_elevador_pronto_3 /= last_pronto_3 then
                report "[MONITOR] E3 pronto mudou para " & std_logic'image(tb_elevador_pronto_3);
                last_pronto_3 := tb_elevador_pronto_3;
            end if;
        end if;
    end process;

end architecture;