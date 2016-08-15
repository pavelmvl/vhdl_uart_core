
library IEEE;
use IEEE.std_logic_1164.ALL;

package uart is

  type PARITY_TYPE   is ( NONE, EVEN, ODD );
  type STOP_BIT_TYPE is ( S1, S2 );

  component uart_rx is
    Generic (
      PARITY                              :        PARITY_TYPE          := NONE;      -- { NONE, EBEN( '0' when parity even number), ODD }
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
  end component uart_rx;

  component uart_tx is
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
  end component uart_tx;

end package uart;

