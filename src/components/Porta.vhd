library IEEE;
use IEEE.std_logic_1164.all;

entity Porta is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        -- Entrada de comando do elevador
        abre       : in  std_logic;  -- 1 = abrir, 0 = fechar
        
        -- Estado do motor
        motor_mov : in std_logic; -- 1 = motor em movimento, 0 = motor parado

        -- Estado atual da porta (sensor)
        porta_aberta : out std_logic;  -- 1 = aberta, 0 = fechada
    );
end entity;

architecture Behavioral of Porta is
    constant limite_tempo : unsigned(31 downto 0) := to_unsigned(250000000, 32);
    signal contador : unsigned(31 downto 0) := (others => '0');
    signal temp : std_logic := '0'
begin
    process(clk, rst)
    begin
        if rst = '1' then
            contador <= (others => '0');
            porta_aberta <= '0'; -- reset: porta fechada
            temp <= '0';
        elsif rising_edge(clk) then
            if contador < limite_tempo and temp = '1' then 
                contador <= contador + 1;
            end if;

            if abre = '1' and motor_mov = '0' and contador < limite_tempo then -- abrir
                porta_aberta <= '1';
                temp <= '1';
                contador <= (others => '0');
                
            elsif (abre = '0' and motor_mov = '0') or contador >= limite_tempo then -- fechar
                porta_aberta <= '0';
                temp <= '0';
                contador <= (others => '0');
            end if;
        end if;
    end process;        
end architecture;
