library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
    port(
        clk     : in  std_logic;
        reset   : in  std_logic;
        timeout : out std_logic;
        seconds : out std_logic_vector(3 downto 0)
    );
end timer;

architecture behavior of timer is
    -- Aqui é o contador de segundos, que vai de 10 a 0
    signal sec_count : unsigned(3 downto 0) := "1010";
    -- Contador grande para gerar o "segundo"
    signal big_count : unsigned(23 downto 0) := (others => '0');
begin
    process(clk, reset)
    begin
        if reset = '1' then
            sec_count <= "1010";
            big_count <= (others => '0');
        elsif rising_edge(clk) then
            if sec_count /= 0 then
                big_count <= big_count + 1;

                -- Quanto maior esse número, mais demora o segundo. É uma simulação apenas.
                if big_count = 8_000_000 then
                    big_count <= (others => '0');
                    sec_count <= sec_count - 1;
                end if;
            end if;
        end if;
    end process;

    seconds <= std_logic_vector(sec_count);
    timeout <= '1' when sec_count = 0 else '0';

end behavior;
