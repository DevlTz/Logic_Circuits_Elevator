library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_elevador is
-- Testbench não tem portas
end entity;

architecture Behavioral of tb_elevador is

    -- Parâmetros
    constant NUM_ANDARES : integer := 8;
    constant TEMPO_PORTA_ABERTA : integer := 10;

    -- Sinais do DUT
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';

    signal requisicoes_escalonador : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');
    signal requisicoes_internas    : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');
    signal sensor_andar_atual      : integer range 0 to NUM_ANDARES-1 := 0;

    signal comando_motor : std_logic_vector(1 downto 0);
    signal comando_porta : std_logic;
    signal andar_atual   : integer range 0 to NUM_ANDARES-1;
    signal estado_motor  : std_logic_vector(1 downto 0);
    signal estado_porta  : std_logic;

begin

    -- Instancia o DUT
    DUT : entity work.Elevador
        generic map(
            NUM_ANDARES => NUM_ANDARES,
            TEMPO_PORTA_ABERTA => TEMPO_PORTA_ABERTA
        )
        port map(
            clk => clk,
            rst => rst,
            requisicoes_escalonador => requisicoes_escalonador,
            requisicoes_internas    => requisicoes_internas,
            sensor_andar_atual      => sensor_andar_atual,
            comando_motor           => comando_motor,
            comando_porta           => comando_porta,
            andar_atual             => andar_atual,
            estado_motor            => estado_motor,
            estado_porta            => estado_porta
        );

    -- Clock
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    -- Estímulos
    stim_proc : process
    begin
        -- Reset inicial
        rst <= '1';
        wait for 20 ns;
        rst <= '0';

        -- Simula uma requisição externa para o andar 3
        requisicoes_escalonador <= (others => '0');
        requisicoes_escalonador(3) <= '1';
        wait for 100 ns;

        -- Simula uma requisição interna para o andar 6
        requisicoes_internas <= (others => '0');
        requisicoes_internas(6) <= '1';
        wait for 150 ns;

        -- Muda o sensor de andar (simula movimento do elevador)
        sensor_andar_atual <= 1;
        wait for 20 ns;
        sensor_andar_atual <= 2;
        wait for 20 ns;
        sensor_andar_atual <= 3; -- Chegou no andar solicitado
        wait for 50 ns;
        sensor_andar_atual <= 4;
        wait for 20 ns;
        sensor_andar_atual <= 5;
        wait for 20 ns;
        sensor_andar_atual <= 6; -- Chegou no andar solicitado interno
        wait for 50 ns;

        -- Final da simulação
        wait;
    end process;

end architecture Behavioral;
