library std;
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.UARTComponents.all;
entity SMC is
  port(
    io: inout std_logic_vector(7 downto 0);
    output_data: out std_logic_vector(7 downto 0);
    input_data: in std_logic_vector(7 downto 0);
    OE, WE, CS: out std_logic;
    address: out std_logic_vector(14 downto 0);
    clk, reset: in std_logic;
    read_data: in std_logic;
    data_ready: in std_logic;
    debug: out std_logic_vector(7 downto 0)
  );
end entity SMC;

architecture Struct of SMC is
  type FsmState is (S0, S1);
  signal state: FsmState;
  signal CONTROL_IN: std_logic_vector(2 downto 0);
  signal write_wait, read_wait: std_logic;
  signal addr_select: std_logic_vector(2 downto 0);
  signal io_select, output_select, output_enable: std_logic;
  signal write_addr_enable, read_addr_enable: std_logic;
begin

  cntrl: SMCControl
    port map (
      clk => clk,
      reset => reset,
      CONTROL_IN => CONTROL_IN,
      io_select => io_select,
      output_select => output_select,
      output_enable => output_enable,
      read_addr_enable => read_addr_enable,
      write_addr_enable => write_addr_enable,
      data_ready => data_ready,
      read_data => read_data,
      addr_select => addr_select,
      write_wait => write_wait,
      read_wait => read_wait
    );

  data: SMCData
    port map (
      io => io,
      output_data => output_data,
      input_data => input_data,
      OE => OE, WE => WE, CS => CS,
      address => address,
      clk => clk,
      reset => reset,
      CONTROL_IN => CONTROL_IN,
      io_select => io_select,
      output_select => output_select,
      output_enable => output_enable,
      read_addr_enable => read_addr_enable,
      write_addr_enable => write_addr_enable,
      addr_select => addr_select,
      write_wait => write_wait,
      read_wait => read_wait,
      debug => debug
    );
end Struct;

library std;
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.UARTComponents.all;
entity SMCControl is
  port(
    clk, reset: in std_logic;
    data_ready: in std_logic;
    read_data: in std_logic;
    -- The set of CS/OE/WE control signals in next clock cycle
    CONTROL_IN: out std_logic_vector(2 downto 0);
    write_wait: in std_logic;
    read_wait: in std_logic;
    addr_select: out std_logic_vector(2 downto 0);
    io_select, output_select, output_enable: out std_logic;
    write_addr_enable, read_addr_enable: out std_logic
  );
end entity SMCControl;

architecture Mixed of SMCControl is
  type FsmState is (S0, S1, S2, S3, S4, S5, S6, S7, S8);
  signal state: FsmState;
begin
  process(state, reset, data_ready, write_wait, read_wait)
    variable nCONTROL_IN: std_logic_vector(2 downto 0);
    variable nread_addr_enable, nwrite_addr_enable: std_logic;
    variable naddr_select: std_logic_vector(2 downto 0);
    variable nio_select: std_logic;
    variable noutput_enable, noutput_select: std_logic;
  begin
    nCONTROL_IN := "111";
    naddr_select := "000";
    nread_addr_enable := '0';
    nwrite_addr_enable := '0';
    nio_select := '0';
    noutput_select := '0';
    noutput_enable := '0';
    case state is
      when S0 =>
        nCONTROL_IN := "111";
        nwrite_addr_enable := '0';
        nread_addr_enable := '0';
        naddr_select := "000";
        nio_select := '0';
        noutput_enable := '0';
        noutput_select := '0';
      when S1 =>
        nCONTROL_IN := "011";
        nwrite_addr_enable := '1';
        nread_addr_enable := '0';
        naddr_select := "001";
        nio_select := '0';
        noutput_select := '0';
        noutput_enable := '0';
      when S2 =>
        nCONTROL_IN := "001";
        nwrite_addr_enable := '0';
        nread_addr_enable := '0';
        naddr_select := "001";
        nio_select := '0';
        noutput_select := '0';
        noutput_enable := '0';
      when S3 =>
        if write_wait = '1' then
          nCONTROL_IN := "001";
        else
          nCONTROL_IN := "111";
        end if;
        nwrite_addr_enable := '0';
        nread_addr_enable := '0';
        naddr_select := "001";
        nio_select := '1';
        noutput_select := '0';
        noutput_enable := '0';
      when S4 =>
        nCONTROL_IN := "111";
        nwrite_addr_enable := '0';
        nread_addr_enable := '0';
        naddr_select := "001";
        nio_select := '1';
        noutput_select := '0';
        noutput_enable := '0';
      when S5 =>
        nCONTROL_IN := "011";
        nwrite_addr_enable := '0';
        nread_addr_enable := '1';
        naddr_select := "010";
        nio_select := '0';
        noutput_select := '0';
        noutput_enable := '0';
      when S6 =>
        nCONTROL_IN := "010";
        nwrite_addr_enable := '0';
        nread_addr_enable := '0';
        naddr_select := "010";
        nio_select := '0';
        noutput_select := '0';
        noutput_enable := '0';
      when S7 =>
        nwrite_addr_enable := '0';
        nread_addr_enable := '0';
        naddr_select := "010";
        nio_select := '0';
        if read_wait = '1' then
          nCONTROL_IN := "010";
        else
          nCONTROL_IN := "111";
          noutput_select := '1';
          noutput_enable := '1';
        end if;
      when S8 =>
        nCONTROL_IN := "111";
        nwrite_addr_enable := '0';
        nread_addr_enable := '0';
        naddr_select := "010";
        nio_select := '0';
        noutput_select := '0';
        noutput_enable := '0';
    end case;
    if reset = '1' then
      CONTROL_IN <= "111";
      read_addr_enable <= '0';
      write_addr_enable <= '0';
      io_select <= '0';
      addr_select <= "000";
      output_enable <= '0';
      output_select <= '0';
    else
      CONTROL_IN <= nCONTROL_IN;
      write_addr_enable <= nwrite_addr_enable;
      read_addr_enable <= nread_addr_enable;
      io_select <= nio_select;
      addr_select <= naddr_select;
      output_select <= noutput_select;
      output_enable <= noutput_enable;
    end if;
  end process;
  process(state, clk, reset, data_ready, read_data, read_wait, write_wait)
    variable nstate: FsmState;
  begin
    nstate := S0;
    case state is
      when S0 =>
        if read_data = '1' then
          -- Begin read sequence, given preference over write
          nstate := S5;
        elsif data_ready = '1' then
          -- Begin write sequence
          nstate := S1;
        else
          nstate := S0;
        end if;
      when S1 =>
        -- This state lowers CS and puts the next write address
        nstate := S2;
      when S2 =>
        -- This state begins the write sequence
        nstate := S3;
      when S3 =>
        -- This state is the wait state where writing is happening
        if write_wait = '0' then
          nstate := S4;
        else
          nstate := S3;
        end if;
      when S4 =>
        -- Last state to finish off writing
        nstate := S0;
      when S5 =>
        -- This state lowers CS and puts the next read address
        nstate := S6;
      when S6 =>
        -- This state begins the read sequence
        nstate := S7;
      when S7 =>
        -- This is the wait stage for read cycle
        if read_wait = '0' then
          nstate := S8;
        else
          nstate := S7;
        end if;
      when S8 =>
        -- This state finishes off the read cycle
        nstate := S0;
    end case;
    if (clk'event and clk = '1') then
      if (reset = '1') then
        state <= S0;
      else
        state <= nstate;
      end if;
    end if;
  end process;
end Mixed;


library std;
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.UARTComponents.all;
entity SMCData is
  port(
    io: inout std_logic_vector(7 downto 0);
    output_data: out std_logic_vector(7 downto 0);
    input_data: in std_logic_vector(7 downto 0);
    OE, WE, CS: out std_logic;
    write_wait: out std_logic;
    read_wait: out std_logic;
    address: out std_logic_vector(14 downto 0);
    clk, reset: in std_logic;
    -- The set of CS/OE/WE control signals in next clock cycle
    CONTROL_IN: in std_logic_vector(2 downto 0);
    addr_select: in std_logic_vector(2 downto 0);
    io_select, output_select, output_enable: in std_logic;
    read_addr_enable, write_addr_enable: in std_logic;
    debug: out std_logic_vector(7 downto 0)
  );
end entity SMCData;

architecture Mixed of SMCData is
  signal OUTPUT_IN: std_logic_vector(7 downto 0);
  signal CONTROL: std_logic_vector(2 downto 0);
  -- signals for writing
  signal WAIT_VALUE: std_logic_vector(3 downto 0);
  signal WAIT_LIMIT: std_logic_vector(3 downto 0) := "0110";
  signal WRITE_WAIT_IN: std_logic_vector(3 downto 0);
  signal WRITE_WAIT_INC: std_logic_vector(3 downto 0);
  -- signals for reading
  signal READ_WAIT_VALUE: std_logic_vector(31 downto 0);
  signal READ_WAIT_IN: std_logic_vector(31 downto 0);
  signal READ_WAIT_INC: std_logic_vector(31 downto 0);
  signal READ_WAIT_LIMIT: std_logic_vector(31 downto 0) := (25 => '1', others => '0');

  signal READ_ADDRESS: std_logic_vector(14 downto 0);
  signal READ_ADDRESS_INC: std_logic_vector(14 downto 0);
  signal READ_ADDRESS_IN: std_logic_vector(14 downto 0);
  signal WRITE_ADDRESS: std_logic_vector(14 downto 0);
  signal WRITE_ADDRESS_INC: std_logic_vector(14 downto 0);
  signal WRITE_ADDRESS_IN: std_logic_vector(14 downto 0);
  signal addr_enable: std_logic;
  signal ADDRESS_IN: std_logic_vector(14 downto 0);
begin
  io <= input_data when io_select = '1' else (others => 'Z');

  -- Read specifications
  inc4: Increment32
          port map (
            input => READ_WAIT_VALUE,
            output => READ_WAIT_INC
          );
  read_wait <= '0' when (READ_WAIT_VALUE = READ_WAIT_LIMIT) else '1';
  READ_WAIT_IN <= READ_WAIT_INC when (READ_WAIT_VALUE /= READ_WAIT_LIMIT) else (others => '0');
  rw: DataRegister
        generic map (data_width => 32)
        port map (
          clk => clk,
          reset => reset,
          Din => READ_WAIT_IN,
          Dout => READ_WAIT_VALUE,
          Enable => '1'
        );

  -- Write specifications
  inc3: Increment4
          port map (
            input => WAIT_VALUE,
            output => WRITE_WAIT_INC
          );
  write_wait <= '0' when (WAIT_VALUE = WAIT_LIMIT) else '1';
  WRITE_WAIT_IN <= WRITE_WAIT_INC when io_select = '1' else "0000";
  ww: DataRegister
        generic map (data_width => 4)
        port map (
          clk => clk,
          reset => reset,
          Din => WRITE_WAIT_IN,
          Dout => WAIT_VALUE,
          Enable => '1'
        );

  -- Address specifications
  incr2: Increment15
          port map (
            input => WRITE_ADDRESS,
            output => WRITE_ADDRESS_INC
          );
  incr5: Increment15
          port map (
            input => READ_ADDRESS,
            output => READ_ADDRESS_INC
          );

  READ_ADDRESS_IN <= READ_ADDRESS_INC;
  WRITE_ADDRESS_IN <= WRITE_ADDRESS_INC;

  ADDRESS_IN <= WRITE_ADDRESS when addr_select = "001" else
                READ_ADDRESS when addr_select = "010" else
                (others => '0');
  debug(7 downto 0) <= ADDRESS_IN(7 downto 0);
  addr_enable <= write_addr_enable or read_addr_enable;

  addr: DataRegister
          generic map (data_width => 15)
          port map (
            Din => ADDRESS_IN,
            Dout => address,
            Enable => addr_enable,
            reset => reset,
            clk => clk
          );
  waddr: DataRegister
          generic map (data_width => 15)
          port map (
            Din => WRITE_ADDRESS_IN,
            Dout => WRITE_ADDRESS,
            Enable => write_addr_enable,
            reset => reset,
            clk => clk
          );
  raddr: DataRegister
          generic map (data_width => 15)
          port map (
            Din => READ_ADDRESS_IN,
            Dout => READ_ADDRESS,
            Enable => read_addr_enable,
            reset => reset,
            clk => clk
          );

  -- Control specifications
  CS <= CONTROL(2);
  WE <= CONTROL(1);
  OE <= CONTROL(0);
  contrl: DataRegisterSp
          generic map (data_width => 3)
          port map (
            Din => CONTROL_IN,
            Dout => CONTROL,
            Enable => '1',
            reset => reset,
            clk => clk
          );

  -- output specifications
  OUTPUT_IN <= io when output_select = '1' else "11111111";
  output: DataRegister
          generic map (data_width => 8)
          port map (
            Din => OUTPUT_IN,
            Dout => output_data,
            Enable => output_enable,
            reset => reset,
            clk => clk
          );
end Mixed;