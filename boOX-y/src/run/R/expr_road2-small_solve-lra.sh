SCENARIO=$1

TIMEOUT=`cat timeout`
PREFIX="road2-small"

KRUHOBOTS_LIST=`cat kruhobots_road2-small`

eval args=("$ARGS")

for KRUHOBOTS in $KRUHOBOTS_LIST; do
    echo "Solving LRA ${args[@]} $PREFIX scenario $SCENARIO MAPF-R instance with $KRUHOBOTS kruhobots ..."
    timeout -s INT $TIMEOUT "$LRA_ROOT/$LRA_BIN" "${args[@]}" -g map_${PREFIX}.mapR -l ${PREFIX}-${SCENARIO}_k${KRUHOBOTS}.kruR -o ${LRA_OUT_PREFIX}${ARGS_PREFIX}_${PREFIX}_tout${TIMEOUT}-${SCENARIO}_k${KRUHOBOTS}.txt 2>${LRA_ERR_PREFIX}${ARGS_PREFIX}_${PREFIX}_tout${TIMEOUT}-${SCENARIO}_k${KRUHOBOTS}.txt
    echo done >${LRA_OUT_PREFIX}${ARGS_PREFIX}_${PREFIX}_tout${TIMEOUT}-${SCENARIO}_k${KRUHOBOTS}.aux
    ## using 'timeout' with the $LRA_BIN and with a lot of processes is buggy - obfuscation ...
    sleep $(( 1 + $RANDOM % 3 )).$(( $RANDOM % 100 ))
done
