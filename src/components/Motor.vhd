library IEEE;
use IEEE.std_logic_1164.all;

entity Motor is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        comando    : in  std_logic_vector(1 downto 0);  
        porta      : in  std_logic;
        em_movimento : out std_logic;
        direcao      : out std_logic_vector(1 downto 0);
        freio        : out std_logic
    );
end entity;

architecture Behavioral of Motor is
    type T_ESTADO_MOTOR is (PARADO, SUBINDO, DESCENDO, FREANDO);
    signal estado_atual, proximo_estado : T_ESTADO_MOTOR;
    constant TEMPO_FREIO : integer := 10;
    signal contador_freio : integer range 0 to TEMPO_FREIO := 0;
    
    signal s_em_movimento : std_logic;
    signal direcao_interna : std_logic_vector(1 downto 0) := "00";

begin

    process(estado_atual, comando, porta, contador_freio)
    begin
        proximo_estado <= estado_atual; 

        if porta = '1' then
            if (estado_atual = SUBINDO) or (estado_atual = DESCENDO) then
                proximo_estado <= FREANDO;
            elsif estado_atual = FREANDO then
                -- Continua freando até contador expirar
                if contador_freio >= TEMPO_FREIO then
                    proximo_estado <= PARADO;
                end if;
            else
                proximo_estado <= PARADO;
            end if;
        
        else
            -- Porta fechada: processa comandos normais
            case estado_atual is
                when PARADO =>
                    if comando = "01" then
                        proximo_estado <= SUBINDO;
                    elsif comando = "10" then
                        proximo_estado <= DESCENDO;
                    end if;

                when SUBINDO =>
                    if comando = "00" or comando = "10" then
                        proximo_estado <= FREANDO;
                    end if;

                when DESCENDO =>
                    if comando = "00" or comando = "01" then
                        proximo_estado <= FREANDO;
                    end if;
                    
                when FREANDO =>
                    if contador_freio >= TEMPO_FREIO then
                        proximo_estado <= PARADO;
                    end if;
            end case;
        end if;
    end process;

    process(clk, rst)
    begin
        if rst = '1' then
            estado_atual <= PARADO;
            contador_freio <= 0;
        elsif rising_edge(clk) then
            estado_atual <= proximo_estado;

            -- Contador de frenagem
            if proximo_estado = FREANDO then
                if contador_freio < TEMPO_FREIO then
                    contador_freio <= contador_freio + 1;
                end if;
            else
                contador_freio <= 0;
            end if;
        end if;
    end process;

    process(estado_atual)
    begin
        case estado_atual is
            when PARADO =>
                s_em_movimento <= '0';
                direcao_interna <= "00";
                freio <= '0';
                
            when SUBINDO =>
                s_em_movimento <= '1';
                direcao_interna <= "01";
                freio <= '0';
                
            when DESCENDO =>
                s_em_movimento <= '1';
                direcao_interna <= "10";
                freio <= '0';
                
            when FREANDO =>
                s_em_movimento <= '0';
                direcao_interna <= "00";
                freio <= '1';
        end case;   
    end process;

    em_movimento <= s_em_movimento;
    direcao <= direcao_interna;

end architecture Behavioral;
