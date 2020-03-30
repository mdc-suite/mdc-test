-----------------------------------------------------------------------------------------
--                                                                                     --
--                This file is part of the CAPH Compiler distribution                  --
--                            http://caph.univ-bpclermont.fr                           --
--                                                                                     --
--                                  Jocelyn SEROT                                      --
--                         Jocelyn.Serot@univ-bpclermont.fr                            --
--                                                                                     --
--         Copyright 2011-2017 Jocelyn SEROT.  All rights reserved.                    --
--  This file is distributed under the terms of the GNU Library General Public License --
--      with the special exception on linking described in file ../LICENSE.            --
--                                                                                     --
-----------------------------------------------------------------------------------------

-- This is an optimized implementation of the [d1l] (one line delay) actor
-- for which line buffering is implemented using a local array.
-- On Altera FPGAs, the Quartus synthetizer infers RAM for the array.
-- Nov 2015, JS

library ieee;
use ieee.std_logic_1164.all;
use work.all;

entity d1l_opt is
   generic (
    linewidth: integer;
    bitwidth: integer
    );
  port (
    a_empty: in std_logic;
    a: in std_logic_vector(bitwidth+1 downto 0); -- +2 bits for tag
    a_rd: out std_logic;
    c_full: in std_logic;
    c: out std_logic_vector(bitwidth+1 downto 0); -- +2 bits for tag
    c_wr: out std_logic;
    clock: in std_logic;
    reset: in std_logic
    );
end d1l_opt;

architecture FSM of d1l_opt is

  constant mk_soS: std_logic_vector(bitwidth+1 downto 0) := "01" & (bitwidth-1 downto 0 => '0');
  constant mk_eoS: std_logic_vector(bitwidth+1 downto 0) := "10" & (bitwidth-1 downto 0 => '0');

  function is_soS(t: std_logic_vector) return boolean is
  begin
    return t(bitwidth+1 downto bitwidth) = "01";
  end;

  function is_eoS(t: std_logic_vector) return boolean is
  begin
    return t(bitwidth+1 downto bitwidth) = "10";
  end;

  function is_data(t: std_logic_vector) return boolean is
  begin
    return t(bitwidth+1 downto bitwidth) = "11";
  end;

  function mk_data(d: std_logic_vector(bitwidth-1 downto 0)) return std_logic_vector is
  begin
    return "11" & std_logic_vector(d);
  end;

  function get_data(t: std_logic_vector) return std_logic_vector is
  begin
    return t(bitwidth-1 downto 0);
  end;

    type t_enum1 is (S0,S1,S2,S3,S4);
    signal s : t_enum1;
    signal n_s : t_enum1;

	signal z_enw : std_logic;
	signal z_waddr:INTEGER RANGE 0 to linewidth;
	signal z_raddr:INTEGER RANGE 0 to linewidth;
	signal n_z_waddr:INTEGER RANGE 0 to linewidth+1;
	signal n_z_raddr:INTEGER RANGE 0 to linewidth+1;
	signal z_din: std_logic_vector (bitwidth-1 DOWNTO 0);
	signal z_dout: std_logic_vector (bitwidth-1 DOWNTO 0);

component single_clock_ram IS
  GENERIC (
    size: integer := 64;
    width: integer := 8
    );
  PORT (
	clock: IN STD_LOGIC;
	data: IN std_logic_vector (width-1 DOWNTO 0);
	write_address: IN INTEGER RANGE 0 to size-1 ;
	read_address: IN INTEGER RANGE 0 to size-1 ;
	we: IN STD_LOGIC;
	q: OUT std_logic_vector (width-1 DOWNTO 0)
	);
end component;

begin

  z : single_clock_ram
    generic map (linewidth,bitwidth)
    port map (clock, z_din, z_waddr, z_raddr, z_enw, z_dout );

  comb: process(a, a_empty, c_full, s, z_raddr, z_waddr, z_dout)
    variable p_p : std_logic_vector(bitwidth-1 downto 0);
  begin
    -- a.rdy, a=SoS, s=S0, c.rdy / rd(a), s:=S1, wr(c,SoS)
    if a_empty='0' and is_soS(a) and s=S0 and c_full='0' then
      a_rd <= '1';
      n_s <= S1;
      c <= mk_soS;
      c_wr <= '1';
      z_enw <= '0';
      n_z_waddr <= z_waddr;
      n_z_raddr <= z_raddr;
      z_din <= (others => 'X');
    -- a.rdy, a=EoS, s=S1, c.rdy / rd(a), s:=S0, wr(c,EoS)
    elsif a_empty='0' and is_eoS(a) and s=S1 and c_full='0' then
      a_rd <= '1';
      n_s <= S0;
      c <= mk_eoS;
      c_wr <= '1';
      z_enw <= '0';
      n_z_waddr <= z_waddr;
      n_z_raddr <= z_raddr;
      z_din <= (others => 'X');
    -- a.rdy, a=SoS, s=S1, c.rdy / rd(a), s:=S2, wr(c,SoS), i:=0
    elsif a_empty='0' and is_soS(a) and s=S1 and c_full='0' then
      a_rd <= '1';
      n_s <= S2;
      c <= mk_soS;
      c_wr <= '1';
      z_enw <= '0';
      n_z_waddr <= z_waddr;
      n_z_raddr <= z_raddr;
      z_din <= (others => 'X');
    -- a.rdy, a=EoS, s=S2, c.rdy / rd(a), s:=S3, wr(c,EoS)
    elsif a_empty='0' and is_eoS(a) and s=S2 and c_full='0' then
      a_rd <= '1';
      n_s <= S3;
      c <= mk_eoS;
      c_wr <= '1';
      z_enw <= '0';
      n_z_waddr <= z_waddr;
      n_z_raddr <= z_raddr;
      z_din <= (others => 'X');
    -- a.rdy, a=Data(p_p), s=S2, c.rdy / p_p=a.data, s:=S2, wr(c,Data(v)), z[i]:=p_p, i:=i + 1
    elsif a_empty='0' and is_data(a) and s=S2 and c_full='0' then
      p_p := get_data(a);
      a_rd <= '1';
      n_s <= S2;
      c <= mk_data((bitwidth-1 downto 0 => '0')); -- WARNING : padding value is always 0 HERE
      c_wr <= '1';
      z_enw <= '1';
      n_z_waddr <= z_waddr+1;
      n_z_raddr <= z_raddr;
      z_din <= p_p;
    -- a.rdy, a=EoS, s=S3, c.rdy / rd(a), s:=S0, wr(c,EoS)
    elsif a_empty='0' and is_eoS(a) and s=S3 and c_full='0' then
      a_rd <= '1';
      n_s <= S0;
      c <= mk_eoS;
      c_wr <= '1';
      z_enw <= '0';
      n_z_waddr <= z_waddr;
      n_z_raddr <= z_raddr;
      z_din <= (others => 'X');
    -- a.rdy, a=SoS, s=S3, c.rdy / rd(a), s:=S4, wr(c,SoS), i:=0
    elsif a_empty='0' and is_soS(a) and s=S3 and c_full='0' then
      a_rd <= '1';
      n_s <= S4;
      c <= mk_soS;
      c_wr <= '1';
      z_enw <= '0';
      n_z_raddr <= 1;
      n_z_waddr <= 0;
      z_din <= (others => 'X');
    -- a.rdy, a=Data(p_p), s=S4, c.rdy / p_p=a.data, s:=S4, wr(c,Data(z[i])), z[i]:=p_p, i:=i + 1
    elsif a_empty='0' and is_data(a) and s=S4 and c_full='0' then
      p_p := get_data(a);
      a_rd <= '1';
      n_s <= S4;
      c <= mk_data(z_dout);
      c_wr <= '1';
      z_enw <= '1';
      z_din <= std_logic_vector(p_p);
      n_z_waddr <= (z_waddr+1) mod linewidth;
      n_z_raddr <= (z_raddr+1) mod linewidth;
    -- a.rdy, a=EoS, s=S4, c.rdy / rd(a), s:=S3, wr(c,EoS)
    elsif a_empty='0' and is_eoS(a) and s=S4 and c_full='0' then
      a_rd <= '1';
      n_s <= S3;
      c <= mk_eoS;
      c_wr <= '1';
      z_enw <= '0';
      n_z_raddr <= 0;
      n_z_waddr <= 0;
      z_din <= (others => 'X');
    else
      a_rd <= '0';
      c_wr <= '0';
      c <= (others => 'X');
      n_s <= s;
      z_enw <= '0';
      n_z_waddr <= z_waddr;
      n_z_raddr <= z_raddr;
      z_din <= (others => 'X');
    end if;
  end process;
  seq: process(clock, reset)
  begin
    if (reset='0') then
      s <= S0;
      z_waddr <= 0;
      z_raddr <= 0;
    elsif rising_edge(clock) then
        s <= n_s;
        z_waddr <= n_z_waddr;
        z_raddr <= n_z_raddr;
    end if;
  end process;
end FSM;
