library std;
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.UARTComponents.all;
entity UARTReceiver is
  port (
    clk, reset: in std_logic;
    data_in: in std_logic;
    data_out: out std_logic_vector(7 downto 0);
    debug: out std_logic_vector(7 downto 0);
    data_ready: out std_logic
  );
end entity UARTReceiver;

architecture Struct of UARTReceiver is
  signal shift_in, tick_reset, tick_half, tick, received: std_logic;
  signal dout_enable: std_logic;
begin

  CP: UARTReceiverControl
  port map (
    data_in => data_in,
    tick_half => tick_half,
    tick => tick,
    reset => reset,
    clk => clk,
    shift_in => shift_in,
    data_ready => data_ready,
    tick_reset => tick_reset,
    received => received,
    dout_enable => dout_enable
  );

  DP: UARTReceiverData
  port map (
    reset => reset,
    debug => debug,
    tick_half => tick_half,
    tick => tick,
    clk => clk,
    shift_in => shift_in,
    dout_enable => dout_enable,
    tick_reset => tick_reset,
    data_out => data_out,
    data_in => data_in,
    received => received
  );
end Struct;


library ieee;
use ieee.std_logic_1164.all;
use work.UARTComponents.all;
entity UARTReceiverControl is
  port (
    data_in: in std_logic;
    tick_half: in std_logic;
    tick: in std_logic;
    received: in std_logic;
    clk, reset: in std_logic;
    shift_in: out std_logic;
    data_ready: out std_logic;
    dout_enable: out std_logic;
    tick_reset: out std_logic
  );
end entity;
architecture Behave of UARTReceiverControl is
  type FsmState is (S0, S1, S2, S3, S4, S5);
  signal state : FsmState;
  signal count_sig: Integer;
begin
  -- This process decides the control signals
  process(state, reset, data_in, tick_half, tick, received)
    variable nshift_in: std_logic;
    variable ntick_reset: std_logic;
    variable ndout_enable: std_logic;
  begin
    nshift_in := '0';
    ntick_reset := '0';
    ndout_enable := '0';
    case state is
      when S0 =>
        nshift_in := '0';
        ntick_reset := '1';
        ndout_enable := '0';
      when S1 =>
        nshift_in := '0';
        ntick_reset := '1';
        ndout_enable := '0';
      when S5 =>
        nshift_in := '0';
        ntick_reset := '1';
        ndout_enable := '0';
        --if data_in = '1' then
        --  -- Since we want to start the ticker
        --  ntick_reset := '1';
        --else
        --  ntick_reset := '0';
        --end if;
      when S2 =>
        ndout_enable := '0';
        if tick_half = '1' then
          nshift_in := '1';
          ntick_reset := '1';
        else
          nshift_in := '0';
          ntick_reset := '0';
        end if;
      when S3 =>
        ndout_enable := '0';
        if received = '1' and tick = '1' then
          nshift_in := '1';
          ntick_reset := '1';
        elsif received = '0' and tick = '1' then
          nshift_in := '1';
          ntick_reset := '1';
        else
          nshift_in := '0';
          ntick_reset := '0';
        end if;
      when S4 =>
        ndout_enable := '1';
        nshift_in := '0';
        ntick_reset := '1';
    end case;
    if reset = '1' then
      shift_in <= '0';
      -- This has been done since we want to feedforward tick reset
      tick_reset <= '1';
      dout_enable <= '0';
    else
      shift_in <= nshift_in;
      tick_reset <= ntick_reset;
      dout_enable <= ndout_enable;
    end if;
  end process;

  -- This process decides the next state of FSM
  process(state, clk, reset, data_in, tick_half, tick, received, count_sig)
    variable nstate: FsmState;
    variable count_var: Integer := 0;
    variable ndata_ready: std_logic := '0';
  begin
    nstate := S0;
    count_var := count_sig;
    ndata_ready := '0';
    case state is
      when S0 =>
        ndata_ready := '0';
        -- This is the reset state
        nstate := S1;
      when S1 =>
        ndata_ready := '0';
        -- In this state, the receiver waits for UART
        if data_in = '0' then
          -- Received an input, begin UART sequence
          nstate := S5;
        else
          nstate := S1;
        end if;
        count_var := 0;
      when S5 =>
        ndata_ready := '0';
        -- This state confirms that the data_in is actually 0
        -- This is done to correct sampling errors
        count_var := count_var + 1;
        if count_var = 7 then
          if data_in = '0' then
            nstate := S2;
          else
            nstate := S1;
          end if;
        else
          nstate := S5;
        end if;
      when S2 =>
        ndata_ready := '0';
        -- In this state, the counter increments till it hits T/2
        -- This is done for clock synchronization
        if tick_half = '1' then
          nstate := S3;
        else
          nstate := S2;
        end if;
      when S3 =>
        ndata_ready := '0';
        -- In this state, the counter samples every T seconds
        if tick = '1' and received = '1' then
          nstate := S4;
        else
          nstate := S3;
        end if;
      when S4 =>
        ndata_ready := '1';
        nstate := S1;
    end case;
    -- Creating the latch
    if (clk'event and clk = '1') then
      if (reset = '1') then
        state <= S0;
        count_sig <= 0;
        data_ready <= '0';
      else
        state <= nstate;
        count_sig <= count_var;
        data_ready <= ndata_ready;
      end if;
    end if;
  end process;
end Behave;

library ieee;
use ieee.std_logic_1164.all;
use work.UARTComponents.all;
entity UARTReceiverData is
  port (
    data_in: in std_logic;
    tick_half: out std_logic;
    debug: out std_logic_vector(7 downto 0);
    tick: out std_logic;
    received: out std_logic;
    clk, reset: in std_logic;
    shift_in: in std_logic;
    dout_enable: in std_logic;
    tick_reset: in std_logic;
    data_out: out std_logic_vector(7 downto 0)
  );
end entity;

architecture Mixed of UARTReceiverData is
  signal SHIFT_OUT: std_logic_vector(9 downto 0);
  signal SHIFT: std_logic_vector(9 downto 0);
  signal COUNT_IN: std_logic_vector(3 downto 0);
  signal COUNT: std_logic_vector(3 downto 0);
  signal INC_OUT: std_logic_vector(3 downto 0);
  signal CONST_0: std_logic_vector(3 downto 0) := "0000";
  -- Taken as 9 since UART is assumed to have no parity bit
  signal LIMIT: std_logic_vector(3 downto 0) := "1001";
  signal count_enable: std_logic;
begin
  tc: UARTTicker
      port map (
        clk => clk,
        reset => reset,
        tick => tick,
        tick_half => tick_half,
        tick_reset => tick_reset
      );

  incr: Increment4 port map (input => COUNT, output => INC_OUT);
  COUNT_in <= CONST_0 when (COUNT = LIMIT) else INC_OUT;

  received <= '1' when (COUNT = LIMIT) else '0';
  count1: DataRegister
           generic map (data_width => 4)
           port map (Din => COUNT_IN,
                     Dout => COUNT,
                     Enable => shift_in,
                     reset => reset,
                     clk => clk);
  debug(7 downto 0) <= SHIFT_OUT(8 downto 1);
  shift_r: DataRegister
           generic map (data_width => 10)
           port map (Din => SHIFT,
                     Dout => SHIFT_OUT,
                     Enable => shift_in,
                     reset => reset,
                     clk => clk);

  dout: DataRegister
        generic map (data_width => 8)
        port map (Din => SHIFT_OUT(8 downto 1),
                  Dout => data_out,
                  Enable => dout_enable,
                  reset => reset,
                  clk => clk);
  SHIFT(8 downto 0) <= SHIFT_OUT(9 downto 1);
  SHIFT(9) <= data_in;

end Mixed;