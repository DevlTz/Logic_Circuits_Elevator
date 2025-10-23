library ieee;
use ieee.std_logic_1164.all;

ENTITY reg_n IS
    -- Aqui estamos mostrando como ele pode ser adaptável para vários bits
    GENERIC (
        W : NATURAL := 16
    );
    PORT (
        d : IN STD_LOGIC_VECTOR(W-1 DOwnTO 0);
        clk : IN STD_LOGIC;
        clr : IN STD_LOGIC;
        en : IN STD_LOGIC;
        set : IN STD_LOGIC;
        shr : IN STD_LOGIC;
        shl : IN STD_LOGIC;
        q : OUT STD_LOGIC_VECTOR(W-1 DOWNTO 0)
    );
END reg_n;

ARCHITECTURE structural OF reg_n IS
    SIGNAL mux_out : STD_LOGIC_VECTOR(W-1 DOWNTO 0);
    SIGNAL q_int : STD_LOGIC_VECTOR(W-1 DOWNTO 0);
begin
    -- Mux 8x1, como na apostila para conseguir selecionar a operação
    gen_mux: FOR i IN 0 TO W-1 GENERATE
        PROCESS(d, q_int, set, clr, shr, shl)
        BEGIN
            IF set = '1' THEN
                mux_out(i) <= '1';
            ELSIF clr = '1' THEN
                mux_out(i) <= '0';
            ELSIF en = '1' THEN
                mux_out(i) <= d(i); -- Operador de carga paralela
            ELSIF shr = '1' THEN
                IF i = W-1 THEN
                    mux_out(i) <= '0'; -- Operador para entrada do shift right
                ELSE
                    mux_out(i) <= q_int(i+1);
                END IF;
            ELSIF shl = '1' THEN
                IF i = 0 THEN
                    mux_out(i) <= '0'; -- Operador paraentrada do shift left
                ELSE
                    mux_out(i) <= q_int(i-1);
                END IF;
            ELSE
                mux_out(i) <= q_int(i); -- Operador para manter conteúdo
            END IF;
        END PROCESS;
    END GENERATE;

    gen_ff: FOR i IN 0 TO W-1 GENERATE
        ff_inst: ENTITY work.ff_d_en
            PORT MAP (
                d => mux_out(i),
                clk => clk,
                clr => '0', -- Clear desativado, já que estamos usando o clr no mux
                en => '1',  -- Enable sempre ativo, já que o controle é feito no mux
                q => q_int(i),
                qn => OPEN
            );
    END GENERATE;

    q <= q_int;

END structural;
