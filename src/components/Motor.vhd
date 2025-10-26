library IEEE;
use IEEE.std_logic_1164.all;

entity Motor is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        -- Entrada de comando do elevador
        comando    : in  std_logic_vector(1 downto 0);  
        -- 00 = parado, 01 = subir, 10 = descer

        -- Saída de sensor (movimento atual)
        em_movimento : out std_logic;  -- 1 = movendo, 0 = parado
        direcao      : out std_logic_vector(1 downto 0)  -- mesma codificação do comando
    );
end entity;

architecture Behavioral of Motor is
begin
    -- A lógica interna será a máquina de estados que você vai criar depois
end architecture;
