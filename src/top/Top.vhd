-- Nome do arquivo: src/top/Top.vhd
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Top is
    generic (
        NUM_ANDARES : integer := 32;
        TEMPO_PORTA_ABERTA : integer := 10000;
        TEMPO_ENTRE_ANDARES : integer := 1000  -- Ciclos de clock para viajar 1 andar
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        
        -- Requisições externas (entradas vindas do testbench)
        req_ext_1 : in std_logic_vector(NUM_ANDARES-1 downto 0);
        req_ext_2 : in std_logic_vector(NUM_ANDARES-1 downto 0);
        req_ext_3 : in std_logic_vector(NUM_ANDARES-1 downto 0);
        
        -- Saídas para monitoramento no testbench
        prox_andar_1 : out integer range 0 to NUM_ANDARES-1;
        prox_andar_2 : out integer range 0 to NUM_ANDARES-1;
        prox_andar_3 : out integer range 0 to NUM_ANDARES-1;
        
        pos_elevador_1 : out integer range 0 to NUM_ANDARES-1;
        pos_elevador_2 : out integer range 0 to NUM_ANDARES-1;
        pos_elevador_3 : out integer range 0 to NUM_ANDARES-1;
        
        estado_elevador_1 : out std_logic_vector(1 downto 0);
        estado_elevador_2 : out std_logic_vector(1 downto 0);
        estado_elevador_3 : out std_logic_vector(1 downto 0);
        
        elevador_pronto_1 : out std_logic;
        elevador_pronto_2 : out std_logic;
        elevador_pronto_3 : out std_logic
    );
end entity;

architecture Behavioral of Top is

    -- Sinais internos para comunicação entre módulos
    signal prox_andar_1_s, prox_andar_2_s, prox_andar_3_s : integer range 0 to NUM_ANDARES-1;
    signal estado_motor_1_s, estado_motor_2_s, estado_motor_3_s : std_logic_vector(1 downto 0);
    signal elevador_pronto_1_s, elevador_pronto_2_s, elevador_pronto_3_s : std_logic;
    signal andar_atual_1_s, andar_atual_2_s, andar_atual_3_s : integer range 0 to NUM_ANDARES-1;

    -- Requisições internas (podem ser modificadas dinamicamente ou conectadas a botões)
    signal requisicoes_internas_1, requisicoes_internas_2, requisicoes_internas_3 : std_logic_vector(NUM_ANDARES-1 downto 0) := (others => '0');

    -- Comandos de motor/porta
    signal comando_motor_1, comando_motor_2, comando_motor_3 : std_logic_vector(1 downto 0);
    signal comando_porta_1, comando_porta_2, comando_porta_3 : std_logic;

    -- Display 7 segmentos
    signal seg_MSD_1, seg_LSD_1 : std_logic_vector(6 downto 0);
    signal seg_MSD_2, seg_LSD_2 : std_logic_vector(6 downto 0);
    signal seg_MSD_3, seg_LSD_3 : std_logic_vector(6 downto 0);
    
    -- SENSORES FÍSICOS (simulados) - Posição real do elevador
    signal sensor_andar_1_s : integer range 0 to NUM_ANDARES-1 := 0;
    signal sensor_andar_2_s : integer range 0 to NUM_ANDARES-1 := 0;
    signal sensor_andar_3_s : integer range 0 to NUM_ANDARES-1 := 0;
    
    -- Estado da porta
    signal estado_porta_1_s, estado_porta_2_s, estado_porta_3_s : std_logic;
    
    -- Sinais de movimento real do motor (vem do componente Motor dentro do Elevador)
    signal em_movimento_1_s, em_movimento_2_s, em_movimento_3_s : std_logic;
    
    -- Contadores para simular tempo de viagem entre andares
    signal contador_movimento_1 : integer range 0 to TEMPO_ENTRE_ANDARES := 0;
    signal contador_movimento_2 : integer range 0 to TEMPO_ENTRE_ANDARES := 0;
    signal contador_movimento_3 : integer range 0 to TEMPO_ENTRE_ANDARES := 0;

begin

    -- =============================
    -- Instâncias dos Elevadores
    -- =============================
    E1 : entity work.Elevador
        generic map (
            NUM_ANDARES => NUM_ANDARES,
            TEMPO_PORTA_ABERTA => TEMPO_PORTA_ABERTA
        )
        port map (
            clk => clk,
            rst => rst,
            proximo_andar_escalonador => prox_andar_1_s,
            requisicoes_internas => requisicoes_internas_1,
            sensor_andar_atual => sensor_andar_1_s,  -- Sensor simulado
            comando_motor => comando_motor_1,
            comando_porta => comando_porta_1,
            elevador_pronto => elevador_pronto_1_s,
            andar_atual => andar_atual_1_s,
            estado_motor => estado_motor_1_s,
            estado_porta => estado_porta_1_s,
            em_movimento => em_movimento_1_s,
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
            proximo_andar_escalonador => prox_andar_2_s,
            requisicoes_internas => requisicoes_internas_2,
            sensor_andar_atual => sensor_andar_2_s,  -- Sensor simulado
            comando_motor => comando_motor_2,
            comando_porta => comando_porta_2,
            elevador_pronto => elevador_pronto_2_s,
            andar_atual => andar_atual_2_s,
            estado_motor => estado_motor_2_s,
            estado_porta => estado_porta_2_s,
            em_movimento => em_movimento_2_s,
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
            proximo_andar_escalonador => prox_andar_3_s,
            requisicoes_internas => requisicoes_internas_3,
            sensor_andar_atual => sensor_andar_3_s,  -- Sensor simulado
            comando_motor => comando_motor_3,
            comando_porta => comando_porta_3,
            elevador_pronto => elevador_pronto_3_s,
            andar_atual => andar_atual_3_s,
            estado_motor => estado_motor_3_s,
            estado_porta => estado_porta_3_s,
            em_movimento => em_movimento_3_s,
            seg_MSD => seg_MSD_3,
            seg_LSD => seg_LSD_3
        );

    -- =============================
    -- Instância do Escalonador
    -- =============================
    ESC : entity work.Escalonador
        port map (
            clk => clk,
            rst => rst,
            pos_elevador_1 => andar_atual_1_s,
            estado_elevador_1 => estado_motor_1_s,
            elevador_pronto_1 => elevador_pronto_1_s,
            pos_elevador_2 => andar_atual_2_s,
            estado_elevador_2 => estado_motor_2_s,
            elevador_pronto_2 => elevador_pronto_2_s,
            pos_elevador_3 => andar_atual_3_s,
            estado_elevador_3 => estado_motor_3_s,
            elevador_pronto_3 => elevador_pronto_3_s,
            requisicoes_externas_elevador_1 => req_ext_1,
            requisicoes_externas_elevador_2 => req_ext_2,
            requisicoes_externas_elevador_3 => req_ext_3,
            requisicao_andar_elevador_1 => prox_andar_1_s,
            requisicao_andar_elevador_2 => prox_andar_2_s,
            requisicao_andar_elevador_3 => prox_andar_3_s
        );

    -- =============================
    -- SIMULAÇÃO DE MOVIMENTO FÍSICO DOS ELEVADORES
    -- =============================
    process(clk, rst)
    begin
        if rst = '1' then
            sensor_andar_1_s <= 0;
            sensor_andar_2_s <= 0;
            sensor_andar_3_s <= 0;
            contador_movimento_1 <= 0;
            contador_movimento_2 <= 0;
            contador_movimento_3 <= 0;
            
        elsif rising_edge(clk) then
            
            -- DEBUG: Reporta estado dos sinais de movimento
            if em_movimento_1_s = '1' then
                report "[DEBUG] E1: em_movimento=1, estado_motor=" & 
                       integer'image(to_integer(unsigned(estado_motor_1_s))) &
                       ", contador=" & integer'image(contador_movimento_1);
            end if;
            
            -- ELEVADOR 1: Simula movimento físico
            -- Usa APENAS estado_motor (que já vem sincronizado do Motor via Elevador)
            if estado_motor_1_s = "01" then  -- Subindo
                if contador_movimento_1 < TEMPO_ENTRE_ANDARES then
                    contador_movimento_1 <= contador_movimento_1 + 1;
                else
                    if sensor_andar_1_s < NUM_ANDARES-1 then
                        sensor_andar_1_s <= sensor_andar_1_s + 1;
                        report "[FISICA] Elevador 1 subiu para andar " & integer'image(sensor_andar_1_s + 1);
                    end if;
                    contador_movimento_1 <= 0;
                end if;
            elsif estado_motor_1_s = "10" then  -- Descendo
                if contador_movimento_1 < TEMPO_ENTRE_ANDARES then
                    contador_movimento_1 <= contador_movimento_1 + 1;
                else
                    if sensor_andar_1_s > 0 then
                        sensor_andar_1_s <= sensor_andar_1_s - 1;
                        report "[FISICA] Elevador 1 desceu para andar " & integer'image(sensor_andar_1_s - 1);
                    end if;
                    contador_movimento_1 <= 0;
                end if;
            else  -- Parado (estado_motor = "00")
                contador_movimento_1 <= 0;
            end if;
            
            -- ELEVADOR 2: Simula movimento físico
            if em_movimento_2_s = '1' and estado_motor_2_s = "01" then  -- Subindo E motor girando
                if contador_movimento_2 < TEMPO_ENTRE_ANDARES then
                    contador_movimento_2 <= contador_movimento_2 + 1;
                else
                    if sensor_andar_2_s < NUM_ANDARES-1 then
                        sensor_andar_2_s <= sensor_andar_2_s + 1;
                        report "[FISICA] Elevador 2 subiu para andar " & integer'image(sensor_andar_2_s + 1);
                    end if;
                    contador_movimento_2 <= 0;
                end if;
            elsif em_movimento_2_s = '1' and estado_motor_2_s = "10" then  -- Descendo E motor girando
                if contador_movimento_2 < TEMPO_ENTRE_ANDARES then
                    contador_movimento_2 <= contador_movimento_2 + 1;
                else
                    if sensor_andar_2_s > 0 then
                        sensor_andar_2_s <= sensor_andar_2_s - 1;
                        report "[FISICA] Elevador 2 desceu para andar " & integer'image(sensor_andar_2_s - 1);
                    end if;
                    contador_movimento_2 <= 0;
                end if;
            else  -- Parado
                contador_movimento_2 <= 0;
            end if;
            
            -- ELEVADOR 3: Simula movimento físico
            if em_movimento_3_s = '1' and estado_motor_3_s = "01" then  -- Subindo E motor girando
                if contador_movimento_3 < TEMPO_ENTRE_ANDARES then
                    contador_movimento_3 <= contador_movimento_3 + 1;
                else
                    if sensor_andar_3_s < NUM_ANDARES-1 then
                        sensor_andar_3_s <= sensor_andar_3_s + 1;
                        report "[FISICA] Elevador 3 subiu para andar " & integer'image(sensor_andar_3_s + 1);
                    end if;
                    contador_movimento_3 <= 0;
                end if;
            elsif em_movimento_3_s = '1' and estado_motor_3_s = "10" then  -- Descendo E motor girando
                if contador_movimento_3 < TEMPO_ENTRE_ANDARES then
                    contador_movimento_3 <= contador_movimento_3 + 1;
                else
                    if sensor_andar_3_s > 0 then
                        sensor_andar_3_s <= sensor_andar_3_s - 1;
                        report "[FISICA] Elevador 3 desceu para andar " & integer'image(sensor_andar_3_s - 1);
                    end if;
                    contador_movimento_3 <= 0;
                end if;
            else  -- Parado
                contador_movimento_3 <= 0;
            end if;
            
        end if;
    end process;

    -- =============================
    -- Conexões das saídas
    -- =============================
    prox_andar_1 <= prox_andar_1_s;
    prox_andar_2 <= prox_andar_2_s;
    prox_andar_3 <= prox_andar_3_s;
    
    pos_elevador_1 <= sensor_andar_1_s;  -- Posição física real
    pos_elevador_2 <= sensor_andar_2_s;
    pos_elevador_3 <= sensor_andar_3_s;
    
    estado_elevador_1 <= estado_motor_1_s;
    estado_elevador_2 <= estado_motor_2_s;
    estado_elevador_3 <= estado_motor_3_s;
    
    elevador_pronto_1 <= elevador_pronto_1_s;
    elevador_pronto_2 <= elevador_pronto_2_s;
    elevador_pronto_3 <= elevador_pronto_3_s;

end architecture Behavioral;