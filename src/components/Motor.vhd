library IEEE;
use IEEE.std_logic_1164.all;

entity Motor is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        -- Entrada de comando do elevador
        comando    : in  std_logic_vector(1 downto 0);  
        -- 00 = parado, 01 = subir, 10 = descer

        -- Entrada porta 
        porta : in std_logic;
        -- 1 = aberta, 0 = fechada

        -- Saída de sensor (movimento atual)
        em_movimento : out std_logic;  -- 1 = movendo, 0 = parado
        direcao      : out std_logic_vector(1 downto 0);  -- mesma codificação do comando
        freio        : out std_logic -- adicionado para comando de parada
    );
end entity;

architecture Behavioral of Motor is

    -- Definição dos estados da FSM
    type T_ESTADO_MOTOR is (PARADO, SUBINDO, DESCENDO, FREANDO);
    
    -- Sinais para guardar o estado 
    signal estado_atual, proximo_estado : T_ESTADO_MOTOR;

    -- Constante para o tempo de frear
    -- Simula o tempo necessário para o motor parar (tá 10 ciclos, mas...)
    constant TEMPO_FREIO : integer := 10;
    
    -- Sinal do contador para o estado de frear
    signal contador_freio : integer range 0 to TEMPO_FREIO := 0;

    -- Sinais internos para evitar que a gente leia as portas de saída diretamente
    signal s_em_movimento : std_logic;
    signal direcao_interna : std_logic_vector(1 downto 0) := "00";

begin

    -- Parte da Lógica de Próximo Estado 
    -- Este processo diz qual é o próximo estado baseado nas entradas e no estado atual.
    
    process(estado_atual, comando, porta, contador_freio, s_em_movimento)
    begin
        proximo_estado <= estado_atual; 

        if porta = '1' then
            if (estado_atual = SUBINDO) or (estado_atual = DESCENDO) then
                proximo_estado <= FREANDO;
            else
                if (s_em_movimento = '1') then
                    proximo_estado <= FREANDO;
                else
                    proximo_estado <= PARADO;
                end if;
            end if;
        
        else -- porta = '0'
            case estado_atual is
                when PARADO =>
                    if comando = "01" then      -- Comando para SUBIR
                        proximo_estado <= SUBINDO;
                    elsif comando = "10" then   -- Comando para DESCER
                        proximo_estado <= DESCENDO;
                    end if;
                    -- Se comando = "00", continua PARADO (default)

                when SUBINDO =>
                    -- Se o comando for parar ("00") ou inverter ("10")
                    -- Se comando = "01", continua SUBINDO (default)

                    if (comando = "00") or (comando = "10") then
                        proximo_estado <= FREANDO; -- Deve frear primeiro
                    end if;

                when DESCENDO =>
                    -- Se o comando for parar ("00") ou inverter ("01")
                    -- Se comando = "10", continua DESCENDO (default)

                    if (comando = "00") or (comando = "01") then
                        proximo_estado <= FREANDO; -- Deve frear primeiro
                    end if;
                    

                when FREANDO =>
                    -- Permanece em FREANDO até o contador terminar
                    if contador_freio = TEMPO_FREIO then
                        proximo_estado <= PARADO;
                    end if;
            end case;
        end if;
    end process;


    -- Partes dos Registradores 
    -- Este processo atualiza o estado atual e o contador no pulso do clock.

    process(clk, rst)
    begin
        if rst = '1' then
            estado_atual <= PARADO;
            contador_freio <= 0;
        elsif rising_edge(clk) then
            estado_atual <= proximo_estado;

            -- Lógica do contador de frenagem
            -- Erro aqui é que estamos usando proximo_estado ao invés de estado_atual
            if estado_atual = FREANDO then
                if contador_freio < TEMPO_FREIO then
                    contador_freio <= contador_freio + 1;
                end if;
            else
                contador_freio <= 0; -- Zera o contador se não estiver freando
            end if;
        end if;
    end process;

    
    -- PROCESSO 3: Lógica de Saída 
    -- Define os SINAIS INTERNOS com base no estado atual
    process(estado_atual)
    begin
        case estado_atual is
            when PARADO =>
                s_em_movimento <= '0';
                -- direcao_interna mantém valor anterior (não precisa atribuir)
                freio <= '0';
                
            when SUBINDO =>
                s_em_movimento <= '1';
                direcao_interna <= "01";  -- ← Corrigido
                freio <= '0';
                
            when DESCENDO =>
                s_em_movimento <= '1';
                direcao_interna <= "10";  -- ← Corrigido
                freio <= '0';
                
            when FREANDO =>
                s_em_movimento <= '0';
                -- direcao_interna mantém valor anterior (não precisa atribuir)
                freio <= '1';
        end case;   
    end process;

    -- ATRIBUIÇÕES CONCORRENTES (fora de qualquer processo)
    em_movimento <= s_em_movimento;
    direcao <= direcao_interna;

end architecture Behavioral;