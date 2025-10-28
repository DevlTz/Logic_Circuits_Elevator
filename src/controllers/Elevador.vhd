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
            direcao      : out std_logic_vector(1 downto 0); -- mesma codificação do comando
            freio        : out std_logic
        );
    end component;

begin
    Porta_ins : Porta 
        port map(
            clk => clk,
            rst => rst,
            abre => comando_porta, 
            motor_mov => sensor_movimento, -- Alterado com o que era :  motor_mov => comando_motor | A explicação pra isso é simples > A porta só precisa saber se o motor tá movendo ou nem
            porta_aberta => estado_porta 
        );

    Motor_ins : Motor
        port map(
            clk => clk,
            rst => rst,
            comando => comando_motor,
            porta => estado_porta,
            em_movimento => sensor_movimento, -- Alterando o que era : em_movimento => 1 bit | A gente tem que fazer a ligação pra o sensor_movimento que em si é uma entrada do Elveador
            direcao => estado_motor,
            freio => open -- isso vai dizer que não vai tá nada ligado enquanto nada rolar. '-'
        );

    function calcula_em_movimento(
        requisicoes_externas : std_logic_vector(31 downto 0);
        requisicoes_internas : std_logic_vector(31 downto 0)
    ) return std_logic is
        variable requisicoes_totais : std_logic_vector(31 downto 0);
        variable todas_reqs : std_logic := '0';
    begin
        -- soma entre as requisições
        requisicoes_totais := requisicoes_externas or requisicoes_internas;

        -- NOR (lembre-se que o NOR quando todas as portas são 0, retorna 1)
        for i in requisicoes_totais'range loop
            todas_reqs := todas_reqs or requisicoes_totais(i);
        end loop;

        -- Logo... iremos retornar da seguinte forma:
        -- '1' = parado, '0' = tem requisição = mover
        return not todas_reqs;
    end function;


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
            
            if calcula_em_movimento(requisicoes_escalonador, requisicoes_internas) = '1' then
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
            else
                comando_motor <= '00';
                comando_porta <= '0';
            end if;
        end if;
    end process;
    
