NEIGHBORHOOD=$1
SCENARIOS_LIST=`cat scenarios_empty`

for SCENARIO in $SCENARIOS_LIST;
do
    ./expr_empty-16-16_solve-lra.sh $NEIGHBORHOOD $SCENARIO &
done
