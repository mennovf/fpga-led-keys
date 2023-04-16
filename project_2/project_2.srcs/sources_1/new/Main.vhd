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

type NoteDetector is record
    N : positive;
    k : positive;
    threshold : FP;
    ledid : natural;
end record;

constant BIN_SIZE : positive := 11;
constant N_BINS   : positive := 8;
constant N_DETECTORS : positive := BIN_SIZE * N_BINS;

type NoteDetectorArray is array (natural range <>) of NoteDetector;
type NoteDetectorBins is array (natural range 0 to N_BINS - 1) of NoteDetectorArray(0 to BIN_SIZE - 1);
type IndexArray is array (natural range <>) of natural range 0 to BIN_SIZE-1;
constant NOTE_DETECTORS : NoteDetectorBins := (((k => 17, N => 23889, ledid => 0, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 23889, ledid => 1, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 22548, ledid => 2, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 21282, ledid => 3, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 20088, ledid => 4, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 18960, ledid => 5, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 17896, ledid => 6, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 16892, ledid => 7, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 15944, ledid => 8, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 15049, ledid => 9, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 14204, ledid => 10, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT))), ((k => 18, N => 13407, ledid => 11, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 12655, ledid => 12, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 11945, ledid => 13, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 11274, ledid => 14, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 10641, ledid => 15, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 10044, ledid => 16, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 9480, ledid => 17, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 8948, ledid => 18, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 8446, ledid => 19, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 7972, ledid => 20, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 7525, ledid => 21, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT))), ((k => 18, N => 7102, ledid => 22, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 6704, ledid => 23, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 6328, ledid => 24, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 5973, ledid => 25, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 5637, ledid => 26, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 5321, ledid => 27, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 5022, ledid => 28, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 4740, ledid => 29, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 4474, ledid => 30, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 4223, ledid => 31, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 3986, ledid => 32, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT))), ((k => 18, N => 3763, ledid => 33, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 3551, ledid => 34, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 3352, ledid => 35, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 3164, ledid => 36, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 2987, ledid => 37, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 2819, ledid => 38, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 2661, ledid => 39, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 2511, ledid => 40, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 2370, ledid => 41, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 2237, ledid => 42, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 2112, ledid => 43, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT))), ((k => 18, N => 1993, ledid => 44, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 1882, ledid => 45, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 1776, ledid => 46, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 1676, ledid => 47, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 1582, ledid => 48, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 1494, ledid => 49, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 1410, ledid => 50, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 1331, ledid => 51, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 1256, ledid => 52, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 1185, ledid => 53, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 1119, ledid => 54, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT))), ((k => 18, N => 1056, ledid => 55, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 997, ledid => 56, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 941, ledid => 57, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 888, ledid => 58, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 838, ledid => 59, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 791, ledid => 60, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 747, ledid => 61, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 705, ledid => 62, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 666, ledid => 63, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 628, ledid => 64, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 593, ledid => 65, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT))), ((k => 18, N => 560, ledid => 66, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 528, ledid => 67, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 499, ledid => 68, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 471, ledid => 69, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 444, ledid => 70, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 419, ledid => 71, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 396, ledid => 72, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 374, ledid => 73, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 353, ledid => 74, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 333, ledid => 75, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 314, ledid => 76, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT))), ((k => 18, N => 297, ledid => 77, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 280, ledid => 78, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 264, ledid => 79, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 250, ledid => 80, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 236, ledid => 81, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 222, ledid => 82, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 210, ledid => 83, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 198, ledid => 84, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 187, ledid => 85, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 177, ledid => 86, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT)), (k => 18, N => 167, ledid => 87, threshold => to_sfixed(0.05, MULTIPLIER_LEFT, MULTIPLIER_RIGHT))));
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

signal madd_input : MultAddInputArray(N_BINS-1 downto 0);
signal madd_output : MultAddOutputArray(N_BINS-1 downto 0);

type MultAddInputArrayBins is array (natural range 0 to N_BINS-1) of MultAddInputArray(0 to BIN_SIZE - 1);
signal madd_mux_inputs : MultAddInputArrayBins;

signal mscheduler_readies : std_ulogic_vector(N_DETECTORS-1 downto 0);
signal mscheduler_start : std_ulogic := '0';
signal mscheduler_outs : std_ulogic_vector(N_DETECTORS-1 downto 0);
signal mscheduler_index : IndexArray(N_BINS - 1 downto 0);

signal goertzel_in_ready : std_ulogic_vector(N_DETECTORS-1 downto 0);
signal goertzel_out_data : FPArray(N_DETECTORS-1 downto 0);
signal goertzel_out_valid : std_ulogic_vector(N_DETECTORS-1 downto 0);
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

detector_bins: for bi in NOTE_DETECTORS'left to NOTE_DETECTORS'right generate begin

    multiply_scheduler : entity work.RoundRobinScheduler
    generic map ( N => BIN_SIZE)
    port map (
        clk => clk,
        start => mscheduler_start,
        readies => mscheduler_readies((bi+1)*BIN_SIZE-1 downto bi*BIN_SIZE),
        out_index => mscheduler_index(bi),
        outs => mscheduler_outs((bi+1)*BIN_SIZE-1 downto bi*BIN_SIZE)
    );
    
    
    
    multiply_add : entity work.sfixed_multiplier
    port map (
        clk => clk,
        ins => madd_input(bi),
        outs => madd_output(bi)
    );
    
    
    mscheduler_readies((bi+1)*BIN_SIZE-1 downto bi*BIN_SIZE) <= goertzel_in_ready((bi+1)*BIN_SIZE-1 downto bi*BIN_SIZE);
    madd_input(bi) <= madd_mux_inputs(bi)(mscheduler_index(bi));
 
    detectors : for i in 0 to BIN_SIZE-1 generate begin
        
        goertzel_instance : entity work.goertzel
            generic map(
                N => NOTE_DETECTORS(bi)(i).N,
                k => NOTE_DETECTORS(bi)(i).k
            )
            port map(
                clk => clk,
                in_data => goertzel_in_data,
                in_ready => goertzel_in_ready(bi*BIN_SIZE + i),
                in_valid => mscheduler_outs(bi*BIN_SIZE + i),
                
                out_data => goertzel_out_data(bi*BIN_SIZE + i),
                out_valid => goertzel_out_valid(bi*BIN_SIZE + i),
                
                multaddin => madd_mux_inputs(bi)(i),
                multaddout => madd_output(bi)
        );
        
        process(clk)
        begin
            if rising_edge(clk) and goertzel_out_valid(bi*BIN_SIZE + i) = '1' then
                leds(NOTE_DETECTORS(bi)(i).ledid) <= (r => (others => '1'), g => (others => '0'), b => (others => '0'), w => (others => '0')) when goertzel_out_data(bi*BIN_SIZE + i) > to_sfixed(0.005, MULTIPLIER_LEFT, MULTIPLIER_RIGHT) else
                                                     (r => (others => '0'), g => (others => '0'), b => (others => '1'), w => (others => '0')) when goertzel_out_data(bi*BIN_SIZE + i) <= to_sfixed(0.005, MULTIPLIER_LEFT, MULTIPLIER_RIGHT) else
                                                     (r => (others => '0'), g => (others => '1'), b => (others => '0'), w => (others => '0'));
            end if;
        end process;
        
    end generate;
end generate;

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
                if uart_state = WAIT_SEND and goertzel_out_valid(48) = '1' then
                    uart_str(3) <= to_slv(goertzel_out_data(48))(MULTIPLIER_WIDTH - 1 - 24 downto MULTIPLIER_WIDTH - 24 - 8);
                    uart_str(2) <= to_slv(goertzel_out_data(48))(MULTIPLIER_WIDTH - 1 - 16 downto MULTIPLIER_WIDTH - 16 - 8);
                    uart_str(1) <= to_slv(goertzel_out_data(48))(MULTIPLIER_WIDTH - 1 - 8  downto MULTIPLIER_WIDTH - 8  - 8);
                    uart_str(0) <= to_slv(goertzel_out_data(48))(MULTIPLIER_WIDTH - 1      downto MULTIPLIER_WIDTH      - 8);
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
--variable counter : natural range 0 to 10000000;
begin
    if rising_edge(clk) then
        led_send <= '1' when led_ready = '1' else '0';
        
--        if led_ready = '1' and counter = 10000000 then
--            leds <= leds(1 to N_LEDS - 1) & leds(0);
--            counter := 0;
--        else
--            if counter < 10000000 then
--                counter := counter + 1;
--            end if;
--        end if;
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
            mscheduler_start <= '1';
        else
            mscheduler_start <= '0';
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
led(1 to 2) <= mscheduler_outs(1 downto 0);
led(0) <= '1' when goertzel_out_data(48) > to_sfixed(2, MULTIPLIER_LEFT, MULTIPLIER_RIGHT) else '0';
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
