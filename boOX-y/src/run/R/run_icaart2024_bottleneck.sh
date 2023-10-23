#!/bin/bash

[[ -z $MIN_K ]] && MIN_K=2
[[ -z $MAX_K ]] && MAX_K=10

BIN=../../main/mapfR_solver_boOX

DATA_FILE=./bottleneck.dat

printf "k\tt\n" >$DATA_FILE

for (( k=$MIN_K; $k <= $MAX_K; ++k )); do
    ofile=bottleneck/out_${k}

    printf "k=%d ..." $k
    $BIN --input-mapR-file=bottleneck/bottleneck_${k}.mapR --input-kruhoR-file=bottleneck/bottleneck_${k}.kruR --algorithm='smtcbsR*' >$ofile || exit $?
    printf "\n"

    t=$(sed -rn 's/^.*Wall clock TIME[^=]+= (.*)$/\1/p' <$ofile | tail -n 1)
    printf "%d\t%.4f" $k $t >>$DATA_FILE

    ( ! grep -q 'SOLVABLE' $ofile || grep -q 'FAILED' $ofile ) && {
        printf "\tX" >>$DATA_FILE
    }

    printf "\n" >>$DATA_FILE
done

printf "Done.\n"
exit 0
