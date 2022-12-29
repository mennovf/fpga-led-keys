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
           i2s_lrcl     : out std_logic);
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


--- Asciifier
signal ascii_input : integer;
signal ascii_converting : std_logic;
signal ascii_convert : std_logic := '0';
signal ascii_result : CHAR_ARRAY(0 to 10);
signal ascii_len : natural := 0;


-- I2S
signal i2s_data_ready : STD_LOGIC  := '0';
signal i2s_sample_out : signed (31 downto 0);
signal i2s_data_channel : std_ulogic;
signal audio_sample : std_logic_vector (17 downto 0) := "010101010101010101";



-- FFT
signal fft_s_axis_config_tdata : std_logic_vector ( 7 downto 0 );
signal fft_s_axis_config_tvalid : std_logic;
signal fft_s_axis_config_tready : std_logic;
signal fft_s_axis_data_tdata : std_logic_vector ( 47 downto 0 );
signal fft_s_axis_data_tvalid : std_logic;
signal fft_s_axis_data_tready : std_logic;
signal fft_s_axis_data_tlast : std_logic;
signal fft_m_axis_data_tdata : std_logic_vector ( 63 downto 0 );
signal fft_m_axis_data_tvalid : std_logic;
signal fft_m_axis_data_tlast : std_logic;
signal fft_event_frame_started : std_logic;
signal fft_event_tlast_unexpected : std_logic;
signal fft_event_tlast_missing : std_logic;
signal fft_event_data_in_channel_halt : std_logic;



-----------------------------------------------------------
-----------------------------------------------------------
-----------------------------------------------------------
begin

asciifier: entity work.AsciiConverter port map (
    input => ascii_input,
    converting => ascii_converting,
    convert => ascii_convert,
    clk => clk,
    result => ascii_result,
    length => ascii_len
);

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
                if uart_state = WAIT_SEND then
                    uart_str(0) <= audio_sample(17 downto 10);
                    uart_str(1) <= audio_sample(9 downto 2);
                    strEnd <= 2;
                    uart_str_send <= '1';
                    wait_state := SoTX;
                end if;
        end case;
    end if;    
end process;

----------------------------------------------------------
------              Ascii Control                  -------
----------------------------------------------------------

-- process (clk) 
-- variable counter : integer := 0; 
-- type WaitState is (SoC, EoC, SoTX, EoTX); 
-- variable wait_state : WaitState := EoTX; 
-- begin 
--     if rising_edge(clk) then        
--         case wait_state is 
--             when SoC => 
--                 if ascii_converting = '1' then 
--                     ascii_convert <= '0'; 
--                     wait_state := EoC; 
--                 end if; 
--             when EoC => 
--                 if ascii_converting = '0' then 
--                     wait_state := SoTX; 
--                     uart_str(0 to ascii_result'high) <= ascii_result; 
--              
--                     for i in uart_str'range loop 
--                         if i = ascii_len then 
--                             uart_str(i) <= X"0A"; 
--                         end if; 
--                         if i = ascii_len + 1 then 
--                             uart_str(i) <= X"0D"; 
--                         end if; 
--                     end loop; 
--                     strEnd <= ascii_len + 2; 
--                     uart_str_send <= '1'; 
--                 end if; 
--             when SoTX => 
-- 		        if uart_state /= WAIT_SEND then 
--                     wait_state := EoTX;                     
--                     uart_str_send <= '0'; 
--                 end if; 
--             when EoTX => 
--                 if uart_state = WAIT_SEND then 
--                     ascii_input <= counter; 
--                     ascii_convert <= '1'; 
--                     counter := counter + 1; 
--                     if counter > 100 then 
--                         counter := -100; 
--                     end if; 
--                     wait_state := SoC; 
--                 end if; 
--         end case; 
--     end if;     
-- end process; 


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
        when others=> --should never be reached
            uart_state <= WAIT_SEND;
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
