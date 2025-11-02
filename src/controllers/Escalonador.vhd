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

        -- Requisições externas (uma por elevador)
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
    
    -- Sinais para detectar borda de subida de elevador_pronto
    signal pronto_1_anterior, pronto_2_anterior, pronto_3_anterior : std_logic := '0';
    
    -- Função que calcula o próximo andar baseado no algoritmo SCAN
    function calc_proximo_andar(
        requisicoes_externas : std_logic_vector(31 downto 0);
        pos_elevador : integer range 0 to 31;
        estado_elevador : std_logic_vector(1 downto 0);
        elevador_id : integer
    ) return integer is
        variable ordem_subida, ordem_descida : t_requisicoes := (others => 0);
        variable idx_sub, idx_des : integer := 0;
        variable prox_andar : integer := pos_elevador;
        variable temp : integer;
        variable dist_subida, dist_descida : integer;

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
                elsif i = pos_elevador then
                    -- Requisição no mesmo andar: retorna imediatamente
                    report "Escalonador E" & integer'image(elevador_id) & 
                           ": Requisicao no andar atual " & integer'image(i);
                    return i;
                end if;
            end if;
        end loop;
         
        -- Se não há requisições, mantém no andar atual
        if idx_sub = 0 and idx_des = 0 then
          --  report "Escalonador E" & integer'image(elevador_id) & 
            --       ": Sem requisicoes, mantendo em " & integer'image(pos_elevador);
            return pos_elevador;
        end if;
        
        -- Ordena requisições de subida (crescente - mais próximo primeiro)
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

        -- Ordena requisições de descida (decrescente - mais próximo primeiro)
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

        -- Decide próximo andar baseado no ALGORITMO SCAN
        if estado_elevador = "01" then
            -- SUBINDO: continua na mesma direção se houver requisições acima
            if idx_sub > 0 then
                prox_andar := ordem_subida(0);  -- Próximo andar acima
                report "Escalonador E" & integer'image(elevador_id) & 
                       ": SUBINDO de " & integer'image(pos_elevador) & 
                       " -> " & integer'image(prox_andar);
            elsif idx_des > 0 then
                prox_andar := ordem_descida(0);  -- Inverte para descer
                report "Escalonador E" & integer'image(elevador_id) & 
                       ": INVERTENDO (sobe->desce) para " & integer'image(prox_andar);
            end if;
         
        elsif estado_elevador = "10" then
            -- DESCENDO: continua na mesma direção se houver requisições abaixo
            if idx_des > 0 then
                prox_andar := ordem_descida(0);  -- Próximo andar abaixo
                report "Escalonador E" & integer'image(elevador_id) & 
                       ": DESCENDO de " & integer'image(pos_elevador) & 
                       " -> " & integer'image(prox_andar);
            elsif idx_sub > 0 then
                prox_andar := ordem_subida(0);  -- Inverte para subir
                report "Escalonador E" & integer'image(elevador_id) & 
                       ": INVERTENDO (desce->sobe) para " & integer'image(prox_andar);
            end if;
         
        else
            -- PARADO: escolhe o mais próximo (prioriza subir se empate)
            if idx_sub > 0 and idx_des > 0 then
                -- Calcula distância para ambas direções
                dist_subida := ordem_subida(0) - pos_elevador;
                dist_descida := pos_elevador - ordem_descida(0);
                
                if dist_subida <= dist_descida then
                    prox_andar := ordem_subida(0);
                    report "Escalonador E" & integer'image(elevador_id) & 
                           ": PARADO, escolhendo SUBIR para " & integer'image(prox_andar) & 
                           " (dist=" & integer'image(dist_subida) & ")";
                else
                    prox_andar := ordem_descida(0);
                    report "Escalonador E" & integer'image(elevador_id) & 
                           ": PARADO, escolhendo DESCER para " & integer'image(prox_andar) & 
                           " (dist=" & integer'image(dist_descida) & ")";
                end if;
            elsif idx_sub > 0 then
                prox_andar := ordem_subida(0);
                report "Escalonador E" & integer'image(elevador_id) & 
                       ": PARADO, iniciando SUBIDA para " & integer'image(prox_andar);
            elsif idx_des > 0 then
                prox_andar := ordem_descida(0);
                report "Escalonador E" & integer'image(elevador_id) & 
                       ": PARADO, iniciando DESCIDA para " & integer'image(prox_andar);
            end if;
        end if;
         
        return prox_andar;
    end function;

begin

    process(clk, rst)
    begin 
        if rst = '1' then
            requisicao_andar_elevador_1 <= 0;
            requisicao_andar_elevador_2 <= 0;
            requisicao_andar_elevador_3 <= 0;
            pronto_1_anterior <= '0';
            pronto_2_anterior <= '0';
            pronto_3_anterior <= '0';
            report "========== ESCALONADOR: RESET ==========";
            
        elsif rising_edge(clk) then
            
            -- Atualiza sinais para detectar bordas
            pronto_1_anterior <= elevador_pronto_1;
            pronto_2_anterior <= elevador_pronto_2;
            pronto_3_anterior <= elevador_pronto_3;
            
            -- Calcula próximo andar para cada elevador
            -- (chamado a cada ciclo, mas só muda quando requisições mudam)
            requisicao_andar_elevador_1 <= calc_proximo_andar(
                requisicoes_externas_elevador_1, 
                pos_elevador_1, 
                estado_elevador_1, 
                1
            );
            
            requisicao_andar_elevador_2 <= calc_proximo_andar(
                requisicoes_externas_elevador_2, 
                pos_elevador_2, 
                estado_elevador_2, 
                2
            );
            
            requisicao_andar_elevador_3 <= calc_proximo_andar(
                requisicoes_externas_elevador_3, 
                pos_elevador_3, 
                estado_elevador_3, 
                3
            );
            
        end if;
    end process;
    
end Behavioral;