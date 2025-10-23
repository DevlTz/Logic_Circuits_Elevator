entity full_sub is
    port(
        a,b,bin : in bit;
        d, bout : out bit
    );
end full_sub;

architecture structural of full_sub is
    signal d1, b1, b2 : bit;
begin
    d1 <= a XOR b;
    b1 <= NOT a AND b;
    b2 <= d1 AND bin;

    d <= d1 XOR bin;
    bout <= b1 OR b2;
end structural;