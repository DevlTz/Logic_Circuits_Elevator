ENTITY decoder_2x4 is
    PORT (
        a0, a1 : IN BIT; --  entradas
        q0, q1, q2, q3 : OUT BIT -- saídas  
    );
end decoder_2x4;

ARCHITECTURE structural OF decoder_2x4 IS
    signal w0, w1 : BIT; -- sinais intermediários
begin
    -- Inversores
    w0 <= NOT a0;
    w1 <= NOT a1;
    
    -- Portas AND
    q0 <= w1 AND w0; -- 00
    q1 <= w1 AND a0; -- 01
    q2 <= a1 AND w0; -- 10
    q3 <= a1 AND a0; -- 11
END structural;

