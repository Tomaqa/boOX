PREFIX="road2-medium"

KRUHOBOTS_LIST=`cat kruhobots_road2-medium`
SCENARIOS_LIST=`cat scenarios_road2-medium`

for KRUHOBOTS in $KRUHOBOTS_LIST;
do
    for SCENARIO in $SCENARIOS_LIST;
    do
	echo 'Generating '$PREFIX' scenario '$SCENARIO' MAPF-R instance with '$KRUHOBOTS' kruhobots ...'
	../../main/kruhoR_generate_boOX '--kruho-radius=0.3535533905933' '--input-xml-map-file=map_'$PREFIX'.xml' '--input-xml-agent-file='$PREFIX'-'$SCENARIO'.xml' '--output-kruhoR-file='$PREFIX'-'$SCENARIO'_k'$KRUHOBOTS'.kruR' '--N-kruhobots='$KRUHOBOTS
    done
done
