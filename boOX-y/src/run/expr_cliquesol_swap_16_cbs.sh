ROBOT_LIST=`cat robots_16`
SEED_LIST=`cat seeds_10`
SIZE=16

for ROBOTS in $ROBOT_LIST;
do
  for SEED in $SEED_LIST;	
  do            
    echo 'Solving clique instance '$SIZE' with '$ROBOTS' agents ...'
    ../main/swap_solver_boOX --algorithm=cbs++ --timeout=128 '--input-file=clique_'$SIZE'_a'$ROBOTS'_'$SEED'.mpf' '--output-file=swap-cbs_clique_'$SIZE'_a'$ROBOTS'_'$SEED'.out' > 'swap-cbs_clique_'$SIZE'_a'$ROBOTS'_'$SEED'.txt'
  done
done
