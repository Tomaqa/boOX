ROBOT_LIST=`cat robots_16`
SEED_LIST=`cat seeds_10`
SIZE=16

for ROBOTS in $ROBOT_LIST;
do
  for SEED in $SEED_LIST;	
  do            
    echo 'Solving path instance '$SIZE' with '$ROBOTS' agents ...'
    ./mapf_solver_boOX --algorithm=cbs++ --timeout=512 '--input-file=path_'$SIZE'_a'$ROBOTS'_'$SEED'.mpf' '--output-file=mapf-cbs_path_'$SIZE'_a'$ROBOTS'_'$SEED'.out' > 'mapf-cbs_path_'$SIZE'_a'$ROBOTS'_'$SEED'.txt'
  done
done
