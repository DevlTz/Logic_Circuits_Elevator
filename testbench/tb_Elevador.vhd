library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_Elevador is
end tb_Elevador;

architecture sim of tb_Elevador is
    signal clk, rst : std_logic := '0';
    signal requisicoes_escalonador : std_logic_vector(31 downto 0) := (others => '0');
    signal requisicoes_internas    : std_logic_vector(31 downto 0) := (others => '0');
    signal sensor_andar_atual      : integer range 0 to 31 := 0;

    signal comando_motor : std_logic_vector(1 downto 0);
    signal comando_porta : std_logic;
    signal andar_atual   : integer range 0 to 31;
    signal estado_motor  : std_logic_vector(1 downto 0);
    signal estado_porta  : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin
    DUT : entity work.Elevador
        port map (
            clk => clk,
            rst => rst,
            requisicoes_escalonador => requisicoes_escalonador,
            requisicoes_internas => requisicoes_internas,
            sensor_andar_atual => sensor_andar_atual,
            comando_motor => comando_motor,
            comando_porta => comando_porta,
            andar_atual => andar_atual,
            estado_motor => estado_motor,
            estado_porta => estado_porta
        );

    clk_proc : process
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

        -- Cenário: andar atual 0, requisição pro andar 3
        sensor_andar_atual <= 0;
        requisicoes_escalonador(3) <= '1';
        wait for 200 ns;

        -- Chegou no andar 3
        sensor_andar_atual <= 3;
        requisicoes_escalonador(3) <= '0';
        wait for 200 ns;

        -- Requisição pra andar 1
        sensor_andar_atual <= 3;
        requisicoes_internas(1) <= '1';
        wait for 200 ns;

        sensor_andar_atual <= 1;
        requisicoes_internas(1) <= '0';
        wait for 200 ns;

        wait;
    end process;
end sim;
