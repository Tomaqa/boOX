NEIGHBOR=$1
PREFIX="empty-16-16-random"

KRUHOBOTS_LIST=`cat kruhobots_empty`
SCENARIOS_LIST=`cat scenarios_empty`

for SCENARIO in $SCENARIOS_LIST;
do
    for KRUHOBOTS in $KRUHOBOTS_LIST;
    do
	echo 'Extracting '$PREFIX' scenario '$SCENARIO' MAPF-R instance with '$KRUHOBOTS' kruhobots ...'
	grep "machine TIME" 'out_'$PREFIX'_n'$NEIGHBOR'-'$SCENARIO'_k'$KRUHOBOTS'.txt'
    done
done
