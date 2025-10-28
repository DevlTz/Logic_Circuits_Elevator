entity Escalonador is
    port (
        -- O escalonador tem que saber onde estão cada um dos elevadores, os seus estados e dependendo da lógica, da proximidade.
        -- Inicialmente, precisamos de:
            -- Registradores para armazenar a posição de cada um dos elevadores;
            -- Registradores para armazenar o estado de cada um dos elevadores em relação às solicitações;
            -- Registradores para armazenar as requisições feitas para cada um dos andares;

        -- O encoder vai ser responsável por codificar as requisições em um formato que possa ser entendido pelo
        -- sistema, enquanto o decoder vai fazer o processo inverso, decodificando as informações recebidas.

        -- De resto, podemos receber sinais de posição, estado da maneira normal mesmo, já que são poucos bits.

        clk : in std_logic;
        rst : in std_logic;

        -- >>> Entradas

        -- [ Status do elevador ] 
        -- Esses trechos serão interessantes para que consigamos fazer os cálculos necessários para decisões de otimização
        -- de local. Precisaremos de registrdores aqui. Tanto para posição quanto para estado.

        -- Posições dos elevadores
        pos_elevador_1 : in integer range 0 to 10;
        pos_elevador_2 : in integer range 0 to 10;
        pos_elevador_3 : in integer range 0 to 10;

        -- Estados dos elevadores
        estado_elevador_1 : in std_logic_vector(1 downto 0);
        estado_elevador_2 : in std_logic_vector(1 downto 0);
        estado_elevador_3 : in std_logic_vector(1 downto 0);

        -- Aqui eu creio que só vai precisar de um mesmo que é pra representar qual ele tem que olhar e dizer:
        -- "Ei, tu tem quer ir pra esse andar aqui." e depois remover.

        -- [ Requisições dos andares ]
        -- Precisaremos de uma parte do processo pra ele conseguir fazer com que mapeie certo para o índice indicado.
        requisicoes_externas_elevador_1 : in std_logic_vector(10 downto 0);
        requisicoes_externas_elevador_2 : in std_logic_vector(10 downto 0);
        requisicoes_externas_elevador_3 : in std_logic_vector(10 downto 0);

        -- Para adicionar as requisições internas às externas, podemos fazer um "or" entre os dois vetores.
        
        -- >>> Saídas
        -- [ Requisições para os elevadores ]
        requisicao_andar_elevador_1 : out integer range 0 to 10;
        requisicao_andar_elevador_2 : out integer range 0 to 10;
        requisicao_andar_elevador_3 : out integer range 0 to 10;

        -- Acho que nem tem mais nada...
    );
end entity;

architecture Behavioral of Escalonador is
    -- TODO: Sinais internos e lógica do escalonador
begin
    -- Lógica do escalonador será implementada aqui
end Behavioral;