ROBOT_LIST=`cat robots_maps`
SEED_LIST=`cat seeds_10`
SIZE=16
TIMEOUT=`cat timeout`

for ROBOTS in $ROBOT_LIST;
do
  for SEED in $SEED_LIST;	
  do            
    echo 'Solving den520d instance with '$ROBOTS' agents ...'
    ../main/insolver_reLOC '--total-timeout='$TIMEOUT '--minisat-timeout='$TIMEOUT --encoding=rmdd '--input-file=den520d_a'$ROBOTS'_'$SEED'.cpf' '--output-file=perm-mdd++_den520d_a'$ROBOTS'_'$SEED'.out' > 'perm-mdd++_den520d_a'$ROBOTS'_'$SEED'.txt'
  done
done
