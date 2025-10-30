library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_Porta is
end tb_Porta;

architecture sim of tb_Porta is
    signal clk, rst : std_logic := '0';
    signal abre, motor_mov : std_logic := '0';
    signal porta_aberta : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin
    DUT : entity work.Porta
        port map (
            clk => clk,
            rst => rst,
            abre => abre,
            motor_mov => motor_mov,
            porta_aberta => porta_aberta
        );

    clk_gen : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    stim_proc : process
    begin
        rst <= '1';
        wait for 20 ns;
        rst <= '0';

        -- 1. Abrir porta (motor parado)
        abre <= '1'; motor_mov <= '0';
        wait for 100 ns;

        -- 2. Tentar abrir com motor em movimento (não deve abrir)
        abre <= '1'; motor_mov <= '1';
        wait for 100 ns;

        -- 3. Fechar porta
        abre <= '0'; motor_mov <= '0';
        wait for 100 ns;

        wait;
    end process;
end sim;
