library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_Motor is
end tb_Motor;

architecture sim of tb_Motor is
    -- Sinais locais
    signal clk, rst : std_logic := '0';
    signal comando  : std_logic_vector(1 downto 0) := "00";
    signal porta    : std_logic := '0';
    signal em_movimento : std_logic;
    signal direcao      : std_logic_vector(1 downto 0);
    signal freio        : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin
    -- DUT
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

    -- Clock
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Estímulos
    stim_proc : process
    begin
        rst <= '1';
        wait for 20 ns;
        rst <= '0';

        -- 1. Subir
        comando <= "01"; porta <= '0';
        wait for 100 ns;

        -- 2. Parar
        comando <= "00"; 
        wait for 200 ns;

        -- 3. Descer
        comando <= "10"; 
        wait for 100 ns;

        -- 4. Abrir porta (deve frear)
        porta <= '1';
        wait for 200 ns;

        wait;
    end process;
end sim;
