library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Porta is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        abre       : in  std_logic;
        motor_mov  : in  std_logic;
        porta_aberta : out std_logic
    );
end entity;

architecture Behavioral of Porta is
    constant limite_tempo : unsigned(31 downto 0) := to_unsigned(250000000, 32);
    signal contador : unsigned(31 downto 0) := (others => '0');
    signal contando : std_logic := '0';
    signal abre_anterior : std_logic := '0';
begin
    process(clk, rst)
    begin
        if rst = '1' then
            contador <= (others => '0');
            porta_aberta <= '0';
            contando <= '0';
            abre_anterior <= '0';
            
        elsif rising_edge(clk) then
            abre_anterior <= abre;

            -- ✅ PRIORIDADE 1: Fechamento de emergência se motor ligar
            if motor_mov = '1' then
                porta_aberta <= '0';
                contando <= '0';
                contador <= (others => '0');
                
            -- PRIORIDADE 2: Contagem do timeout
            elsif contando = '1' then
                if contador < limite_tempo then
                    contador <= contador + 1;
                else
                    -- Timeout expirou: fecha a porta
                    porta_aberta <= '0';
                    contando <= '0';
                end if;
            end if;
            
            -- PRIORIDADE 3: Borda de subida para abrir (SE motor parado)
            if abre = '1' and abre_anterior = '0' and motor_mov = '0' then
                porta_aberta <= '1';
                contador <= (others => '0');
                contando <= '1';
            end if;

            if motor_mov = '1' then
                porta_aberta <= '0';
                contando <= '0';
                contador <= (others => '0');
            end if;
        end if;
    end process;        
end architecture;
