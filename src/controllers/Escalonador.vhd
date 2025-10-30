library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Escalonador is
    port (
        clk : in std_logic;
        rst : in std_logic;

        -- Posições dos elevadores
        pos_elevador_1 : in integer range 0 to 31;
        pos_elevador_2 : in integer range 0 to 31;
        pos_elevador_3 : in integer range 0 to 31;

        -- Estados dos elevadores
        estado_elevador_1 : in std_logic_vector(1 downto 0);
        estado_elevador_2 : in std_logic_vector(1 downto 0);
        estado_elevador_3 : in std_logic_vector(1 downto 0);

        -- Requisições dos andares
        requisicoes_externas_elevador_1 : in std_logic_vector(31 downto 0);
        requisicoes_externas_elevador_2 : in std_logic_vector(31 downto 0);
        requisicoes_externas_elevador_3 : in std_logic_vector(31 downto 0);

        -- Saídas
        requisicao_andar_elevador_1 : out integer range 0 to 31;
        requisicao_andar_elevador_2 : out integer range 0 to 31;
        requisicao_andar_elevador_3 : out integer range 0 to 31
    );
end entity;

architecture Behavioral of Escalonador is
    
    type t_requisicoes is array(0 to 31) of integer range 0 to 31;
    
    function calc_req(
        requisicoes_externas : std_logic_vector(31 downto 0);
        pos_elevador : integer range 0 to 31;
        estado_elevador : std_logic_vector(1 downto 0);
        pos : integer
    ) return integer is
        
        variable requisicoes : t_requisicoes := (others => 0);
        variable ordem_subida, ordem_descida : t_requisicoes := (others => 0);
        variable i, j : integer;
        variable idx_sub, idx_des, idx_total : integer := 0;
        variable prox_andar : integer := pos_elevador;
        variable temp : integer;

    begin
        -- Separando requisições 
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
        
        -- Ordenação subida (crescente)
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

        -- Ordenação descida (decrescente)
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

        -- Juntando tudo baseado no estado
        if estado_elevador = "01" then  -- Subindo
            for i in 0 to idx_sub - 1 loop
                requisicoes(idx_total) := ordem_subida(i);
                idx_total := idx_total + 1;
            end loop;

            for i in 0 to idx_des - 1 loop
                requisicoes(idx_total) := ordem_descida(i);
                idx_total := idx_total + 1;
            end loop;
            
        elsif estado_elevador = "10" then  -- Descendo
            for i in 0 to idx_des - 1 loop
                requisicoes(idx_total) := ordem_descida(i);
                idx_total := idx_total + 1;
            end loop;

            for i in 0 to idx_sub - 1 loop
                requisicoes(idx_total) := ordem_subida(i);
                idx_total := idx_total + 1;
            end loop;
            
        else  -- Parado - pode escolher qualquer direção
            for i in 0 to idx_sub - 1 loop
                requisicoes(idx_total) := ordem_subida(i);
                idx_total := idx_total + 1;
            end loop;

            for i in 0 to idx_des - 1 loop
                requisicoes(idx_total) := ordem_descida(i);
                idx_total := idx_total + 1;
            end loop;
        end if;

        -- Retorna próximo andar
        if idx_total > 0 and pos <= idx_total - 1 then
            prox_andar := requisicoes(pos);
        else 
            prox_andar := pos_elevador;
        end if;
        
        return prox_andar;
    end function;

begin

    process(clk, rst)
        variable idx_count_1 : integer := 0;
        variable idx_count_2 : integer := 0;
        variable idx_count_3 : integer := 0;
    begin 
        if rst = '1' then
            requisicao_andar_elevador_1 <= 0;
            requisicao_andar_elevador_2 <= 0;
            requisicao_andar_elevador_3 <= 0;
            idx_count_1 := 0;
            idx_count_2 := 0;
            idx_count_3 := 0;
            
        elsif rising_edge(clk) then
            requisicao_andar_elevador_1 <= calc_req(requisicoes_externas_elevador_1, pos_elevador_1, estado_elevador_1, idx_count_1);
            requisicao_andar_elevador_2 <= calc_req(requisicoes_externas_elevador_2, pos_elevador_2, estado_elevador_2, idx_count_2);
            requisicao_andar_elevador_3 <= calc_req(requisicoes_externas_elevador_3, pos_elevador_3, estado_elevador_3, idx_count_3);
            
            idx_count_1 := idx_count_1 + 1;
            idx_count_2 := idx_count_2 + 1;
            idx_count_3 := idx_count_3 + 1;
        end if;
    end process;
    
end Behavioral;