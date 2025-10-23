--+====================================+
--| ff_d.vhd
--| D Flip-Flop with complementary outputs
--+====================================+
-- Author: Ryan Silvestre, 2025

library ieee;
use ieee.std_logic_1164.all;

ENTITY ff_d IS
    -- Parâmetros genéricos
    GENERIC (
        W : NATURAL := 16
    );

    -- Portas de entrada e saída
    PORT (
        d: IN STD_LOGIC_VECTOR(W-1 DOWNTO 0);
        clk : IN STD_LOGIC;
        q : OUT STD_LOGIC_VECTOR(W-1 DOWNTO 0);
        qn: OUT STD_LOGIC_VECTOR(W-1 DOWNTO 0);
    );
END ff_d;

ARCHITECTURE behavior OF ff_d IS
BEGIN
    -- Processo de captura do clock
    PROCESS(clk)
    BEGIN
        -- Só muda o valor na transição positiva do clock (transição de borda)
        IF rising_edge(clk) THEN
            q <= d;
            qn <= NOT d;
        END IF;
    END PROCESS;
END behavior;