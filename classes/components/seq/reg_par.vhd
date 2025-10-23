library ieee;
use ieee.std_logic_1164.all;

entity reg_par is
    generic ( W: natural := 8);
    port (
        d: in std_logic_vector(W-1 downto 0); -- entrada paralela de dado
        clk: in std_logic;                     -- clock
        clr: in std_logic;                     -- clear assíncrono
        load: in std_logic;                  -- load
        q: out std_logic_vector(W-1 downto 0)   -- saída do registrador
    );

end reg_par;

architecture structural of par_reg is
    signal q_int : std_logic_vector(W-1 downto 0);
    signal mux_out : std_logic_vector(W-1 downto 0);
begin
    -- choose between loading d or keeping old q_int
    gen_mux: for i in 0 to W-1 generate
    begin
        mux_out(i) <= d(i) when load = '1' else q_int(i);
    end generate;

    -- instantiate ff_d_en for each bit (assumes entity ff_d_en exists)
    gen_ff: for i in 0 to W-1 generate
    begin
        ff_inst: entity work.ff_d_en
            port map (
                d   => mux_out(i),
                clk => clk,
                clr => clrn,  -- ff_d_en treats '0' as clear
                en  => '1',   -- enable permanently 1: selection handled by mux
                q   => q_int(i),
                qn  => open
            );
    end generate;

    q <= q_int;

end architecture;