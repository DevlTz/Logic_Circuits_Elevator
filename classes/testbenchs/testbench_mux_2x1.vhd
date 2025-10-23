-- Arquivo: testbench_mux_2x1.vhd
ENTITY testbench_mux_2x1 IS
END testbench_mux_2x1;

ARCHITECTURE test_mux OF testbench_mux_2x1 IS

  SIGNAL at, bt, selt, st : BIT;

  COMPONENT mux_2x1
    PORT (
      a, b  : IN BIT;
      sel   : IN BIT;
      s     : OUT BIT
    );
  END COMPONENT;

BEGIN

  -- Instanciação do UUT (unit under test)
  uut : mux_2x1
    PORT MAP (
      a   => at,
      b   => bt,
      sel => selt,
      s   => st
    );

  -- Processo de estímulo
  dados_teste : PROCESS
  BEGIN
    at <= '0'; bt <= '1'; selt <= '1'; 
    WAIT FOR 10 ns;
    selt <= '0'; 
    WAIT FOR 10 ns;
    
    -- Finaliza a simulação
    WAIT;
  END PROCESS;

END test_mux;
