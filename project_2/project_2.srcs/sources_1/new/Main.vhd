----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.11.2022 21:13:47
-- Design Name: 
-- Module Name: Main - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use work.Ascii.all;
use work.LED.all;

library fixed;
use fixed.fixed_pkg.all;

use work.SFixedMultiplierInterface.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Main is
    Port ( clk, sw      : in STD_LOGIC;
           RsTx         : out std_logic;
           led          : out std_logic_vector(0 to 15);
           i2s_din      : in std_logic;
           i2s_clk_out  : out std_logic;
           i2s_lrcl     : out std_logic;
           led_dout     : out std_logic);
end Main;

architecture Behavioral of Main is

subtype Byte is std_logic_vector(7 downto 0);
subtype Printable is natural range 33 to 126;

--The type definition for the UART state machine type. Here is a description of what
--occurs during each state:
-- SEND_CHAR   -- uartSend is set high for a single clock cycle, signaling the character
--                data at sendStr(strIndex) to be registered by the UART_TX_CTRL at the next
--                cycle. Also, strIndex is incremented (behaves as if it were post 
--                incremented after reading the sendStr data). The state is set to RDY_LOW.
-- RDY_LOW     -- Do nothing. Wait for the READY signal from the UART_TX_CTRL to go low, 
--                indicating a send operation has begun. State is set to WAIT_RDY.
-- WAIT_RDY    -- Do nothing. Wait for the READY signal from the UART_TX_CTRL to go high, 
--                indicating a send operation has finished. If READY is high and strEnd = 
--                StrIndex then state is set to WAIT_BTN, else if READY is high and strEnd /=
--                StrIndex then state is set to SEND_CHAR.
-- WAIT_SEND    -- Do nothing. Wait for the send to become asserted.
type UART_STATE_TYPE is (SEND_CHAR, RDY_LOW, WAIT_RDY, WAIT_SEND);




constant MAX_STR_LEN : integer := 27;

--Contains the current string being sent over uart.
signal uart_str : CHAR_ARRAY(0 to 13) := (others=>(others=>'0'));--(X"48", X"65", X"6C", X"6C", X"6F", X"20", X"77", X"6F", X"72", X"6C", X"64", X"21", X"0A", X"0D");

--Contains the length of the current string being sent over uart.
signal strEnd : natural := 0;


--Contains the index of the next character to be sent over uart
--within the uart_str variable.
signal strIndex : natural := 0;

--Used to start a send of a string
signal uart_str_send : std_logic := '0';

--UART_TX_CTRL control signals
signal uart_ready : std_logic;
signal uart_send : std_logic := '0';
signal uart_data : std_logic_vector (7 downto 0):= "00000000";
signal uart_tx : std_logic;

--Current uart state signal
signal uart_state : UART_STATE_TYPE := WAIT_SEND;

-- I2S
signal i2s_data_ready : STD_LOGIC  := '0';
signal i2s_sample_out : signed (31 downto 0);
signal i2s_data_channel : std_ulogic;
signal audio_sample : std_logic_vector (17 downto 0) := "010101010101010101";  
    
-- LED Strip
constant N_LEDS : integer := 144;
signal leds : led_array(0 to N_LEDS - 1) := ((r => (others => '1'), g => (others => '0'), b => (others => '0'), w => (others => '0')), (r => (others => '0'), g => (others => '1'), b => (others => '0'), w => (others => '0')), (r => (others => '0'), g => (others => '0'), b => (others => '1'), w => (others => '0')), 
others=>(others=>(others=>'0')));
signal led_ready : std_logic;
signal led_send : std_logic;


-- Goertzels
signal madd_input : MultAddInput;
signal madd_output : MultAddOutput;

signal readies : std_ulogic_vector(4 downto 0);

constant GOERTZEL_B : positive := 7;
constant GOERTZEL_F : positive := 11;
signal goertzel_in_ready : std_ulogic;
signal goertzel_out_data : FP;
signal goertzel_out_valid : std_ulogic;
signal goertzel_in_valid : std_ulogic := '0';
signal goertzel_in_data : FP;


-----------------------------------------------------------
-----------------------------------------------------------
-----------------------------------------------------------
begin


uart : entity work.UART_TX_CTRL port map (
    SEND => uart_send,
    DATA => uart_data,
    CLK => clk,
    READY => uart_ready,
    UART_TX => uart_tx
);

i2s : entity work.I2SMaster port map (
    clk => clk,
    din => i2s_din,
    data_ready => i2s_data_ready,
    data_channel => i2s_data_channel,
    dout => i2s_sample_out,
    ws => i2s_lrcl,
    clk_out => i2s_clk_out
);

multiply_scheduler : entity work.RoundRobinScheduler
generic map ( N => 5)
port map (
    clk => clk,
    start => clk,
    readies => readies
    );

multiply_add : entity work.sfixed_multiplier
port map (
    clk => clk,
    ins => madd_input,
    outs => madd_output
);

goertzel0 : entity work.goertzel
generic map(
    N => 2376,
    k => 27
)
port map(
	clk => clk,
	in_data => goertzel_in_data,
	in_ready => goertzel_in_ready,
	in_valid => goertzel_in_valid,
	
	out_data => goertzel_out_data,
	out_valid => goertzel_out_valid,
	
	multaddin => madd_input,
	multaddout => madd_output
);


led_strip : entity work.sk6812
generic map (
    N => N_LEDS,
    clk_period => 10ns
)
port map (
    clk => clk,
    leds => leds,
    send => led_send,
    ready => led_ready,
    dout => led_dout
);



----------------------------------------------------------
------               Goertzel                      -------
----------------------------------------------------------

process (clk)
type WaitState is (SoTX, EoTX);
variable wait_state : WaitState := EoTX;
begin
    if rising_edge(clk) then       
        case wait_state is
            when SoTX =>
		        if uart_state /= WAIT_SEND then
                    wait_state := EoTX;                    
                    uart_str_send <= '0';
                end if;
            when EoTX =>
                if uart_state = WAIT_SEND and goertzel_out_valid = '1' then
                    uart_str(3) <= to_slv(goertzel_out_data)(MULTIPLIER_WIDTH - 1 - 24 downto MULTIPLIER_WIDTH - 24 - 8);
                    uart_str(2) <= to_slv(goertzel_out_data)(MULTIPLIER_WIDTH - 1 - 16 downto MULTIPLIER_WIDTH - 16 - 8);
                    uart_str(1) <= to_slv(goertzel_out_data)(MULTIPLIER_WIDTH - 1 - 8  downto MULTIPLIER_WIDTH - 8  - 8);
                    uart_str(0) <= to_slv(goertzel_out_data)(MULTIPLIER_WIDTH - 1      downto MULTIPLIER_WIDTH      - 8);
                    strEnd <= 4;
                    uart_str_send <= '1';
                    wait_state := SoTX;
                end if;
        end case;
    end if;    
end process;


----------------------------------------------------------
------               LED Stuff                     -------
----------------------------------------------------------

feed_leds : process(clk)
variable counter : natural range 0 to 10000000;
begin
    if rising_edge(clk) then
        led_send <= '1' when led_ready = '1' else '0';
        
        if led_ready = '1' and counter = 10000000 then
            leds <= leds(1 to N_LEDS - 1) & leds(0);
            counter := 0;
        else
            if counter < 10000000 then
                counter := counter + 1;
            end if;
        end if;
    end if;
end process;


----------------------------------------------------------
------            Microphone Logging               -------
----------------------------------------------------------

process (clk)
variable conv : std_ulogic_vector(17 downto 0);
variable conv2 : std_ulogic_vector(MULTIPLIER_LEFT downto MULTIPLIER_RIGHT);
begin
    if rising_edge(clk) then
        if i2s_data_ready = '1' and i2s_data_channel = '0' then
            conv := std_logic_vector(i2s_sample_out(31 downto 14));
            audio_sample <= conv;
            
            conv2 := (MULTIPLIER_LEFT downto MULTIPLIER_LEFT - 18 + 1 => conv, others => '0');
            goertzel_in_data <= to_sfixed(conv2, MULTIPLIER_LEFT, MULTIPLIER_RIGHT);
            goertzel_in_valid <= '1';
        else
            goertzel_in_valid <= '0';
        end if;
    end if;
end process;

--process (clk)
--type WaitState is (SoTX, EoTX);
--variable wait_state : WaitState := EoTX;
--begin
--    if rising_edge(clk) then       
--        case wait_state is
--            when SoTX =>
--		        if uart_state /= WAIT_SEND then
--                    wait_state := EoTX;                    
--                    uart_str_send <= '0';
--                end if;
--            when EoTX =>
--                if uart_state = WAIT_SEND then
--                    uart_str(0) <= audio_sample(17 downto 10);
--                    uart_str(1) <= audio_sample(9 downto 2);
--                    strEnd <= 2;
--                    uart_str_send <= '1';
--                    wait_state := SoTX;
--                end if;
--        end case;
--    end if;    
--end process;


----------------------------------------------------------
------              UART Control                   -------
----------------------------------------------------------


--Next Uart state logic (states described above)
next_uart_state_process : process (CLK)
begin
	if (rising_edge(CLK)) then
        case uart_state is
        when SEND_CHAR =>
            uart_state <= RDY_LOW;
        when RDY_LOW =>
            uart_state <= WAIT_RDY;
        when WAIT_RDY =>
            if (uart_ready = '1') then
                if (strEnd = strIndex) then
                    uart_state <= WAIT_SEND;
                else
                    uart_state <= SEND_CHAR;
                end if;
            end if;
        when WAIT_SEND =>
            if (uart_str_send = '1') then
                uart_state <= SEND_CHAR;
            end if;
        end case;
	end if;
end process;


--Conrols the strIndex signal so that it contains the index
--of the next character that needs to be sent over uart
char_count_process : process (CLK)
begin
	if (rising_edge(CLK)) then
		if (uart_state = WAIT_SEND) then
			strIndex <= 0;
		elsif (uart_state = SEND_CHAR) then
			strIndex <= strIndex + 1;
		end if;
	end if;
end process;

--Controls the UART_TX_CTRL signals
char_load_process : process (CLK)
begin
	if (rising_edge(CLK)) then
		if (uart_state = SEND_CHAR) then
			uart_send <= '1';
			uart_data <= uart_str(strIndex);
		else
			uart_send <= '0';
		end if;
	end if;
end process;


RsTx <= uart_tx;
led(5 to 15) <= audio_sample(17 downto 7);
led(0) <= '1' when goertzel_out_data > to_sfixed(2, MULTIPLIER_LEFT, MULTIPLIER_RIGHT) else '0';
--led(4) <= '1' when debug_state = Sampling else '0';
--led(3) <= '1' when debug_state = SendingSamples else '0';
--led(2) <= '1' when debug_state = FFTFeeding else '0';
--led(1) <= '1' when debug_state = FFTUnloading else '0';
--led(0) <= '1' when debug_state = SendingSpectrum else '0';

--dontremove : process(clk)
--begin
--    if rising_edge(clk) then
--        if goertzel_out_valid = '1' then
--            led(0) <= '1' when goertzel_out_data > to_sfixed(1.0, GOERTZEL_B, -GOERTZEL_F) else '0';
--        end if;
--    end if;
--end process;

end Behavioral;
