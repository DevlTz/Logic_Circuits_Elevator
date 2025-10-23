--+====================================+
--| ff_d_en.vhd
--| D Flip-Flop with clear and enable
--+====================================+
-- Author: Ryan Silvestre, 2025

library ieee;
use ieee.std_logic_1164.all;

ENTITY ff_d_en IS
    PORT (
        d : IN STD_LOGIC;
        clk: IN STD_LOGIC;
        clr: IN STD_LOGIC;
        en : IN STD_LOGIC;
        q : OUT STD_LOGIC;
        qn: OUT STD_LOGIC
    );
END ff_d_en;

ARCHITECTURE behavior OF ff_d_en IS
BEGIN
    PROCESS(clk, clr)
    -- Importante mencionar que nesse procedimento aqui, estamos trabalhando com o rising edge.
    BEGIN
        IF (clr = '0') THEN
            q <= '0';
            qn <= '1';
        ELSIF (clk'event AND clk = '1') THEN
            IF (en = '1') THEN
                q <= d;
                qn <= NOT d;
            END IF;
        END IF;
    END PROCESS;
END behavior;
