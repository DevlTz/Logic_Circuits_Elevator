library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_motor is
end tb_motor;

architecture sim of tb_motor is
    signal clk, rst : std_logic := '0';
    signal comando  : std_logic_vector(1 downto 0) := "00";
    signal porta    : std_logic := '0';
    signal em_movimento : std_logic;
    signal direcao      : std_logic_vector(1 downto 0);
    signal freio        : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin
    DUT : entity work.Motor
        port map (
            clk => clk,
            rst => rst,
            comando => comando,
            porta => porta,
            em_movimento => em_movimento,
            direcao => direcao,
            freio => freio
        );

    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    stim_proc : process
    begin
        -- Reset
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        -- TESTE 1: Subir (porta fechada)
        report "TESTE 1: Comando SUBIR";
        comando <= "01"; 
        porta <= '0';
        wait for 100 ns;
        
        assert em_movimento = '1' and direcao = "01"
            report "ERRO: Motor deveria estar subindo!"
            severity error;
        report "TESTE 1 PASSOU: Motor subindo corretamente";

        -- TESTE 2: Parar (comando 00)
        report "TESTE 2: Comando PARAR";
        comando <= "00"; 
        wait for 200 ns; -- Espera frenagem (10 ciclos + margem)
        
        assert em_movimento = '0' and direcao = "00" and freio = '0'
            report "ERRO: Motor deveria estar parado!"
            severity error;
        report "TESTE 2 PASSOU: Motor parou corretamente";

        -- TESTE 3: Descer
        report "TESTE 3: Comando DESCER";
        comando <= "10"; 
        wait for 100 ns;
        
        assert em_movimento = '1' and direcao = "10"
            report "ERRO: Motor deveria estar descendo!"
            severity error;
        report "TESTE 3 PASSOU: Motor descendo corretamente";

        -- TESTE 4: Porta aberta (deve frear IMEDIATAMENTE)
        report "TESTE 4: Porta aberta durante movimento";
        porta <= '1';
        wait for 50 ns; -- Deve entrar em FREANDO
        
        assert freio = '1'
            report "ERRO: Motor deveria estar freando!"
            severity error;
        report "TESTE 4 PASSOU: Motor freou com porta aberta";
        
        wait for 200 ns; -- Espera frenagem completa
        
        assert em_movimento = '0'
            report "ERRO: Motor deveria ter parado apos frenagem!"
            severity error;
        report "Motor parou apos frenagem";

        -- TESTE 5: Tentar mover com porta aberta (nao deve mover)
        report "TESTE 5: Comando com porta aberta";
        comando <= "01";
        porta <= '1';
        wait for 100 ns;
        
        assert em_movimento = '0'
            report "ERRO: Motor nao deveria mover com porta aberta!"
            severity error;
        report "TESTE 5 PASSOU: Motor bloqueado com porta aberta";

        report "========== TODOS OS TESTES CONCLUIDOS ==========";
        wait;
    end process;
end sim;
