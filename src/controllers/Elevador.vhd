library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Elevador is
    port (
        clk   : in std_logic;
        rst   : in std_logic;

        -- Requisições
        requisicoes_escalonador : in std_logic_vector(31 downto 0); -- externas
        requisicoes_internas    : in std_logic_vector(31 downto 0); -- botões da cabine

        -- Sensores
        sensor_andar_atual      : in integer range 0 to 31;

        -- Saídas para motor e porta
        comando_motor           : out std_logic_vector(1 downto 0); -- 00=parado, 01=subindo, 10=descendo
        comando_porta           : out std_logic;                     -- 0=fechada, 1=abrindo

        -- Estado interno
        andar_atual             : out integer range 0 to 31;
        estado_motor            : out std_logic_vector(1 downto 0);
        estado_porta            : out std_logic
    );
end entity;

architecture Behavioral of Elevador is
    -- Sinais internos para as saídas (para poder ler e escrever)
    signal comando_motor_int  : std_logic_vector(1 downto 0);
    signal comando_porta_int  : std_logic;
    signal andar_atual_int    : integer range 0 to 31;
    
    signal requisicoes_totais : std_logic_vector(31 downto 0);
    signal proximo_andar      : integer range 0 to 31;

    -- Sinais internos para conexão de componentes
    signal sensor_porta_aberta : std_logic;
    signal sensor_movimento    : std_logic;
    signal sensor_direcao      : std_logic_vector(1 downto 0);

    component Porta is 
        port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            abre         : in  std_logic;  -- 1 = abrir, 0 = fechar
            motor_mov    : in  std_logic;  -- 1 = motor em movimento, 0 = motor parado
            porta_aberta : out std_logic   -- 1 = aberta, 0 = fechada
        );
    end component;
    
    component Motor is 
        port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            comando      : in  std_logic_vector(1 downto 0);  
            porta        : in  std_logic;
            em_movimento : out std_logic;  -- 1 = movendo, 0 = parado
            direcao      : out std_logic_vector(1 downto 0); -- mesma codificação do comando
            freio        : out std_logic
        );
    end component;

    function calcula_em_movimento(
        req_externas : std_logic_vector(31 downto 0);
        req_internas : std_logic_vector(31 downto 0)
    ) return std_logic is
        variable req_totais : std_logic_vector(31 downto 0);
        variable tem_req    : std_logic := '0';
    begin
        -- Combina as requisições
        req_totais := req_externas or req_internas;

        -- Verifica se há alguma requisição
        for i in req_totais'range loop
            tem_req := tem_req or req_totais(i);
        end loop;

        -- Retorna: '1' = tem requisição, '0' = sem requisição
        return tem_req;
    end function;

begin
    -- Instância da Porta
    Porta_ins : Porta 
        port map(
            clk          => clk,
            rst          => rst,
            abre         => comando_porta_int, 
            motor_mov    => sensor_movimento,
            porta_aberta => sensor_porta_aberta
        );

    -- Instância do Motor
    Motor_ins : Motor
        port map(
            clk          => clk,
            rst          => rst,
            comando      => comando_motor_int,
            porta        => sensor_porta_aberta,
            em_movimento => sensor_movimento,
            direcao      => sensor_direcao,
            freio        => open
        );

    -- Atribuição dos sinais internos às saídas
    comando_motor <= comando_motor_int;
    comando_porta <= comando_porta_int;
    andar_atual   <= andar_atual_int;
    estado_porta  <= sensor_porta_aberta;
    estado_motor  <= sensor_direcao;

    -- Processo principal de controle
    process(clk, rst)
    begin
        if rst = '1' then 
            comando_motor_int <= "00";
            comando_porta_int <= '0';
            andar_atual_int   <= 0;
            proximo_andar     <= 0;

        elsif rising_edge(clk) then
            andar_atual_int <= sensor_andar_atual;
            proximo_andar   <= 0; -- TODO: implementar lógica de escalonamento
            
            -- Verifica se há requisições
            if calcula_em_movimento(requisicoes_escalonador, requisicoes_internas) = '1' then
                if proximo_andar < andar_atual_int then -- descer
                    comando_motor_int <= "10";
                    comando_porta_int <= '0';
                elsif proximo_andar > andar_atual_int then -- subir
                    comando_motor_int <= "01";
                    comando_porta_int <= '0';
                else -- chegou no andar
                    comando_motor_int <= "00";
                    comando_porta_int <= '1';
                end if;
            else -- sem requisições
                comando_motor_int <= "00";
                comando_porta_int <= '0';
            end if;
        end if;
    end process;

end Behavioral;