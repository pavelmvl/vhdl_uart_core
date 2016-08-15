----------------------------------------------------------------------------------
-- Company    : DB Radar
-- Engineer   : pavelmvl
-- 
-- Create Date: 07/03/2016 12:07:31 PM
-- Design Name: 
-- Module Name: uart_rx - RTL
-- Project Name: hdl17 rev. A
-- Target Devices: ARTIX-7
-- Tool Versions: PlanAhead v14.7
-- Description: module tested only in 8N1 mode
-- 
-- Dependencies: package 'uart' from file 'uart.vhd'
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
--use work.uart.ALL;
use work.uart.PARITY_TYPE;
use work.uart.STOP_BIT_TYPE;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_rx is
  Generic (
    PARITY                              :        PARITY_TYPE          := NONE;      -- { NONE, EVEN( '0' when parity even number), ODD }
    STOP_BIT                            :        STOP_BIT_TYPE        := S1         -- { S1, S2 }
  );
  Port    (
    CLK                                 : in     std_logic;
    CLK_EN                              : in     std_logic;
    RST                                 : in     std_logic;
    rxd                                 : in     std_logic;
    dout                                :   out  std_logic_vector( 7 downto  0 );
    dout_str                            :   out  std_logic;
    derr                                :   out  std_logic
  );
end uart_rx;

architecture RTL of uart_rx is

-- declare type of module state:
--  idle    - wait for start bit
--  data    - receive some bits used by rules PARITY and STOP_BIT
--  check   - set parity bit or stop if parity is disabled
--  stop_s1 - when parity is enabled set first stop bit
--  stop_s2 - when STOP_BIT is S2 value transmit second stop bit
--  err     - this case need for test module
--  success - end of transmiting byte and goto idle
  type rxd_state_type is ( idle, data, check, stop_s1, stop_s2 );

  signal            err_state           :        std_logic_vector( 7 downto  0 ); -- test state
  signal            rxd_state           :        rxd_state_type;

  signal            parity_value        :        std_logic;                       -- value for parity calculating

  signal            rxd_rst             :        std_logic;
  signal            rxd_vector          :        std_logic_vector( 8 downto  0 ); -- shit register for receiving data
  signal            rxd_hold            :        std_logic_vector( 7 downto  0 ); -- hold data register

begin

  dout          <= rxd_hold;
  dout_str      <= '1' when rxd_state = check else '0';

  derr          <= '0' when err_state = x"00" else '1';


  rxd_rst       <= '1' when rxd_state = check else '0';

rxd_vector_shift_process:process( CLK )
  begin
    if falling_edge( CLK ) then
      if RST = '1' or rxd_rst = '1' then
        rxd_vector <= ( others => '1' );
      else -- RST = '1'
          if CLK_EN = '1' then
            rxd_vector <= rxd & rxd_vector( rxd_vector'length - 1 downto 1 );
          end if; -- CLK_EN = '1'
      end if; -- else RST = '1'
    end if; -- elsif rising_edge( CLK )
  end process;


rxd_hold_process:process( CLK )
  begin
    if rising_edge( CLK ) then -- RST = '1'
      if RST = '1' then
        rxd_hold <= ( others => '0' );
      else -- RST = '1'
          if CLK_EN = '1' then
            if rxd_vector ( 0 ) = '0' and rxd_state = data then
              rxd_hold <= rxd_vector(  8 downto  1 );
            else -- rxd_vector ( 0 ) = '0' and rxd_state = data
              null;
            end if; -- else rxd_vector ( 0 ) = '0' and rxd_state = data
          end if; -- CLK_EN = '1'
      end if; -- else RST = '1'
    end if; -- rising_edge( CLK )
  end process;
  
rxd_state_process:process( CLK, RST )
  begin
    if rising_edge( CLK ) then -- RST = '1'
      if RST = '1' then
        err_state <= ( others => '0' );
        rxd_state <= idle;
      else -- RST = '1'
          if CLK_EN = '1' then
            case rxd_state is
              when idle       =>
                  err_state   <= ( others => '0' );
                  if rxd = '1' then
                    rxd_state <= idle;
                  else
                    rxd_state <= data;
                  end if;
                  parity_value<= '0';
              -- case rxd_state when idle
              when data       =>
                  if rxd_vector( 0 ) = '0' then
                    rxd_state <= check;
                  else
                    rxd_state <= data;
                    parity_value <= parity_value xor rxd;
                  end if;
              -- case rxd_state when data
              when check      => -- parity checking
                  case PARITY is
                    when NONE =>
                        if STOP_BIT = S1 then
                          if rxd = '1' then
                            rxd_state <= idle;
                          else -- rxd = '1'
                            err_state( 2 ) <= '1'; -- error STOP_S1 PARITY fail
                            rxd_state <= idle;
                          end if; -- else rxd = '1'
                        else -- STOP_BIT = S1
                          rxd_state <= stop_s2;
                        end if; -- else STOP_BIT = S1
                    -- case PARITY when NONE
                    when EVEN =>
                        if parity_value = rxd then
                          null;
                        else -- parity_value = rxd
                          err_state <= x"01"; -- error PARITY EVEN fail
                          rxd_state <= idle;
                        end if; -- else parity_value = rxd_vector( rxd_vector'length - 9 )
                    when ODD  =>
                        if not parity_value = rxd then
                          null;
                        else -- parity_value = rxd
                          err_state <= x"2"; -- error PARITY ODD fail
                          rxd_state <= idle;
                        end if; -- else parity_value = rxd
                  end case; -- PARITY
                  if STOP_BIT = S1 then
                    rxd_state <= stop_s1;
                  else -- rxd = '1'
                    rxd_state <= stop_s2;
                  end if; -- else rxd = '1'
              -- case rxd_state when check
              when stop_s1    =>
                  if STOP_BIT = S1 then
                    if rxd = '1' then
                      rxd_state <= idle;
                    else -- rxd = '1'
                      err_state <= x"10"; -- error STOP_S1 fail
                      rxd_state <= idle;
                    end if; -- else rxd = '1'
                  else -- STOP_BIT = S1
                    rxd_state <= stop_s2;
                  end if; -- else STOP_BIT = S1
              -- case rxd_state when stop_s1
              when stop_s2    =>
                  if rxd = '1' then
                    rxd_state <= idle;
                  else -- rxd = '1'
                    err_state <= x"20"; -- error STOP_S1 fail
                    rxd_state <= idle;
                  end if; -- else rxd = '1'
              -- case rxd_state when stop_s2
            end case; -- case rxd_state
          end if; -- CLK_EN = '1'
      end if; -- else RST = '1'
    end if; -- rising_edge( CLK )
  end process;

end RTL;

