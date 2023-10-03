NEIGHBOR=$1
SCENARIO=$2

[[ -z $TIMEOUT ]] && TIMEOUT=`cat timeout`
PREFIX="empty-16-16-random"

KRUHOBOTS_LIST=`cat kruhobots_empty`

for KRUHOBOTS in $KRUHOBOTS_LIST;
do
    echo 'Solving '$PREFIX' scenario '$SCENARIO' MAPF-R instance with '$KRUHOBOTS' kruhobots ...'
    ## Verification of solutions is not timeouted and can take long ...
    timeout $(($TIMEOUT + 10)) ../../main/mapfR_solver_boOX '--timeout='$TIMEOUT '--input-mapR-file=map_'$PREFIX'_n'$NEIGHBOR'.mapR' '--input-kruhoR-file='$PREFIX'-'$SCENARIO'_k'$KRUHOBOTS'.kruR' '--algorithm=smtcbsR*' '--output-file=solution_n'$NEIGHBOR'-'$SCENARIO'.txt' >'out/out_'$PREFIX'_tout'$TIMEOUT'_n'$NEIGHBOR'-'$SCENARIO'_k'$KRUHOBOTS'.txt' 2>'out/err_'$PREFIX'_tout'$TIMEOUT'_n'$NEIGHBOR'-'$SCENARIO'_k'$KRUHOBOTS'.txt'
    (( $? == 124 )) && echo FAILED >>'out/out_'$PREFIX'_tout'$TIMEOUT'_n'$NEIGHBOR'-'$SCENARIO'_k'$KRUHOBOTS'.txt'
    echo done >'out/out_'$PREFIX'_tout'$TIMEOUT'_n'$NEIGHBOR'-'$SCENARIO'_k'$KRUHOBOTS'.aux'
done
