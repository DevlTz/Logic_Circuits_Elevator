library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Top is
    generic (
        NUM_ANDARES : integer := 32;
        TEMPO_PORTA_ABERTA : integer := 10000
    );
    port (
        clk : in std_logic;
        rst : in std_logic
    );
end entity;

architecture Behavioral of Top is

    -- Sinais comuns
    signal prox_andar_1, prox_andar_2, prox_andar_3 : integer range 0 to NUM_ANDARES-1;
    signal estado_motor_1, estado_motor_2, estado_motor_3 : std_logic_vector(1 downto 0);
    signal elevador_pronto_1, elevador_pronto_2, elevador_pronto_3 : std_logic;
    signal andar_atual_1, andar_atual_2, andar_atual_3 : integer range 0 to NUM_ANDARES-1;

    -- Requisições internas simuladas (podem ser modificadas dinamicamente)
    signal requisicoes_internas_1, requisicoes_internas_2, requisicoes_internas_3 : std_logic_vector(NUM_ANDARES-1 downto 0);

    -- Requisições externas (podem ser ligadas ao dispatcher ou testbench)
    signal req_ext_1, req_ext_2, req_ext_3 : std_logic_vector(NUM_ANDARES-1 downto 0);

    -- Comandos de motor/porta
    signal comando_motor_1, comando_motor_2, comando_motor_3 : std_logic_vector(1 downto 0);
    signal comando_porta_1, comando_porta_2, comando_porta_3 : std_logic;

    -- Display 7 segmentos (opcional)
    signal seg_MSD_1, seg_LSD_1 : std_logic_vector(6 downto 0);
    signal seg_MSD_2, seg_LSD_2 : std_logic_vector(6 downto 0);
    signal seg_MSD_3, seg_LSD_3 : std_logic_vector(6 downto 0);

begin

    -- =============================
    -- Instancia dos Elevadores
    -- =============================
    E1 : entity work.Elevador
        generic map (
            NUM_ANDARES => NUM_ANDARES,
            TEMPO_PORTA_ABERTA => TEMPO_PORTA_ABERTA
        )
        port map (
            clk => clk,
            rst => rst,
            proximo_andar_escalonador => prox_andar_1,
            requisicoes_internas => requisicoes_internas_1,
            sensor_andar_atual => andar_atual_1,
            comando_motor => comando_motor_1,
            comando_porta => comando_porta_1,
            elevador_pronto => elevador_pronto_1,
            andar_atual => andar_atual_1,
            estado_motor => estado_motor_1,
            estado_porta => open, -- pode criar sinal se necessário
            seg_MSD => seg_MSD_1,
            seg_LSD => seg_LSD_1
        );

    E2 : entity work.Elevador
        generic map (
            NUM_ANDARES => NUM_ANDARES,
            TEMPO_PORTA_ABERTA => TEMPO_PORTA_ABERTA
        )
        port map (
            clk => clk,
            rst => rst,
            proximo_andar_escalonador => prox_andar_2,
            requisicoes_internas => requisicoes_internas_2,
            sensor_andar_atual => andar_atual_2,
            comando_motor => comando_motor_2,
            comando_porta => comando_porta_2,
            elevador_pronto => elevador_pronto_2,
            andar_atual => andar_atual_2,
            estado_motor => estado_motor_2,
            estado_porta => open,
            seg_MSD => seg_MSD_2,
            seg_LSD => seg_LSD_2
        );

    E3 : entity work.Elevador
        generic map (
            NUM_ANDARES => NUM_ANDARES,
            TEMPO_PORTA_ABERTA => TEMPO_PORTA_ABERTA
        )
        port map (
            clk => clk,
            rst => rst,
            proximo_andar_escalonador => prox_andar_3,
            requisicoes_internas => requisicoes_internas_3,
            sensor_andar_atual => andar_atual_3,
            comando_motor => comando_motor_3,
            comando_porta => comando_porta_3,
            elevador_pronto => elevador_pronto_3,
            andar_atual => andar_atual_3,
            estado_motor => estado_motor_3,
            estado_porta => open,
            seg_MSD => seg_MSD_3,
            seg_LSD => seg_LSD_3
        );

    -- =============================
    -- Instancia do Escalonador
    -- =============================
    ESC : entity work.Escalonador
        port map (
            clk => clk,
            rst => rst,
            pos_elevador_1 => andar_atual_1,
            estado_elevador_1 => estado_motor_1,
            elevador_pronto_1 => elevador_pronto_1,
            pos_elevador_2 => andar_atual_2,
            estado_elevador_2 => estado_motor_2,
            elevador_pronto_2 => elevador_pronto_2,
            pos_elevador_3 => andar_atual_3,
            estado_elevador_3 => estado_motor_3,
            elevador_pronto_3 => elevador_pronto_3,
            requisicoes_externas_elevador_1 => req_ext_1,
            requisicoes_externas_elevador_2 => req_ext_2,
            requisicoes_externas_elevador_3 => req_ext_3,
            requisicao_andar_elevador_1 => prox_andar_1,
            requisicao_andar_elevador_2 => prox_andar_2,
            requisicao_andar_elevador_3 => prox_andar_3
        );

end architecture Behavioral;
