SCENARIO=$1

TIMEOUT=`cat timeout`
PREFIX="road2-small"

KRUHOBOTS_LIST=`cat kruhobots_road2-small`

SCENARIO_FILE=`mktemp`
CONFIG_FILE=`mktemp`

for KRUHOBOTS in $KRUHOBOTS_LIST; do
    echo 'Solving CCBS '$PREFIX' scenario '$SCENARIO' MAPF-R instance with '$KRUHOBOTS' kruhobots ...'

    awk 'BEGIN{i=0} !/<agent/{print;} /<agent/{ if (++i <= '$KRUHOBOTS') print; }' <$PREFIX'-'$SCENARIO'.xml' >$SCENARIO_FILE
    sed "s/\(<timelimit>\)[^<]*</\1${TIMEOUT}</" <"$CCBS_ROOT"/Examples/config.xml >$CONFIG_FILE
    "$CCBS_ROOT/$CCBS_BIN" 'map_'$PREFIX'.xml' $SCENARIO_FILE $CONFIG_FILE >${CCBS_OUT_PREFIX}_${PREFIX}_tout${TIMEOUT}-${SCENARIO}_k${KRUHOBOTS}.txt 2>${CCBS_ERR_PREFIX}_${PREFIX}_tout${TIMEOUT}-${SCENARIO}_k${KRUHOBOTS}.txt
    echo done >${CCBS_OUT_PREFIX}_${PREFIX}_tout${TIMEOUT}-${SCENARIO}_k${KRUHOBOTS}.aux
done

rm -f $SCENARIO_FILE
rm -f $CONFIG_FILE
