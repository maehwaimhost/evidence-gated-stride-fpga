create_clock -period 10.000 -name clk_a [get_ports clk_a]
create_clock -period 7.000 -name clk_b [get_ports clk_b]
set_clock_groups -asynchronous -group [get_clocks clk_a] -group [get_clocks clk_b]
set_false_path -from [get_ports reset_n]
