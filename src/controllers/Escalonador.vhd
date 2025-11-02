library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Escalonador is
    port (
        clk : in std_logic;
        rst : in std_logic;

        -- Entradas do Elevador 1
        pos_elevador_1 : in integer range 0 to 31;
        estado_elevador_1 : in std_logic_vector(1 downto 0);
        elevador_pronto_1 : in std_logic;
        
        -- Entradas do Elevador 2
        pos_elevador_2 : in integer range 0 to 31;
        estado_elevador_2 : in std_logic_vector(1 downto 0);
        elevador_pronto_2 : in std_logic; 
        
        -- Entradas do Elevador 3
        pos_elevador_3 : in integer range 0 to 31;
        estado_elevador_3 : in std_logic_vector(1 downto 0);
        elevador_pronto_3 : in std_logic; 

        -- Requisições externas (uma por elevador - distribuição feita pelo top level)
        requisicoes_externas_elevador_1 : in std_logic_vector(31 downto 0);
        requisicoes_externas_elevador_2 : in std_logic_vector(31 downto 0);
        requisicoes_externas_elevador_3 : in std_logic_vector(31 downto 0);

        -- Saídas: próximo andar para cada elevador
        requisicao_andar_elevador_1 : out integer range 0 to 31;
        requisicao_andar_elevador_2 : out integer range 0 to 31;
        requisicao_andar_elevador_3 : out integer range 0 to 31
    );
end entity;

architecture Behavioral of Escalonador is
    type t_requisicoes is array(0 to 31) of integer range 0 to 31;
    
    -- Função que calcula o próximo andar baseado no algoritmo SCAN
    function calc_req(
        requisicoes_externas : std_logic_vector(31 downto 0);
        pos_elevador : integer range 0 to 31;
        estado_elevador : std_logic_vector(1 downto 0);
        pos : integer;
        elevador_id : integer
    ) return integer is
        variable requisicoes : t_requisicoes := (others => 0);
        variable ordem_subida, ordem_descida : t_requisicoes := (others => 0);
        variable i, j : integer;
        variable idx_sub, idx_des, idx_total : integer := 0;
        variable prox_andar : integer := pos_elevador;
        variable temp : integer;

    begin
        -- Separa requisições em subida e descida relativas à posição atual
        for i in 0 to 31 loop
            if requisicoes_externas(i) = '1' then
                if i > pos_elevador then
                    ordem_subida(idx_sub) := i;
                    idx_sub := idx_sub + 1;
                elsif i < pos_elevador then
                    ordem_descida(idx_des) := i;
                    idx_des := idx_des + 1;
                end if;
            end if;
        end loop;
         
        -- Ordena requisições de subida (crescente)
        if idx_sub > 1 then
            for i in 0 to idx_sub - 2 loop
                for j in 0 to idx_sub - i - 2 loop
                    if ordem_subida(j) > ordem_subida(j+1) then
                        temp := ordem_subida(j);
                        ordem_subida(j) := ordem_subida(j+1);
                        ordem_subida(j+1) := temp;
                    end if;
                end loop;   
            end loop;
        end if;

        -- Ordena requisições de descida (decrescente)
        if idx_des > 1 then
            for i in 0 to idx_des - 2 loop
                for j in 0 to idx_des - i - 2 loop
                    if ordem_descida(j) < ordem_descida(j+1) then
                        temp := ordem_descida(j);
                        ordem_descida(j) := ordem_descida(j+1);
                        ordem_descida(j+1) := temp;
                    end if;
                end loop;
            end loop;
        end if;

        -- Monta fila de requisições baseada na direção atual (ALGORITMO SCAN)
        if estado_elevador = "01" then
            -- Subindo: primeiro continua subindo, depois desce
            for i in 0 to idx_sub - 1 loop
                requisicoes(idx_total) := ordem_subida(i);
                idx_total := idx_total + 1;
            end loop;
            for i in 0 to idx_des - 1 loop
                requisicoes(idx_total) := ordem_descida(i);
                idx_total := idx_total + 1;
            end loop;
         
        elsif estado_elevador = "10" then
            -- Descendo: primeiro continua descendo, depois sobe
            for i in 0 to idx_des - 1 loop
                requisicoes(idx_total) := ordem_descida(i);
                idx_total := idx_total + 1;
            end loop;
            for i in 0 to idx_sub - 1 loop
                requisicoes(idx_total) := ordem_subida(i);
                idx_total := idx_total + 1;
            end loop;
         
        else
            -- Parado: prioriza subida, depois descida
            for i in 0 to idx_sub - 1 loop
                requisicoes(idx_total) := ordem_subida(i);
                idx_total := idx_total + 1;
            end loop;
            for i in 0 to idx_des - 1 loop
                requisicoes(idx_total) := ordem_descida(i);
                idx_total := idx_total + 1;
            end loop;
        end if;

        -- Retorna o andar na posição da fila
        if idx_total > 0 and pos < idx_total then
            prox_andar := requisicoes(pos);
            report "Escalonador Elevador " & integer'image(elevador_id) & 
                   ": Fila pos " & integer'image(pos) & " = Andar " & integer'image(prox_andar);
        else 
            prox_andar := pos_elevador;
            if idx_total = 0 then
                report "Escalonador Elevador " & integer'image(elevador_id) & 
                       ": Sem requisicoes, mantendo no andar " & integer'image(pos_elevador);
            else
                report "Escalonador Elevador " & integer'image(elevador_id) & 
                       ": Fim da fila (pos=" & integer'image(pos) & ", total=" & 
                       integer'image(idx_total) & "), mantendo no andar " & integer'image(pos_elevador);
            end if;
        end if;
         
        return prox_andar;
    end function;

begin

    process(clk, rst)
        variable idx_count_1 : integer range 0 to 31 := 0;
        variable idx_count_2 : integer range 0 to 31 := 0;
        variable idx_count_3 : integer range 0 to 31 := 0;
    begin 
        if rst = '1' then
            requisicao_andar_elevador_1 <= 0;
            requisicao_andar_elevador_2 <= 0;
            requisicao_andar_elevador_3 <= 0;
            idx_count_1 := 0;
            idx_count_2 := 0;
            idx_count_3 := 0;
            report "========== ESCALONADOR: RESET ==========";
            
        elsif rising_edge(clk) then
            
            -- Avança contador quando elevador sinaliza pronto
            if elevador_pronto_1 = '1' then
                report "Escalonador: Elevador 1 PRONTO, avancando contador de " & 
                       integer'image(idx_count_1) & " para " & integer'image(idx_count_1 + 1);
                idx_count_1 := idx_count_1 + 1;
            end if;
            
            if elevador_pronto_2 = '1' then
                report "Escalonador: Elevador 2 PRONTO, avancando contador de " & 
                       integer'image(idx_count_2) & " para " & integer'image(idx_count_2 + 1);
                idx_count_2 := idx_count_2 + 1;
            end if;
            
            if elevador_pronto_3 = '1' then
                report "Escalonador: Elevador 3 PRONTO, avancando contador de " & 
                       integer'image(idx_count_3) & " para " & integer'image(idx_count_3 + 1);
                idx_count_3 := idx_count_3 + 1;
            end if;
            
            -- CORREÇÃO CRÍTICA: Reseta contador quando não há mais requisições
            if requisicoes_externas_elevador_1 = (31 downto 0 => '0') then
                if idx_count_1 /= 0 then
                    report "Escalonador: Elevador 1 - Sem requisicoes, resetando contador";
                end if;
                idx_count_1 := 0;
            end if;
            
            if requisicoes_externas_elevador_2 = (31 downto 0 => '0') then
                if idx_count_2 /= 0 then
                    report "Escalonador: Elevador 2 - Sem requisicoes, resetando contador";
                end if;
                idx_count_2 := 0;
            end if;
            
            if requisicoes_externas_elevador_3 = (31 downto 0 => '0') then
                if idx_count_3 /= 0 then
                    report "Escalonador: Elevador 3 - Sem requisicoes, resetando contador";
                end if;
                idx_count_3 := 0;
            end if;
            
            -- Calcula próximo andar para cada elevador
            requisicao_andar_elevador_1 <= calc_req(
                requisicoes_externas_elevador_1, 
                pos_elevador_1, 
                estado_elevador_1, 
                idx_count_1,
                1
            );
            
            requisicao_andar_elevador_2 <= calc_req(
                requisicoes_externas_elevador_2, 
                pos_elevador_2, 
                estado_elevador_2, 
                idx_count_2,
                2
            );
            
            requisicao_andar_elevador_3 <= calc_req(
                requisicoes_externas_elevador_3, 
                pos_elevador_3, 
                estado_elevador_3, 
                idx_count_3,
                3
            );
            
        end if;
    end process;
    
end Behavioral;