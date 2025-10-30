-- SeteSeg.vhd
-- Converte andar_atual (0..31) para dois displays 7-seg
-- Mostra dezenas no MSD e unidades no LSD
-- Compatível com VHDL-93

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SeteSeg is
    generic (
        NUM_ANDARES : integer := 32
    );
    port (
        andar_atual : in  integer range 0 to NUM_ANDARES-1; -- entrada direta do elevador
        seg_MSD     : out std_logic_vector(6 downto 0);     -- most significant digit
        seg_LSD     : out std_logic_vector(6 downto 0)      -- least significant digit
    );
end entity;

architecture comb of SeteSeg is

    -- Segment patterns para common-cathode (1 = acende)
    function seg_pattern(d: integer) return std_logic_vector is
        variable p: std_logic_vector(6 downto 0);
    begin
        case d is
            when 0 => p := "1111110";
            when 1 => p := "0110000";
            when 2 => p := "1101101";
            when 3 => p := "1111001";
            when 4 => p := "0110011";
            when 5 => p := "1011011";
            when 6 => p := "1011111";
            when 7 => p := "1110000";
            when 8 => p := "1111111";
            when 9 => p := "1111011";
            when others => p := "0000000"; -- tudo apagado
        end case;
        return p;
    end function;

begin

    -- Processo combinacional
    process(andar_atual)
        variable tens  : integer := 0;
        variable ones  : integer := 0;
        variable andar : integer := 0;
    begin
        -- Copia o valor do andar (já vem limitado pelo range)
        andar := andar_atual;
        
        -- Calcula dezenas e unidades
        if andar >= 30 then
            tens := 3;
            ones := andar - 30;
        elsif andar >= 20 then
            tens := 2;
            ones := andar - 20;
        elsif andar >= 10 then
            tens := 1;
            ones := andar - 10;
        else
            tens := 0;
            ones := andar;
        end if;
        
        -- Proteção final (não deve ser necessário, mas por garantia)
        if tens < 0 then tens := 0; end if;
        if tens > 9 then tens := 9; end if;
        if ones < 0 then ones := 0; end if;
        if ones > 9 then ones := 9; end if;

        -- Map para os displays
        seg_MSD <= seg_pattern(tens);
        seg_LSD <= seg_pattern(ones);

    end process;

end architecture;