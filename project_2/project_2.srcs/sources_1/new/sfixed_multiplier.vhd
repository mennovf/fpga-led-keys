----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.03.2023 15:49:31
-- Design Name: 
-- Module Name: sfixed_multiplier - Behavioral
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

library fixed;
use fixed.fixed_pkg.all;
use fixed.fixed_float_types.all;

entity sfixed_multiplier is
generic (
    constant B : positive;
    constant F : positive
);

Port (
    signal clk : in std_ulogic;
    signal in_A : in sfixed(B-1 downto -F);
    signal in_B : in sfixed(B-1 downto -F);
    signal in_C : in sfixed(B-1 downto -F);
    signal in_valid : in std_ulogic;
    signal in_ready : out std_ulogic := '1';
    
    signal out_data : out sfixed(B-1 downto -F);
    signal out_valid : out std_ulogic := '0'
);

end sfixed_multiplier;



architecture Behavioral of sfixed_multiplier is

constant AHIGH : positive := in_A'high - in_A'low;
constant BHIGH : positive := in_B'high - in_B'low;
constant CHIGH : positive := in_C'high - in_C'low;

constant WIDTH : positive := 18;
constant HIGH : positive := WIDTH - 1;
constant RHIGH : positive := 2*WIDTH + 1 - 1;
signal eA : std_ulogic_vector(HIGH downto 0);
signal eB : std_ulogic_vector(HIGH downto 0);
signal eC : std_ulogic_vector(CHIGH + F downto 0);


signal eP : std_ulogic_vector(RHIGH downto 0);
signal enable : std_ulogic := '0';

signal ulv_A : std_ulogic_vector(AHIGH downto 0);
signal ulv_B : std_ulogic_vector(BHIGH downto 0);
signal ulv_C : std_ulogic_vector(CHIGH downto 0);

begin


assert B + F <= WIDTH
    report "The width of the fixed point number should fit into the width of the FMA."
    severity FAILURE;

out_data <= to_sfixed(eP(out_data'high - out_data'low + F downto F), out_data'high, out_data'low);

ulv_A <= to_sulv(in_A);
eA <= (AHIGH downto 0 => ulv_A, others => in_A(in_A'high));

ulv_B <= to_sulv(in_B);
eB <= (BHIGH downto 0 => ulv_B, others => in_B(in_B'high));

ulv_C <= to_sulv(in_C);
eC <= (CHIGH + F downto F => ulv_C, others => '0');


multiplier : entity work.multadd
  port map (
    CLK => clk,
    CE => enable,
    SCLR => '0',
    --A => (others => '0'),
    --B => (others => '0'),
    --C => (others => '0'),
    A => eA,
    B => eB,
    C => (CHIGH + F downto 0 => eC, others => in_C(in_C'high)),
    SUBTRACT => '0',
    P => eP
);

controller : process(clk)
constant LATENCY : positive := 4;
variable counter : natural range 0 to LATENCY := 0;

begin

    in_ready <= '1' when counter = 0 else '0';

    if rising_edge(clk) then
        out_valid <= '0';
        if counter = 0 and in_valid = '1' then
            enable <= '1';
            counter := 1;
        end if;
        
        if counter = LATENCY then
            counter := 0;
            out_valid <= '1';
        else
            counter := counter + 1;
        end if;
    end if;
end process;

end Behavioral;
