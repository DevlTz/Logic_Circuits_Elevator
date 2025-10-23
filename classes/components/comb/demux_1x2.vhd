ENTITY demux_1x2 IS
    GENERIC (
        W: NATURAL := 16
    );
    PORT (
        e : IN BIT;  -- entrada
        sel: IN BIT; -- seletor
        y0: OUT BIT; -- saída y0
        y1: OUT BIT; -- saída y1
    );
end demux_1x2;

ARCHITECTURE structural OF demux_1x2 IS
BEGIN
    gen_demux: FOR i IN 0 TO W-1 GENERATE
        y0(i) <= e(i) AND NOT sel;  -- bit a bit
        y1(i) <= e(i) AND sel;
    END GENERATE;
END structural;


ARCHITECTURE behavior OF demux_1x2 IS
BEGIN
    PROCESS (e, sel)
    BEGIN
        IF (sel = '0') THEN
            y0 <= e;
            y1 <= (W-1 DOWNTO 0 => '0');
        ELSE
            y0 <= (W-1 DOWNTO 0 => '0');
            y1 <= e;
        END IF;
    END PROCESS;
END behavior;