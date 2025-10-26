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
begin