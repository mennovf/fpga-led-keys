----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.01.2023 22:22:25
-- Design Name: 
-- Module Name: sk6812 - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package LED is
    type Color is record
       r : std_ulogic_vector(7 downto 0);
       g : std_ulogic_vector(7 downto 0);
       b : std_ulogic_vector(7 downto 0);
       w : std_ulogic_vector(7 downto 0);
    end record;
    type led_array is array (integer range<>) of Color;
    constant RED   : Color := (r => (others => '1'), g => (others => '0'), b => (others => '0'), w => (others => '0'));
    constant GREEN : Color := (r => (others => '0'), g => (others => '1'), b => (others => '0'), w => (others => '0'));
    constant BLUE  : Color := (r => (others => '0'), g => (others => '0'), b => (others => '1'), w => (others => '0'));
end package;



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.LED.all;
use IEEE.NUMERIC_STD.ALL;

entity sk6812 is
generic (
    constant N : natural;
    constant clk_period : time
);
port(
    clk : in std_ulogic;
    leds : in led_array(0 to N - 1);
    send : in std_ulogic;
    ready : out std_ulogic;
    dout : out std_ulogic
);
end sk6812;

architecture Behavioral of sk6812 is
    constant T0H : natural := 300ns / clk_period - 1;
    constant T0L : natural := 900ns / clk_period;
    constant T1H : natural := 600ns / clk_period - 1;
    constant T1L : natural := 600ns / clk_period;
    constant T1E : natural := T1H + T1L;
    constant T0E : natural := T0H + T0L;
    constant Trst : natural := 80000ns / clk_period - 1;
    
    type StateType is (Idle, Transmitting, Resetting);
    signal state : StateType := Resetting;
    constant NBITS : positive := 32;
begin

send_leds: process(clk)
    variable led_counter : natural range 0 to N - 1 := 0;
    
    constant BIT_RESET : natural := NBITS - 1;
    constant BIT_LAST : natural := 0;
    
    variable bit_counter : natural range 0 to NBITS - 1 := BIT_RESET;
    variable time_counter : natural range 0 to Trst := 0;
    variable c : std_ulogic_vector(NBITS - 1 downto 0);
    
    variable TH : natural;
    variable TE : natural;
begin
    if rising_edge(clk) then
        -- State aliases
        c := leds(led_counter).g & leds(led_counter).r & leds(led_counter).b & leds(led_counter).w;
        
        if c(bit_counter) = '1' then
            TH := T1H;
            TE := T1E;
        else
            TH := T0H;
            TE := T0E;
        end if;
        
        
        -- FSM
        case state is
            when Resetting =>
                dout <= '0';
                if time_counter = Trst then
                    state <= Idle;
                else
                    time_counter := time_counter + 1;
                end if;
                
             when Transmitting =>
                dout <= '1' when time_counter <= TH else '0';
                if time_counter = TE then
                    -- Advance to the next bit
                    if bit_counter = BIT_LAST then
                        if led_counter = N - 1 then
                            led_counter := 0;
                            state <= Resetting;
                        else
                            led_counter := led_counter + 1;
                        end if;
                        
                        bit_counter := BIT_RESET;
                    else
                        bit_counter := bit_counter - 1;
                    end if;
                    
                    time_counter := 0;
                else
                    time_counter := time_counter + 1;
                end if;
                
             when Idle =>
                state <= Transmitting;
                led_counter := 0;
                bit_counter := BIT_RESET;
                time_counter := 0;
        end case;
    end if;
end process;


ready <= '1' when state = Idle else '0';

end Behavioral;
