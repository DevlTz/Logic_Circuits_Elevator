entity Elevador is
    port (
        clk   : in std_logic;
        rst   : in std_logic;

        -- Requisições
        requisicoes_escalonador : in std_logic_vector(31 downto 0); -- externas
        requisicoes_internas    : in std_logic_vector(31 downto 0); -- botões da cabine

        -- Precisamos de um registrador pra isso aqui..........

        -- Sensores
        sensor_andar_atual      : in integer range 0 to 31;
        sensor_porta_aberta     : in std_logic;
        sensor_movimento        : in std_logic;

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
    signal requisicoes_totais : std_logic_vector(31 downto 0);
    signal proximo_andar      : integer range 0 to 31;

    component Porta is 
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            abre       : in  std_logic;  -- 1 = abrir, 0 = fechar
            motor_mov  : in std_logic; -- 1 = motor em movimento, 0 = motor parado
            porta_aberta : out std_logic;  -- 1 = aberta, 0 = fechada
        );
    end component;
    
    component Motor is 
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            comando    : in  std_logic_vector(1 downto 0);  
            porta      : in std_logic;
            em_movimento : out std_logic;  -- 1 = movendo, 0 = parado
            direcao      : out std_logic_vector(1 downto 0)  -- mesma codificação do comando
        );
    end component;

begin
    Porta_ins : Porta 
        port map(
            clk => clk,
            rst => rst,
            abre => comando_porta, 
            motor_mov => comando_motor,
            porta_aberta => estado_porta 
        );

    Motor_ins : Motor
        port map(
            clk => clk,
            rst => rst,
            comando => comando_motor,
            porta => estado_porta,
            em_movimento => 1 bit,
            direcao => estado_motor
        );

    process(clk, rst)
    begin
        if rst = '1' then 
            comando_motor <= '00';
            comando_porta <= '0';
            andar_atual <= 0;
            estado_motor <= '00';
            estado_porta <= '0';
        elsif rising_edge(clk) then
            andar_atual <= sensor_andar_atual;
            estado_porta <= sensor_porta_aberta;
            estado_motor <= sensor_movimento;

            if proximo_andar < andar_atual then -- descer
                comando_motor <= '10';
                comando_porta <= '0';
            elsif proximo_andar > andar_atual then -- subir
                comando_motor <= '01';
                comando_porta <= '0';
            else -- chegou 
                comando_motor <= '00';
                comando_porta <= '1';
            end if;
        end if;
    end process;
    
