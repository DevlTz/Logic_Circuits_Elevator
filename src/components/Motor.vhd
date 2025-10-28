library IEEE;
use IEEE.std_logic_1164.all;

-- Motor está sem realimentação de sinal.

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

        ocupado : in std_logic; -- ele recebe papo de um sinal para caso não tiver nenhuma requisição presente no vetor do elevador
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

begin

    -- Parte da Lógica de Próximo Estado 
    -- Este processo diz qual é o próximo estado baseado nas entradas e no estado atual.
    
    process(estado_atual, comando, porta, contador_freio)
    begin
        -- Por padrão, o próximo estado é o estado atual
        proximo_estado <= estado_atual; 

        -- REGRA DE SEGURANÇA: Se a porta abrir, para imediatamente
        -- Considera parar se o motor ainda estivesse em movimento
        if porta = '1' or ocupado = '0' then -- atualizei aqui pra considerar o sinal de ocupado
            if (estado_atual = SUBINDO) or (estado_atual = DESCENDO) then
                proximo_estado <= FREANDO;
            else
                if (em_movimento = '1') then
                    proximo_estado <= FREANDO;
                else
                    proximo_estado <= PARADO;
                end if;
            end if;
        
        -- LÓGICA DE OPERAÇÃO (Porta fechada)
        else -- porta = '0' e o ocupado é igual a 1
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
                    if (comando = "00") or (comando = "10") then
                        proximo_estado <= FREANDO; -- Deve frear primeiro
                    end if;
                    -- Se comando = "01", continua SUBINDO (default)

                when DESCENDO =>
                    -- Se o comando for parar ("00") ou inverter ("01")
                    if (comando = "00") or (comando = "01") then
                        proximo_estado <= FREANDO; -- Deve frear primeiro
                    end if;
                    -- Se comando = "10", continua DESCENDO (default)

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
            if proximo_estado = FREANDO then
                if contador_freio < TEMPO_FREIO then
                    contador_freio <= contador_freio + 1;
                end if;
            else
                contador_freio <= 0; -- Zera o contador se não estiver freando
            end if;
        end if;
    end process;


    -- PROCESSO 3: Lógica de Saída 
    -- Define as saídas (em_movimento, direcao) com base só no estado atual.
    
    process(estado_atual)
    begin
        case estado_atual is
            when PARADO =>
                em_movimento <= '0';
                direcao <= direcao;
                freio <= '0';
                
            when SUBINDO =>
                em_movimento <= '1';
                direcao <= "01";
                freio <= '0';
                
            when DESCENDO =>
                em_movimento <= '1';
                direcao <= "10";
                freio <= '0';
                
            when FREANDO =>
                em_movimento <= '0'; -- O motor não está "em movimento"
                direcao <= direcao; -- Mantém a direção anterior
                freio <= '1'; -- Freio ativo 
        end case;   
    end process;

end architecture Behavioral;