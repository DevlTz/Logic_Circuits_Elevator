--+====================================+
--| latch_d.vhd
--| D-Latch with complementary outputs 
--+====================================+
-- Author: Ryan Silvestre, 2025

library ieee;
use ieee.std_logic_1164.all;

ENTITY latch_d IS 
    -- Parâmetros genéricos
    GENERIC (
        W : NATURAL := 16
    );
    -- Portas de entrada e saída
    PORT (
        clk : IN STD_LOGIC;
        d : IN STD_LOGIC_VECTOR(W-1 DOWNTO 0);
        q : OUT STD_LOGIC_VECTOR(W-1 DOWNTO 0);
        qn : OUT STD_LOGIC_VECTOR(W-1 DOWNTO 0)
    );
END latch_d;

ARCHITECTURE behavior OF latch_d IS
BEGIN
    -- Processo do latch
    PROCESS(clk, d)
    BEGIN
        -- Quando o clock está alto, o latch captura o valor de d
        IF (clk = '1') THEN
            q <= d;
            qn <= NOT d;
        END IF;
    END PROCESS;
END behavior;

