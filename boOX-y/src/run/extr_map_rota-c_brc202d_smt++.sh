ROBOT_LIST=`cat robots_maps_c`
SEED_LIST=`cat seeds_10`
SIZE=16

for ROBOTS in $ROBOT_LIST;
do
  for SEED in $SEED_LIST;	
  do            
    echo $ROBOTS,$SEED
     grep "machine TIME" 'rota-smt++_brc202d_c2_a'$ROBOTS'_'$SEED'.txt'
     grep "clauses" 'rota-smt++_brc202d_c2_a'$ROBOTS'_'$SEED'.txt'
  done
done

for ROBOTS in $ROBOT_LIST;
do
  for SEED in $SEED_LIST;	
  do            
    echo $ROBOTS,$SEED
     grep "machine TIME" 'rota-smt++_brc202d_c3_a'$ROBOTS'_'$SEED'.txt'
     grep "clauses" 'rota-smt++_brc202d_c3_a'$ROBOTS'_'$SEED'.txt'
  done
done

for ROBOTS in $ROBOT_LIST;
do
  for SEED in $SEED_LIST;	
  do            
    echo $ROBOTS,$SEED
     grep "machine TIME" 'rota-smt++_brc202d_c4_a'$ROBOTS'_'$SEED'.txt'
     grep "clauses" 'rota-smt++_brc202d_c4_a'$ROBOTS'_'$SEED'.txt'
  done
done
