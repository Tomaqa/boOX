PREFIX="warehouse-10-20-10-2-1"

SCENARIOS_FILE="scenarios_"$PREFIX
ROBOTS_FILE="robots_"$PREFIX

ROBOTS_LIST=`cat $ROBOTS_FILE`
SCENARIOS_LIST=`cat $SCENARIOS_FILE`

for ROBOTS in $ROBOTS_LIST;
do
    for SCENARIO in $SCENARIOS_LIST;
    do
	echo 'Extracting '$PREFIX' scenario '$SCENARIO' MAPF instance with '$ROBOTS' agents ...'
	grep "machine TIME" 'out-105_'$PREFIX'-'$SCENARIO'_a'$ROBOTS'.txt'
    done
done
