-- Arquivo: testbench_mux_2x1_duo.vhd
ENTITY testbench_mux_2x1_duo IS
END testbench_mux_2x1_duo;

ARCHITECTURE tb OF testbench_mux_2x1_duo IS
  -- Sinais para conectar ao DUT
  SIGNAL a0, b0, a1, b1, sel : BIT;
  SIGNAL s0, s1 : BIT;

  COMPONENT mux_2x1_duo
    PORT (
      a0, b0 : IN BIT;
      a1, b1 : IN BIT;
      sel     : IN BIT;
      s0, s1  : OUT BIT
    );
  END COMPONENT;
BEGIN
  -- Instanciação do DUT (Device Under Test)
  uut : mux_2x1_duo
    PORT MAP (
      a0 => a0,
      b0 => b0,
      a1 => a1,
      b1 => b1,
      sel => sel,
      s0 => s0,
      s1 => s1
    );

  -- Processo de estímulo
  stim_proc : PROCESS
  BEGIN
    -- Teste 1
    a0 <= '0'; b0 <= '1';
    a1 <= '1'; b1 <= '0';
    sel <= '0';
    WAIT FOR 10 ns;

    -- Teste 2
    sel <= '1';
    WAIT FOR 10 ns;

    -- Teste 3
    a0 <= '1'; b0 <= '0';
    a1 <= '0'; b1 <= '1';
    sel <= '0';
    WAIT FOR 10 ns;

    -- Teste 4
    sel <= '1';
    WAIT FOR 10 ns;

    -- Finaliza a simulação
    WAIT;
  END PROCESS;

END tb;
