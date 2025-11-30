library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;

entity tb_top is
end entity;

architecture sim of tb_top is
    constant CLK_PERIOD : time := 10 ns;
    constant NUM_ANDARES : integer := 32;
    constant TEMPO_PORTA_ABERTA : integer := 50;
    constant TEMPO_ENTRE_ANDARES : integer := 100;

    -- Sinais
    signal clk, rst : std_logic := '0';
    signal tb_req_ext_1, tb_req_ext_2, tb_req_ext_3 : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');
    signal tb_prox_andar_1, tb_prox_andar_2, tb_prox_andar_3 : integer range 0 to NUM_ANDARES-1;
    signal tb_pos_elevador_1, tb_pos_elevador_2, tb_pos_elevador_3 : integer range 0 to NUM_ANDARES-1;
    signal tb_estado_elevador_1, tb_estado_elevador_2, tb_estado_elevador_3 : std_logic_vector(1 downto 0);
    signal tb_elevador_pronto_1, tb_elevador_pronto_2, tb_elevador_pronto_3 : std_logic;
    signal simulacao_terminada : boolean := false;
    
    -- Arquivo de log
    file log_file : text;
    
    -- Contadores para estatísticas
    shared variable movimentos_e1, movimentos_e2, movimentos_e3 : integer := 0;
    shared variable atendimentos_e1, atendimentos_e2, atendimentos_e3 : integer := 0;

begin

    DUT : entity work.Top
        generic map (
            NUM_ANDARES => NUM_ANDARES,
            TEMPO_PORTA_ABERTA => TEMPO_PORTA_ABERTA,
            TEMPO_ENTRE_ANDARES => TEMPO_ENTRE_ANDARES
        )
        port map (
            clk => clk, rst => rst,
            req_ext_1 => tb_req_ext_1, req_ext_2 => tb_req_ext_2, req_ext_3 => tb_req_ext_3,
            prox_andar_1 => tb_prox_andar_1, prox_andar_2 => tb_prox_andar_2, prox_andar_3 => tb_prox_andar_3,
            pos_elevador_1 => tb_pos_elevador_1, pos_elevador_2 => tb_pos_elevador_2, pos_elevador_3 => tb_pos_elevador_3,
            estado_elevador_1 => tb_estado_elevador_1, estado_elevador_2 => tb_estado_elevador_2, estado_elevador_3 => tb_estado_elevador_3,
            elevador_pronto_1 => tb_elevador_pronto_1, elevador_pronto_2 => tb_elevador_pronto_2, elevador_pronto_3 => tb_elevador_pronto_3
        );

    -- Clock
    clk_process : process
    begin
        while not simulacao_terminada loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    -- Reset
    rst_process : process
    begin
        rst <= '1'; wait for 100 ns; rst <= '0';
        wait;
    end process;

    ---------------------------------------------------------------------
    -- Logger CSV: Registra apenas mudanças de estado
    ---------------------------------------------------------------------
    logger : process(clk)
        variable L : line;
        variable primeira_linha : boolean := true;
        variable last_pos_1, last_pos_2, last_pos_3 : integer := -1;
        variable last_estado_1, last_estado_2, last_estado_3 : std_logic_vector(1 downto 0) := "00";
        variable last_pronto_1, last_pronto_2, last_pronto_3 : std_logic := '0';
    begin
        if rising_edge(clk) and not simulacao_terminada then
            -- Abre arquivo na primeira vez
            if primeira_linha then
                file_open(log_file, "elevadores_log.csv", write_mode);
                write(L, string'("tempo_ns,elevador,evento,andar,estado,pronto"));
                writeline(log_file, L);
                primeira_linha := false;
            end if;
            
            -- Log E1: Mudança de posição
            if tb_pos_elevador_1 /= last_pos_1 then
                write(L, integer'image(now / 1 ns) & ",E1,MOVIMENTO," & 
                         integer'image(tb_pos_elevador_1) & "," &
                         integer'image(to_integer(unsigned(tb_estado_elevador_1))) & "," &
                         std_logic'image(tb_elevador_pronto_1)(2));
                writeline(log_file, L);
                last_pos_1 := tb_pos_elevador_1;
                movimentos_e1 := movimentos_e1 + 1;
            end if;
            
            -- Log E1: Mudança de estado
            if tb_estado_elevador_1 /= last_estado_1 then
                write(L, integer'image(now / 1 ns) & ",E1,ESTADO," & 
                         integer'image(tb_pos_elevador_1) & "," &
                         integer'image(to_integer(unsigned(tb_estado_elevador_1))) & "," &
                         std_logic'image(tb_elevador_pronto_1)(2));
                writeline(log_file, L);
                last_estado_1 := tb_estado_elevador_1;
            end if;
            
            -- Log E1: Ficou pronto
            if tb_elevador_pronto_1 = '1' and last_pronto_1 = '0' then
                write(L, integer'image(now / 1 ns) & ",E1,ATENDIMENTO," & 
                         integer'image(tb_pos_elevador_1) & "," &
                         integer'image(to_integer(unsigned(tb_estado_elevador_1))) & ",1");
                writeline(log_file, L);
                last_pronto_1 := tb_elevador_pronto_1;
                atendimentos_e1 := atendimentos_e1 + 1;
            elsif tb_elevador_pronto_1 = '0' and last_pronto_1 = '1' then
                last_pronto_1 := '0';
            end if;
            
            -- Repetir para E2
            if tb_pos_elevador_2 /= last_pos_2 then
                write(L, integer'image(now / 1 ns) & ",E2,MOVIMENTO," & 
                         integer'image(tb_pos_elevador_2) & "," &
                         integer'image(to_integer(unsigned(tb_estado_elevador_2))) & "," &
                         std_logic'image(tb_elevador_pronto_2)(2));
                writeline(log_file, L);
                last_pos_2 := tb_pos_elevador_2;
                movimentos_e2 := movimentos_e2 + 1;
            end if;
            
            if tb_estado_elevador_2 /= last_estado_2 then
                write(L, integer'image(now / 1 ns) & ",E2,ESTADO," & 
                         integer'image(tb_pos_elevador_2) & "," &
                         integer'image(to_integer(unsigned(tb_estado_elevador_2))) & "," &
                         std_logic'image(tb_elevador_pronto_2)(2));
                writeline(log_file, L);
                last_estado_2 := tb_estado_elevador_2;
            end if;
            
            if tb_elevador_pronto_2 = '1' and last_pronto_2 = '0' then
                write(L, integer'image(now / 1 ns) & ",E2,ATENDIMENTO," & 
                         integer'image(tb_pos_elevador_2) & "," &
                         integer'image(to_integer(unsigned(tb_estado_elevador_2))) & ",1");
                writeline(log_file, L);
                last_pronto_2 := tb_elevador_pronto_2;
                atendimentos_e2 := atendimentos_e2 + 1;
            elsif tb_elevador_pronto_2 = '0' and last_pronto_2 = '1' then
                last_pronto_2 := '0';
            end if;
            
            -- Repetir para E3
            if tb_pos_elevador_3 /= last_pos_3 then
                write(L, integer'image(now / 1 ns) & ",E3,MOVIMENTO," & 
                         integer'image(tb_pos_elevador_3) & "," &
                         integer'image(to_integer(unsigned(tb_estado_elevador_3))) & "," &
                         std_logic'image(tb_elevador_pronto_3)(2));
                writeline(log_file, L);
                last_pos_3 := tb_pos_elevador_3;
                movimentos_e3 := movimentos_e3 + 1;
            end if;
            
            if tb_estado_elevador_3 /= last_estado_3 then
                write(L, integer'image(now / 1 ns) & ",E3,ESTADO," & 
                         integer'image(tb_pos_elevador_3) & "," &
                         integer'image(to_integer(unsigned(tb_estado_elevador_3))) & "," &
                         std_logic'image(tb_elevador_pronto_3)(2));
                writeline(log_file, L);
                last_estado_3 := tb_estado_elevador_3;
            end if;
            
            if tb_elevador_pronto_3 = '1' and last_pronto_3 = '0' then
                write(L, integer'image(now / 1 ns) & ",E3,ATENDIMENTO," & 
                         integer'image(tb_pos_elevador_3) & "," &
                         integer'image(to_integer(unsigned(tb_estado_elevador_3))) & ",1");
                writeline(log_file, L);
                last_pronto_3 := tb_elevador_pronto_3;
                atendimentos_e3 := atendimentos_e3 + 1;
            elsif tb_elevador_pronto_3 = '0' and last_pronto_3 = '1' then
                last_pronto_3 := '0';
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------
    -- Stimulus: Apenas reports de início/fim de cada teste
    ---------------------------------------------------------------------
    stimulus : process
        procedure requisitar(
            signal req : out std_logic_vector; 
            andar : integer; 
            elev_id : string
        ) is
        begin
            req(andar) <= '1';
            report "[TESTE] " & elev_id & " requisitado para andar " & integer'image(andar) & 
                   " no tempo " & time'image(now);
            wait for 50 * CLK_PERIOD;
        end procedure;
        
        procedure esperar_pronto(
            signal pronto : in std_logic; 
            signal pos : in integer;
            andar : integer; 
            elev_id : string;
            timeout : time := 2 ms
        ) is
            variable tempo_inicio : time;
        begin
            tempo_inicio := now;
            -- Espera chegar ao andar E ficar pronto
            loop
                wait for CLK_PERIOD;
                if pos = andar and pronto = '1' then
                    report "[OK] " & elev_id & " chegou ao andar " & integer'image(andar) & 
                           " em " & time'image(now - tempo_inicio);
                    exit;
                elsif now - tempo_inicio > timeout then
                    report "[ERRO] " & elev_id & " TIMEOUT no andar " & integer'image(andar) & 
                           " (pos atual = " & integer'image(pos) & 
                           ", pronto = " & std_logic'image(pronto) & ")" severity error;
                    exit;
                end if;
            end loop;
        end procedure;
        
        procedure limpar is
        begin
            tb_req_ext_1 <= (others => '0');
            tb_req_ext_2 <= (others => '0');
            tb_req_ext_3 <= (others => '0');
            wait for 50 * CLK_PERIOD;
        end procedure;
    begin
        wait for 200 ns;
        report "=== INICIO DOS TESTES ===";
        
        -- TESTE 1
        report "--- TESTE 1: Requisicao simples E1->5 ---";
        requisitar(tb_req_ext_1, 5, "E1");
        esperar_pronto(tb_elevador_pronto_1, tb_pos_elevador_1, 5, "E1");
        limpar;
        
        -- TESTE 2
        report "--- TESTE 2: Requisicoes simultaneas ---";
        tb_req_ext_1(3) <= '1';
        tb_req_ext_2(7) <= '1';
        tb_req_ext_3(2) <= '1';
        report "[TESTE] E1->3, E2->7, E3->2";
        wait for 50 * CLK_PERIOD;
        esperar_pronto(tb_elevador_pronto_1, tb_pos_elevador_1, 3, "E1");
        esperar_pronto(tb_elevador_pronto_2, tb_pos_elevador_2, 7, "E2");
        esperar_pronto(tb_elevador_pronto_3, tb_pos_elevador_3, 2, "E3");
        limpar;
        
        -- TESTE 3
        report "--- TESTE 3: Multiplas requisicoes E1 (10 e 15) ---";
        tb_req_ext_1(10) <= '1';
        tb_req_ext_1(15) <= '1';
        wait for 50 * CLK_PERIOD;
        esperar_pronto(tb_elevador_pronto_1, tb_pos_elevador_1, 10, "E1");
        wait for 50 * CLK_PERIOD;
        esperar_pronto(tb_elevador_pronto_1, tb_pos_elevador_1, 15, "E1");
        limpar;
        
        -- TESTE 4
        report "--- TESTE 4: Descida E2->2 ---";
        requisitar(tb_req_ext_2, 2, "E2");
        esperar_pronto(tb_elevador_pronto_2, tb_pos_elevador_2, 2, "E2");
        limpar;
        
        -- TESTE 5
        report "--- TESTE 5: Stress test E3 (5->1->8) ---";
        requisitar(tb_req_ext_3, 5, "E3");
        esperar_pronto(tb_elevador_pronto_3, tb_pos_elevador_3, 5, "E3");
        tb_req_ext_3(5) <= '0';
        wait for 50 * CLK_PERIOD;
        
        requisitar(tb_req_ext_3, 1, "E3");
        esperar_pronto(tb_elevador_pronto_3, tb_pos_elevador_3, 1, "E3");
        tb_req_ext_3(1) <= '0';
        wait for 50 * CLK_PERIOD;
        
        requisitar(tb_req_ext_3, 8, "E3");
        esperar_pronto(tb_elevador_pronto_3, tb_pos_elevador_3, 8, "E3");
        limpar;
        
        wait for 100 * CLK_PERIOD;
        
        -- SUMÁRIO FINAL
        report "========================================";
        report "=== SUMARIO DA SIMULACAO ===";
        report "========================================";
        report "Estatisticas:";
        report "  E1: " & integer'image(movimentos_e1) & " movimentos, " & 
               integer'image(atendimentos_e1) & " atendimentos";
        report "  E2: " & integer'image(movimentos_e2) & " movimentos, " & 
               integer'image(atendimentos_e2) & " atendimentos";
        report "  E3: " & integer'image(movimentos_e3) & " movimentos, " & 
               integer'image(atendimentos_e3) & " atendimentos";
        report "Posicoes finais: E1=" & integer'image(tb_pos_elevador_1) & 
               " E2=" & integer'image(tb_pos_elevador_2) & 
               " E3=" & integer'image(tb_pos_elevador_3);
        report "Log detalhado salvo em: elevadores_log.csv";
        report "========================================";
        
        file_close(log_file);
        simulacao_terminada <= true;
        wait;
    end process;

end architecture;
