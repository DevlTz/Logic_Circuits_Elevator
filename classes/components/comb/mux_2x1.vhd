ENTITY mux_2x1 IS
	GENERIC (
		W: NATURAL := 16
	);
	PORT (
		a,b : IN BIT_VECTOR(W-1 DOWNTO 0);
		sel : IN BIT;
		s : OUT BIT_VECTOR(W-1 DOWNTO 0)
	);
END mux_2x1;

ARCHITECTURE structural OF mux_2x1 IS
BEGIN
    gen_mux: FOR i IN 0 TO W-1 GENERATE
        s(i) <= (a(i) AND NOT sel) OR (b(i) AND sel);
    END GENERATE;
END structural;

ARCHITECTURE behavior OF mux_2x1 IS
BEGIN
    PROCESS(a,b,sel)
	begin
		if(sel = '0') then
			s <= a;
		else 
			s <= b;
		end if;
	end process;
end behavior;