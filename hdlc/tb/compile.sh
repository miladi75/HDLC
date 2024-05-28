rm -rf work*

RED='\033[0;31m'
NC='\033[0m'    

vlib work 

printf "${RED}\nCompiling design${NC}\n"


if vlog -sv ../rtl/*.sv 
then
	echo "Success"
else
	echo "Failure"
	exit 1
fi

printf "${RED}\nCompiling test files${NC}\n"
if vlog -sv ./*.sv 
then
	echo "Success"
else
	echo "Failure"
	exit 1
fi

