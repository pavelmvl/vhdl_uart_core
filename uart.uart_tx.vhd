----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/03/2016 12:07:31 PM
-- Design Name: 
-- Module Name: uart_tx - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_tx is
  Generic (
    PARITY                              :        PARITY_TYPE          := NONE;      -- { NONE, EVEN( '0' when parity even number), ODD }
    STOP_BIT                            :        STOP_BIT_TYPE        := S1         -- { S1, S2 }
  );
  Port    (
    CLK                                 : in     std_logic;
    CLK_EN                              : in     std_logic;
    RST                                 : in     std_logic;
    TXD                                 :   out  std_logic;
    UART_INP_DATA                       : in     std_logic_vector( 7 downto  0 );
    UART_INP_WE                         : in     std_logic;
    UART_INP_READY                      :   out  std_logic
  );
end uart_tx;

architecture RTL of uart_tx is

  type txd_state_type is ( idle, t_start, t_data, t_parity, t_stop_1, t_stop_2 );

  signal            txd_state           :        txd_state_type;

  signal            t_counter           :        integer range 0 to 8;
  
  signal            parity_value        :        std_logic;

  signal            txd_index           :        integer range 0 to 7;
  signal            txd_vector          :        std_logic_vector( 9 downto  0 );
  signal            txd_hold            :        std_logic_vector( 7 downto  0 );

begin

  TXD                                   <= txd_vector( 0 );

txd_process:process( RST, CLK )
  begin
    if rising_edge( CLK ) then -- RST = '1'
      if RST = '1' then
        txd_hold                        <= x"FF";
        txd_vector                      <= ( others => '1' );
        txd_state                       <= idle;
        t_counter                       <=  0;
        parity_value                    <= '0';
      else -- RST = '1'
          if CLK_EN = '1' then
            case txd_state is
              when idle =>
                  if UART_INP_WE = '1' then
                    txd_hold            <= UART_INP_DATA;
                    txd_state           <= t_start;
                    UART_INP_READY      <= '0';
                  else -- UART_INP_WE = '1'
                    txd_state           <= idle;
                    UART_INP_READY      <= '1';
                  end if; -- else UART_INP_WE = '1'
              -- case txd_state when idle
              when t_start  =>
                parity_value            <= '0';
                txd_vector( 8 downto 0 )<= txd_hold & '0';
                txd_state               <= t_data;
              -- case txd_state when t_statr
              when t_data =>
                  parity_value          <= parity_value xor txd_vector( 0 );
                  txd_vector            <= '1' & txd_vector( txd_vector'length - 1 downto  1 );
                  if t_counter < 8 then
                    t_counter           <= t_counter + 1;
                  else -- t_counter < 8
                    t_counter           <=  0;
                    txd_state           <= t_parity;
                  end if; -- else t_counter < 8
              -- case txd_state when t_data
              when t_parity =>
                  if PARITY = NONE then
                    txd_state           <= idle;
                    txd_vector          <= '1' & txd_vector( txd_vector'length - 1 downto  1 );
                  else -- PARITY = NONE
                    txd_state           <= t_stop_1;
                    if PARITY = EVEN then
                      txd_vector( 0 )   <= parity_value;
                    else -- PARITY = EVEN
                      txd_vector( 0 )   <= not parity_value;
                    end if; -- else PARITY = EVEN
                  end if; -- else PARITY = NONE
              -- case txd_state when t_parity
              when t_stop_1 =>
                  txd_vector            <= '1' & txd_vector( txd_vector'length - 1 downto  1 );
                  if STOP_BIT = S1 then
                    txd_state           <= idle;
                  else -- STOP_BIT = S1
                    txd_state           <= t_stop_2;
                  end if; -- else STOP_BIT = S1
              -- case txd_state when t_stop_1
              when t_stop_2 =>
                  txd_state             <= idle;
              -- case txd_state when t_stop_2
              when others =>
            end case; -- txd_state
          end if; -- CLK_EN = '1'
      end if; -- else rst = '1'
    end if; -- rising_edge( CLK )
  end process;

end RTL;

