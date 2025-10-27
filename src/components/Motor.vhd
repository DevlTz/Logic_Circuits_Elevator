library IEEE;
use IEEE.std_logic_1164.all;

entity Motor is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        -- Entrada de comando do elevador
        comando    : in  std_logic_vector(1 downto 0);  
        -- 00 = parado, 01 = subir, 10 = descer

        -- Entrada porta
        porta : in std_logic;
        -- 1 = aberta, 0 = fechada

        -- Saída de sensor (movimento atual)
        em_movimento : out std_logic;  -- 1 = movendo, 0 = parado
        direcao      : out std_logic_vector(1 downto 0)  -- mesma codificação do comando
    );
end entity;

architecture Behavioral of Motor is
begin
    process(clk, rst)
    begin
        if rst = '1' then
        em_movimento <= '0';
        direcao <= '00';
        
        elsif rising_edge(clk) then
            if porta = '0' then -- porta fechada
                if comando = '01' then -- subir
                    em_movimento <= '1';
                    direcao <= '01';
                elsif comando = '10' then -- descer
                    em_movimento <= '1';
                    direcao <= '10';
                else -- parado
                    em_movimento <= '0';
                    direcao <= '00';
                end if;
            else -- porta aberta
                em_movimento <= '0';
                direcao <= '00';
            end if;
        end if;
    end process;
end architecture;
