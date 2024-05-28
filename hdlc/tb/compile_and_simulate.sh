#!/bin/bash


# Set path to header file directory
HEADER_PATH="/home/courses/desdigsys2/2023s/dds223s05/dds2/term_project/hdlc/tb"

# Remove existing work library and transcript file
rm -rf work*
rm -rf transcript

RED='\033[0;31m'
NC='\033[0m'    

# Create a work library
vlib work 

# Compile design files
printf "${RED}\nCompiling design${NC}\n"
# if vlog -sv -y $HEADER_PATH +incdir+$HEADER_PATH ../rtl/*.sv 
if vlog -sv ../rtl/*.sv 
then
    vlog -sv -y $HEADER_PATH +incdir+$HEADER_PATH ../rtl/*.sv 
    echo "Success"
else
    echo "Failure"
    exit 1
fi


# Simulate the design
printf "${RED}\nSimulating${NC}\n"
if [[ "$@" =~ --gui ]]
then
    #echo vsim -assertdebug -voptargs="+acc" test_hdlc bind_hdlc -do "log -r *" &
    #vsim -c coverage testPr_hdlc -do "log -r *" 
    vsim  -voptargs="+acc" test_hdlc bind_hdlc -do "log -r *"
else
    if vsim -assertdebug -c -coverage -voptargs="+acc" test_hdlc bind_hdlc -do "log -r *; run -all; coverage report -cvg -details -file coverage_rep.txt; exit"
    then
        echo "Success"
    else
        echo "Failure"
        exit 1
    fi
fi
