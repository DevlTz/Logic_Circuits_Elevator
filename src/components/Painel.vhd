library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Entidade do Painel de Controle do Elevador
-- A idéia é de que ele envie apenas um requisição por vez, acionando o bit que corresponde ao andar solicitado.
-- O retorno vai ser um vetor de 32 bits, que ao final vai ser somado (OR) com as requisições internas do elevador.

entity Painel is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;

        -- Sinais de entrada
        -- O do andar é um inteiro que indica qual botão foi pressionado (0 a 31)
        -- O sinal de pressão indica se o botão foi pressionado ou não, deve ser útil pra debounce.
        andar     : in  integer range 0 to 31; 
        press     : in  std_logic;             

        -- Sinais de saída
        -- Isso aqui é o que eu falei antes, um vetor de 32 bits que indica qual andar foi solicitado.
        requisicao : out std_logic_vector(31 downto 0)
    );
end entity;

architecture Behavioral of Painel is
begin
    process(clk, rst)
    begin
        if rst = '1' then
            requisicao <= (others => '0');
        elsif rising_edge(clk) then
            if press = '1' then
                -- Aqui, ele só aciona o bit correspondente ao andar solicitado
                requisicao <= (others => '0');
                requisicao(andar) <= '1';
            else
                -- Se não tem requisição, fica zerado
                requisicao <= (others => '0');
            end if;
        end if;
    end process;
end architecture;
