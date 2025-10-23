entity full_adder is
    port(
        a, b, cin: in bit;
        s, cout: out bit;
    );
end full_adder;

architecture structural of full_adder is
    signal s1, c1, c2 : bit;
begin
    s1 <= a XOR b;
    c1 <= a AND b;

    s <= s1 XOR cin;
    c2 <= s1 AND cin;

    cout <= c1 OR c2;
end structural;