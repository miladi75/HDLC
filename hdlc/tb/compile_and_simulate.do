# compile_and_simulate.do will compile and simulate and authomatically run in QuestaSim to see the 

# `vsim -view vsim.wlf &` Opens QuestaSim from X11 server
#   If the simulation is rerun, type dataset restart -f in transcript window in
# Questasim to update it.

# Remove existing work library and transcript file
exec rm -rf work*
exec rm -rf transcript

# Create a work library
vlib work

# Compile design files
puts "Compiling design files..."
if {[catch {vlog -sv ../rtl/*.sv} errmsg]} {
    puts "Error: $errmsg"
    quit -code 1
} else {
    puts "Success"
}

# Compile test files
puts "Compiling test files..."
if {[catch {vlog -sv ./*.sv} errmsg]} {
    puts "Error: $errmsg"
    quit -code 1
} else {
    puts "Success"
}

# Simulate the design
puts "Simulating..."
set gui_mode [regexp -- "--gui" $argv]
if {$gui_mode} {
    puts "vsim -assertdebug -voptargs=\"+acc\" test_hdlc bind_hdlc -do \"log -r *\""
} else {
    if {[catch {vsim -assertdebug -c -coverage -voptargs="+acc" test_hdlc bind_hdlc -do "log -r *; run -all; coverage report -cvg -details -file coverage_rep.txt; exit"} errmsg]} {
        puts "Error: $errmsg"
        quit -code 1
    } else {
        puts "Success"
    }
}
