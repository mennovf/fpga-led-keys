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



-- FFT
-- Config slave channel signals
signal fft_s_axis_config_tvalid        : std_logic := '0';  -- payload is valid
signal fft_s_axis_config_tready        : std_logic := '0';  -- slave is ready
signal fft_s_axis_config_tdata         : std_logic_vector(7 downto 0) := (others => '0');  -- data payload

-- Data slave channel signals
signal fft_s_axis_data_tvalid          : std_logic := '0';  -- payload is valid
signal fft_s_axis_data_tready          : std_logic := '0';  -- slave is ready
signal fft_s_axis_data_tdata           : std_logic_vector(47 downto 0) := (others => '0');  -- data payload
signal fft_s_axis_data_tlast           : std_logic := '0';  -- indicates end of packet

-- Data master channel signals
signal fft_m_axis_data_tvalid          : std_logic := '0';  -- payload is valid
signal fft_m_axis_data_tdata           : std_logic_vector(63 downto 0) := (others => '0');  -- data payload
signal fft_m_axis_data_tlast           : std_logic := '0';  -- indicates end of packet

-- Event signals
signal fft_event_frame_started         : std_logic := '0';
signal fft_event_tlast_unexpected      : std_logic := '0';
signal fft_event_tlast_missing         : std_logic := '0';
signal fft_event_data_in_channel_halt  : std_logic := '0';

constant FFT_WIDTH    : integer := 18;
constant FFT_MAX_SAMPLES : integer := 2**11;  -- maximum number of samples in a frame
constant START_FREQUENCY_INDEX : natural := 5;

subtype Magnitude is signed(FFT_WIDTH*2 downto 0);
type FFTMagnitudes is array (0 to FFT_MAX_SAMPLES) of Magnitude;
signal fft_mag_output : Magnitude;
signal fft_mag_outputted : std_ulogic := '0';

    
    
-- LED Strip
constant N_LEDS : integer := 144;
signal leds : led_array(0 to N_LEDS - 1) := ((r => (others => '1'), g => (others => '0'), b => (others => '0'), w => (others => '0')), (r => (others => '0'), g => (others => '1'), b => (others => '0'), w => (others => '0')), (r => (others => '0'), g => (others => '0'), b => (others => '1'), w => (others => '0')), 
others=>(others=>(others=>'0')));
signal led_ready : std_logic;
signal led_send : std_logic;



-- DEBUG
signal fft_feed_counter : natural := 0;
signal fft_unload_counter: natural;
signal fft_max_index : integer;
signal fft_max_value : Magnitude;
-- Config slave channel alias signals
signal s_axis_config_tdata_fwd_inv      : std_logic                    := '0';              -- forward or inverse

-- Data slave channel alias signals
signal s_axis_data_tdata_re             : std_logic_vector(17 downto 0) := (others => '0');  -- real data
signal s_axis_data_tdata_im             : std_logic_vector(17 downto 0) := (others => '0');  -- imaginary data

-- Data master channel alias signals
signal m_axis_data_tdata_re             : std_logic_vector(28 downto 0) := (others => '0');  -- real data
signal m_axis_data_tdata_im             : std_logic_vector(28 downto 0) := (others => '0');  -- imaginary data



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

fft : entity work.fft port map (
    aclk => clk,
    
    s_axis_config_tdata => fft_s_axis_config_tdata,
    s_axis_config_tvalid => fft_s_axis_config_tvalid,
    s_axis_config_tready => fft_s_axis_config_tready,
    
    s_axis_data_tdata => fft_s_axis_data_tdata,
    s_axis_data_tvalid => fft_s_axis_data_tvalid,
    s_axis_data_tready => fft_s_axis_data_tready,
    s_axis_data_tlast => fft_s_axis_data_tlast,
    
    m_axis_data_tdata => fft_m_axis_data_tdata,
    m_axis_data_tvalid => fft_m_axis_data_tvalid,
    m_axis_data_tlast => fft_m_axis_data_tlast,
    
    event_frame_started => fft_event_frame_started,
    event_tlast_unexpected => fft_event_tlast_unexpected,
    event_tlast_missing => fft_event_tlast_missing,
    event_data_in_channel_halt => fft_event_data_in_channel_halt
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
------               FFT Processes                 -------
----------------------------------------------------------

fft_feed: process(clk)
variable counter : natural range 0 to FFT_MAX_SAMPLES-1 := 0;
variable sample : std_logic_vector(17 downto 0) := (others=>'1');
variable rec : std_logic_vector(fft_s_axis_data_tdata'range);

begin
    if rising_edge(clk) then
        if fft_s_axis_data_tready = '1' then
            sample := std_logic_vector(i2s_sample_out(17 downto 0));
            --sample := "000000000111110100" when sample /= "000000000111110100" else "111111111000001100";
            rec(FFT_WIDTH-1 downto 0) := sample;
            rec(23 downto FFT_WIDTH) := (others => sample(17));
            rec(rec'high downto (rec'high+1)/2) := (others => '0');
            
            fft_s_axis_data_tdata <= rec;
            fft_s_axis_data_tvalid <= '1';
            
            if counter = FFT_MAX_SAMPLES-1 then
                fft_s_axis_data_tlast <= '1';
                counter := 0;
            else                   
                counter := counter + 1;
                fft_s_axis_data_tlast <= '0';
            end if;
        end if;
    end if;
    fft_feed_counter <= counter;
end process;                                                                                            

fft_unload: process (clk)
    variable index : natural range 0 to FFT_MAX_SAMPLES-1 := 0;
    variable sample_re : signed(FFT_WIDTH-1 downto 0);
    variable sample_im : signed(FFT_WIDTH-1 downto 0);
begin
    if rising_edge(clk) then
        if fft_m_axis_data_tvalid = '1' then
            sample_re(17 downto 0) := signed(fft_m_axis_data_tdata(28 downto 11));
            sample_re(sample_re'high downto 18) := (others => sample_re(17));
            sample_im(17 downto 0) := signed(fft_m_axis_data_tdata(60 downto 43));
            sample_im(sample_im'high downto 18) := (others => sample_im(17));
            

            fft_mag_output <= resize(sample_re*sample_re, Magnitude'high + 1) + resize(sample_im*sample_im,  Magnitude'high + 1);
            fft_mag_outputted <= '1';


            if index = FFT_MAX_SAMPLES-1 then
                index := 0;
            else
                index := index + 1;
            end if;            
        else
            fft_mag_outputted <= '0';
        end if;
        fft_unload_counter <= index;
    end if;
end process;


freq_max: process(clk)

variable max_freq_index : natural range 0 to FFT_MAX_SAMPLES-1 := 0;
variable max_freq_magnitude : Magnitude := (others=>'0');
variable max_freq_index_bits : std_logic_vector(15 downto 0);
variable d : std_ulogic := '0';
begin
    if rising_edge(clk) then
        if fft_unload_counter = 1025 then
            d := '1';
        end if;
        if fft_mag_outputted = '1' and fft_unload_counter > START_FREQUENCY_INDEX and fft_unload_counter <= FFT_MAX_SAMPLES / 2 + 1 then
            if fft_mag_output > max_freq_magnitude then
                max_freq_magnitude := fft_mag_output;
                max_freq_index := fft_unload_counter;
            end if;
        end if;
        
        
        if fft_unload_counter = 0 then            
            -- Send the max index over uart
            if uart_state = WAIT_SEND then
                max_freq_index_bits := std_logic_vector(to_unsigned(max_freq_index, 16));
                uart_str(0) <= max_freq_index_bits(15 downto 8);
                uart_str(1) <= max_freq_index_bits(7 downto 0);
                strEnd <= 2;
                uart_str_send <= '1';
            end if;
            
            max_freq_index := START_FREQUENCY_INDEX;
            max_freq_magnitude := (others=>'0');
        end if;
        
        if uart_state /= WAIT_SEND then
            uart_str_send <= '0';
        end if;
        
    
        fft_max_index <= max_freq_index;
        fft_max_value <= max_freq_magnitude;
    end if;
end process;



-- Config slave channel alias signals
  s_axis_config_tdata_fwd_inv    <= fft_s_axis_config_tdata(0);

  -- Data slave channel alias signals
  s_axis_data_tdata_re           <= fft_s_axis_data_tdata(17 downto 0);
  s_axis_data_tdata_im           <= fft_s_axis_data_tdata(41 downto 24);

  -- Data master channel alias signals
  m_axis_data_tdata_re           <= fft_m_axis_data_tdata(28 downto 0);
  m_axis_data_tdata_im           <= fft_m_axis_data_tdata(60 downto 32);


----------------------------------------------------------
------            Microphone Logging               -------
----------------------------------------------------------

process (clk)
begin
    if rising_edge(clk) then
        if i2s_data_ready = '1' and i2s_data_channel = '0' then
            audio_sample <= std_logic_vector(i2s_sample_out(31 downto 14));
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
led(0 to 15) <= audio_sample(17 downto 2);

end Behavioral;
