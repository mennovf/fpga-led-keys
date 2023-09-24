----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.03.2023 21:59:47
-- Design Name: 
-- Module Name: goertzel - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- IIRAdd1al Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use IEEE.MATH_REAL.ALL;

library fixed;
use fixed.fixed_pkg.all;
use fixed.fixed_float_types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.SFixedMultiplierInterface.all;

entity goertzel is
generic (
    constant N : positive;
    constant k : natural
);

Port (
    signal clk : in std_ulogic;
    signal in_data : in FP;
    signal in_valid : in std_ulogic;
    signal in_ready : out std_ulogic := '1';
    
    signal out_data : out FP;
    signal out_data_scaled : out FP;
    signal out_valid : out std_ulogic := '0';
    
    signal multaddin  : out MultAddInput := (valid => '0', others => (others=>'0'));
    signal multaddout : in MultAddOutput
    
);

end goertzel;

architecture Behavioral of goertzel is
    constant left : integer := MULTIPLIER_LEFT;
    constant right : integer := MULTIPLIER_RIGHT;
    
    constant Ninverse : FP := to_sfixed(1.0 / real(N), left, right);
    constant omega : real := 2 * MATH_PI * k / N;
    constant double_cos_omega : real := 2*cos(omega);
    constant double_cos_omega_fp : FP := to_sfixed(double_cos_omega, left, right);
    constant neg_double_cos_omega_fp : FP := to_sfixed(-double_cos_omega, left, right);
    constant ONE  : FP := to_sfixed(1.0,  left, right);
    constant MONE : FP := to_sfixed(-1.0, left, right);
    constant ZERO : FP := to_sfixed(0, left, right);
    --constant OCTAVE_SCALE : FP := to_sfixed(13.75, left, right); --Replaced by /16 (shift 4 bits)


    -- Multiply Add
    signal ma_in_A : FP;
    signal ma_in_B : FP;
    signal ma_in_C : FP;
    signal ma_in_valid : std_ulogic := '1';
    signal ma_in_ready : std_ulogic;
    
    signal ma_out_data : FP;
    signal ma_out_valid : std_ulogic;
begin


multaddin.a <= ma_in_a;
multaddin.b <= ma_in_b;
multaddin.c <= ma_in_c;
multaddin.valid <= ma_in_valid;
ma_in_ready <= multaddout.ready;

ma_out_data <= multaddout.result;
ma_out_valid <= multaddout.valid;

iterations: process(clk)
    variable i : natural range 0 to N := 0;
    
    variable s2 : FP := (others => '0');
    variable s1 : FP := (others => '0');
    
    variable acc : FP;

    type StageProgress is (Present, Calculating, Control);
    type PipelineStage is (Waiting, IIRAdd1, IIRAdd2, EndIter, PCS1, PCS2, PS1, PS2, EndSample);
    variable state : PipelineStage := Waiting;
    variable progress : StageProgress := Control;
    
begin

    if rising_edge(clk) then
                         
        case progress is
            when Present =>
                ma_in_valid <= '1';
                if ma_in_ready = '1' then
                    progress := Calculating;
                end if;
            
            when Calculating =>
                ma_in_valid <= '0';
                if ma_out_valid = '1' then
                    acc := ma_out_data;
                    progress := Control;
                end if;
            when Control  =>
                case state is
                
                    when Waiting =>
                        out_valid <= '0';
                        if in_valid = '1' then
                            ma_in_a <= in_data;
                            ma_in_b <= Ninverse;
                            ma_in_c <= ZERO;
                            in_ready <= '0';
                            
                            state := IIRAdd1;
                            progress := Present;
                        end if;
                
                    when IIRAdd1 =>
                        ma_in_a <= double_cos_omega_fp;
                        ma_in_b <= s1;
                        ma_in_c <= acc;
                        
                        state := IIRAdd2;
                        progress := Present;
                        
                    when IIRAdd2 =>
                        ma_in_a <= MONE;
                        ma_in_b <= s2;
                        ma_in_c <= acc;
                        
                        state := EndIter;
                        progress := Present;
                        
                    when EndIter =>
                        i := i + 1;
                        
                        s2 := s1;
                        s1 := acc;
                        
                        if i = N then
                            i := 0;
                            state := PCS1;
                        else
                            state := Waiting;
                            in_ready <= '1';
                        end if;
                    
                        
                    when PCS1 =>
                        ma_in_a <= neg_double_cos_omega_fp;
                        ma_in_b <= s1;
                        ma_in_c <= ZERO;
                        state := PCS2;
                        progress := Present;
                        
                    when PCS2 =>
                        ma_in_a <= acc;
                        ma_in_b <= s2;
                        ma_in_c <= ZERO;
                        state := PS1;
                        progress := Present;
                    
                    when PS1 =>
                        ma_in_a <= s1;
                        ma_in_b <= s1;
                        ma_in_c <= acc;
                        state := PS2;
                        progress := Present;
                        
                    when PS2 =>
                        ma_in_a <= s2;
                        ma_in_b <= s2;
                        ma_in_c <= acc;
                        state := EndSample;
                        progress := Present;
                        
                    when EndSample =>
                        out_data <= acc;
                        out_data_scaled <= out_data_scaled srl 4;
                        out_valid <= '1';
                        in_ready <= '1';
                        s2 := (others => '0');
                        s1 := (others => '0');
                        state := Waiting;
                end case;
        end case;
    end if;
end process;


end Behavioral;
