ENTITY encoder_4x2 IS
    PORT (
        q0, q1, q2, q3 : IN BIT; -- entradas
        a0, a1 : OUT BIT -- saídas  
    );
end encoder_4x2;

ARCHI structural OF encoder_4x2 IS
begin
    a0 <= (q1 OR q3); -- LSB
    a1 <= (q2 OR q3); -- MSB
END structural;