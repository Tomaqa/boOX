NEIGHBOR=$1
SCENARIO=$2

[[ -z $TIMEOUT ]] && TIMEOUT=`cat timeout`
PREFIX="empty-16-16-random"

KRUHOBOTS_LIST=`cat kruhobots_empty`

eval args=("$ARGS")

for KRUHOBOTS in $KRUHOBOTS_LIST; do
    echo "Solving LRA ${args[@]} $PREFIX scenario $SCENARIO MAPF-R instance with $KRUHOBOTS kruhobots ..."
    timeout -s INT $TIMEOUT "$LRA_ROOT/$LRA_BIN" "${args[@]}" -g map_${PREFIX}_n${NEIGHBOR}.mapR -l ${PREFIX}-${SCENARIO}_k${KRUHOBOTS}.kruR -o ${LRA_OUT_PREFIX}${ARGS_PREFIX}_${PREFIX}_tout${TIMEOUT}_n${NEIGHBOR}-${SCENARIO}_k${KRUHOBOTS}.txt 2>${LRA_ERR_PREFIX}${ARGS_PREFIX}_${PREFIX}_tout${TIMEOUT}_n${NEIGHBOR}-${SCENARIO}_k${KRUHOBOTS}.txt
    echo done >${LRA_OUT_PREFIX}${ARGS_PREFIX}_${PREFIX}_tout${TIMEOUT}_n${NEIGHBOR}-${SCENARIO}_k${KRUHOBOTS}.aux
    ## using 'timeout' with the $LRA_BIN and with a lot of processes is buggy - obfuscation ...
    sleep $(( 1 + $RANDOM % 3 )).$(( $RANDOM % 100 ))
done
