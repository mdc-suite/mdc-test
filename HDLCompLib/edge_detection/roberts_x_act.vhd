-- -------------------------------------------------------------------------------
-- This file has been automatically generated by the Caph compiler (version 2.8.4d)
-- from file main.cph, on 2018-05-11 at 16:31:33, by <unknown>
-- For more information, see : http://caph.univ-bpclermont.fr
-- -------------------------------------------------------------------------------

library ieee,caph,work;
use ieee.std_logic_1164.all;
use caph.core.all;
use caph.data_types.all;
use ieee.numeric_std.all;
use work.all;
use work.edgeDetectionOk_globals.all;

entity roberts_x is
   port (
    pel00_empty: in std_logic;
    pel00: in std_logic_vector(7 downto 0);
    pel00_rd: out std_logic;
    pel01_empty: in std_logic;
    pel01: in std_logic_vector(7 downto 0);
    pel01_rd: out std_logic;
    pel10_empty: in std_logic;
    pel10: in std_logic_vector(7 downto 0);
    pel10_rd: out std_logic;
    pel11_empty: in std_logic;
    pel11: in std_logic_vector(7 downto 0);
    pel11_rd: out std_logic;
    out_pel_full: in std_logic;
    out_pel: out std_logic_vector(13 downto 0);
    out_pel_wr: out std_logic;
    clock: in std_logic;
    reset: in std_logic
    );
end roberts_x;

architecture FSM of roberts_x is
begin
  comb: process(pel00, pel00_empty, pel01, pel01_empty, pel10, pel10_empty, pel11, pel11_empty, out_pel_full)
    variable p_p00 : unsigned(7 downto 0);
    variable p_p01 : unsigned(7 downto 0);
    variable p_p10 : unsigned(7 downto 0);
    variable p_p11 : unsigned(7 downto 0);
  begin
    -- pel11.rdy, pel10.rdy, pel01.rdy, pel00.rdy, out_pel.rdy / p_p11=pel11, p_p10=pel10, p_p01=pel01, p_p00=pel00, wr(out_pel,(p_p00 : signed<14>)-(p_p11 : signed<14>))
    if pel11_empty='0' and pel10_empty='0' and pel01_empty='0' and pel00_empty='0' and out_pel_full='0' then
      p_p11 := from_std_logic_vector(pel11,8);
      pel11_rd <= '1';
      p_p10 := from_std_logic_vector(pel10,8);
      pel10_rd <= '1';
      p_p01 := from_std_logic_vector(pel01,8);
      pel01_rd <= '1';
      p_p00 := from_std_logic_vector(pel00,8);
      pel00_rd <= '1';
      out_pel <= std_logic_vector((conv_signed(p_p00,14)) - (conv_signed(p_p11,14)));
      out_pel_wr <= '1';
    else
      pel00_rd <= '0';
      pel01_rd <= '0';
      pel10_rd <= '0';
      pel11_rd <= '0';
      out_pel_wr <= '0';
      out_pel <= (others => 'X');
    end if;
  end process;
  seq: process(clock, reset)
  begin
    if (reset='0') then
    elsif rising_edge(clock) then
    end if;
  end process;
end FSM;