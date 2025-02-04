PREFIX="road2-big"

KRUHOBOTS_LIST=`cat kruhobots_road2-big`
SCENARIOS_LIST=`cat scenarios_road2-big`

for KRUHOBOTS in $KRUHOBOTS_LIST;
do
    for SCENARIO in $SCENARIOS_LIST;
    do
	echo 'Extracting '$PREFIX' scenario '$SCENARIO' MAPF-R instance with '$KRUHOBOTS' kruhobots ...'
	grep "makespan =" 'out_'$PREFIX'-'$SCENARIO'_k'$KRUHOBOTS'.txt'
    done
done
