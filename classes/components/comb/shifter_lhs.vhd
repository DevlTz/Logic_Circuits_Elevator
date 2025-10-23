entity shifter_lhs is 
    port(
        a     : in  bit_vector(3 downto 0);
        shift : in  bit;
        s     : out bit_vector(3 downto 0)
    );
end shifter_lhs;

architecture structural OF shifter_lhs IS
    component mux_2x1
        port (
            a, b : IN BIT;
            sel  : IN BIT;
            s    : OUT BIT
        );
    end component;
begin
    -- bit 0: A(0) ou A(1)
    mux0: mux_2x1 port map(a => a(0), b => a(1), sel => shift, s => s(0));

    -- bit 1: A(1) ou A(2)
    mux1: mux_2x1 port map(a => a(1), b => a(2), sel => shift, s => s(1));

    -- bit 2: A(2) ou A(3)
    mux2: mux_2x1 port map(a => a(2), b => a(3), sel => shift, s => s(2));

    -- bit 3: A(3) ou '0'
    mux3: mux_2x1 port map(a => a(3), b => '0', sel => shift, s => s(3));
end structural;
