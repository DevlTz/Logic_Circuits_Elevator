library IEEE;
use IEEE.std_logic_1164.all;

entity Porta is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        -- Entrada de comando do elevador
        abre       : in  std_logic;  -- 1 = abrir, 0 = fechar

        -- Estado atual da porta (sensor)
        porta_aberta : out std_logic  -- 1 = aberta, 0 = fechada
    );
end entity;

architecture Behavioral of Porta is
begin
    -- A lógica interna será a máquina de estados que você vai criar depois
end architecture;
