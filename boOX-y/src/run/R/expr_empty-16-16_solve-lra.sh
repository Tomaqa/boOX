NEIGHBOR=$1
SCENARIO=$2

TIMEOUT=`cat timeout`
PREFIX="empty-16-16-random"

KRUHOBOTS_LIST=`cat kruhobots_empty`

for KRUHOBOTS in $KRUHOBOTS_LIST; do
    echo "Solving LRA $PREFIX scenario $SCENARIO MAPF-R instance with $KRUHOBOTS kruhobots ..."
    timeout -s INT $TIMEOUT "$LRA_ROOT/$LRA_BIN" -g map_${PREFIX}_n${NEIGHBOR}.mapR -l ${PREFIX}-${SCENARIO}_k${KRUHOBOTS}.kruR -o ${LRA_OUT_PREFIX}_${PREFIX}_tout${TIMEOUT}_n${NEIGHBOR}-${SCENARIO}_k${KRUHOBOTS}.txt 2>${LRA_ERR_PREFIX}_${PREFIX}_tout${TIMEOUT}_n${NEIGHBOR}-${SCENARIO}_k${KRUHOBOTS}.txt
    echo done >${LRA_OUT_PREFIX}_${PREFIX}_tout${TIMEOUT}_n${NEIGHBOR}-${SCENARIO}_k${KRUHOBOTS}.aux
done
