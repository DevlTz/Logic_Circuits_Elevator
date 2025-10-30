library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_elevador is
end entity;

architecture sim of tb_elevador is

    -- Parâmetros
    constant NUM_ANDARES : integer := 8; -- Pode ajustar para teste rápido
    constant TEMPO_PORTA_ABERTA : integer := 10;

    -- Sinais
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal req_ext   : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');
    signal req_int   : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');
    signal sensor_andar : integer range 0 to NUM_ANDARES-1 := 0;

    signal cmd_motor : std_logic_vector(1 downto 0);
    signal cmd_porta : std_logic;
    signal estado_andar : integer range 0 to NUM_ANDARES-1;
    signal estado_motor : std_logic_vector(1 downto 0);
    signal estado_porta : std_logic;

begin

    -- Instancia o Elevador
    DUT: entity work.Elevador
        generic map (
            NUM_ANDARES => NUM_ANDARES,
            TEMPO_PORTA_ABERTA => TEMPO_PORTA_ABERTA
        )
        port map (
            clk => clk,
            rst => rst,
            requisicoes_escalonador => req_ext,
            requisicoes_internas    => req_int,
            sensor_andar_atual      => sensor_andar,
            comando_motor           => cmd_motor,
            comando_porta           => cmd_porta,
            andar_atual             => estado_andar,
            estado_motor            => estado_motor,
            estado_porta            => estado_porta
        );

    -- Clock 10ns
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
    stim_proc: process
    begin
        -- Reset inicial
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 10 ns;

        -- Requisições externas
        req_ext(3) <= '1'; -- Andar 3
        wait for 50 ns;
        req_ext(7) <= '1'; -- Andar 7
        wait for 50 ns;
        req_ext(1) <= '1'; -- Andar 1

        -- Requisições internas
        wait for 50 ns;
        req_int(5) <= '1'; -- Botão andar 5

        -- Simular sensor de andar (fake simplificado, sobe automaticamente para teste)
        for i in 1 to NUM_ANDARES-1 loop
            wait for 10 ns;
            sensor_andar <= i;
        end loop;

        wait for 50 ns;

        -- Fim da simulação
        wait;
    end process;

end architecture sim;
