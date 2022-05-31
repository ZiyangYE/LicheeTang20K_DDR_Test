//Copyright (C)2014-2022 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.05 
//Created Time: 2022-05-31 11:47:50
create_clock -name clk80 -period 12.346 -waveform {0 6.173} [get_nets {clk80}]
create_clock -name clk80_n -period 12.346 -waveform {0 6.173} [get_nets {clk80_n}]
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]
set_clock_groups -asynchronous -group [get_clocks {clk80}] -group [get_clocks {clk80_n}] -group [get_clocks {clk}]
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
