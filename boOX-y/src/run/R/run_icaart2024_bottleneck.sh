#!/bin/bash

[[ -z $MIN_K ]] && MIN_K=2
[[ -z $MAX_K ]] && MAX_K=10

TOOLS=(boox ccbs lra)

function exec_boox {
    ../../main/mapfR_solver_boOX --input-mapR-file=bottleneck/bottleneck_${k}.mapR --input-kruhoR-file=bottleneck/bottleneck_${k}.kruR --algorithm='smtcbsR*' --timeout=1800
}

function exec_ccbs {
    ../../../../ccbs/CCBS bottleneck/bottleneck_map_${k}.xml bottleneck/bottleneck_task_${k}.xml ../../../../ccbs/Examples/config_bottleneck.xml
}

function exec_lra {
    ../../../../mapf_r/bin/release/mathsat_solver bottleneck/bottleneck_${k}.mapR bottleneck/bottleneck_${k}.kruR
}

function extract_t_boox {
    sed -rn 's/^.*Wall clock TIME[^=]+= (.*)$/\1/p' | tail -n 1
}

function extract_t_ccbs {
    sed -rn 's/^Runtime: (.*)$/\1/p'
}

function extract_t_lra {
    sed -rn 's/^main duration: ([0-9.]+) s$/\1/p'
}

function failed_boox {
    ! grep -q 'SOLVABLE' $ofile || grep -q 'FAILED' $ofile
}

function failed_ccbs {
    grep -q 'found: false' $ofile
}

function failed_lra {
    ! grep -q 'guaranteed suboptimal coefficient' $ofile
}

DATA_FILE=./bottleneck.dat

for tool in ${TOOLS[@]}; do
    printf "%s ...\n" $tool

    data_file=${DATA_FILE%.dat}_${tool}.dat
    printf "k\tt\n" >$data_file

    failed=0
    for (( k=$MIN_K; $k <= $MAX_K; ++k )); do
        printf "k=%d ..." $k
        printf "%d\t" $k >>$data_file

        if (( $failed )); then
            printf "?" >>$data_file
        else
            ofile=bottleneck/out_${tool}_${k}.txt

            exec_${tool} >$ofile || exit $?

            t=$(extract_t_${tool} <$ofile)
            printf "%.4f" $t >>$data_file
        fi

        ( (( $failed )) || failed_${tool} ) && {
            printf "\tX" >>$data_file
            failed=1
        }

        printf "\n"
        printf "\n" >>$data_file
    done
done

printf "Done.\n"
exit 0
