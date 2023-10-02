SCENARIO=$1

TIMEOUT=`cat timeout`
PREFIX="road2-small"

KRUHOBOTS_LIST=`cat kruhobots_road2-small`

for KRUHOBOTS in $KRUHOBOTS_LIST;
do
    echo 'Solving '$PREFIX' scenario '$SCENARIO' MAPF-R instance with '$KRUHOBOTS' kruhobots ...'
    ## Verification of solutions is not timeouted and can take long ...
    timeout $(($TIMEOUT + 10)) ../../main/mapfR_solver_boOX '--timeout='$TIMEOUT '--input-mapR-file=map_'$PREFIX'.mapR' '--input-kruhoR-file='$PREFIX'-'$SCENARIO'_k'$KRUHOBOTS'.kruR' '--algorithm=smtcbsR*' '--output-file=solution.txt' >'out/out_'$PREFIX'_tout'$TIMEOUT'-'$SCENARIO'_k'$KRUHOBOTS'.txt' 2>'out/err_'$PREFIX'_tout'$TIMEOUT'-'$SCENARIO'_k'$KRUHOBOTS'.txt'
    (( $? == 124 )) && echo FAILED >>'out/out_'$PREFIX'_tout'$TIMEOUT'-'$SCENARIO'_k'$KRUHOBOTS'.txt'
    echo done >'out/out_'$PREFIX'_tout'$TIMEOUT'-'$SCENARIO'_k'$KRUHOBOTS'.aux'
done
