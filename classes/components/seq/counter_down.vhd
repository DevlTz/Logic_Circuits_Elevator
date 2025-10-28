library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counter_down is
    generic (W : natural := 4);
    port (
        d     : in  std_logic_vector(W - 1 downto 0);
        clk   : in  std_logic;
        clrn  : in  std_logic;
        cnt   : in  std_logic;
        load  : in  std_logic;
        q     : out std_logic_vector(W - 1 downto 0)
    );
end counter_down;

architecture behavior of counter_down is
    signal q_reg: std_logic_vector(W - 1 downto 0);
begin
    process (clk, clrn)
    begin
        if (clrn = '0') then
            q_reg <= (others => '0');
        elsif rising_edge(clk) then
            if (cnt = '1') then
                if (load = '1') then
                    q_reg <= d;
                else
                    q_reg <= std_logic_vector(unsigned(q_reg) - 1);
                end if;
            end if;
        end if;
    end process;

    q <= q_reg;
end behavior;
