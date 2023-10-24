#!/bin/bash

[[ -z $MIN_K ]] && MIN_K=2
[[ -z $MAX_K ]] && MAX_K=30

[[ -z $TOOLS ]] && TOOLS=(boox ccbs lra)

BOOX_ARGS=()
CCBS_ARGS=()
LRA_ARGS=(
    '-Fmakespan -B2'
    '-Fmakespan -B1.5'
    '-Fmakespan -B1.25'
    '-Fsoc -B2'
    '-Fsoc -B1.5'
    '-Fsoc -B1.25'
)

function exec_boox {
    ../../main/mapfR_solver_boOX "$@" --input-mapR-file=bottleneck/bottleneck_${k}.mapR --input-kruhoR-file=bottleneck/bottleneck_${k}.kruR --algorithm='smtcbsR*' --timeout=1800
}

function exec_ccbs {
    ../../../../ccbs/CCBS "$@" bottleneck/bottleneck_map_${k}.xml bottleneck/bottleneck_task_${k}.xml ../../../../ccbs/Examples/config_bottleneck.xml
}

function exec_lra {
    ../../../../mapf_r/bin/release/mathsat_solver "$@" bottleneck/bottleneck_${k}.mapR bottleneck/bottleneck_${k}.kruR
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

function run_tool {
    local tool=$1

    printf "%s ...\n" $tool

    local -n all_args=${tool^^}_ARGS
    if [[ -z ${all_args[*]} ]]; then
        run_tool_args $tool
    else
        for args in "${all_args[@]}"; do
            printf "with args: %s ...\n" "${args[*]}"
            run_tool_args $tool "${args[@]}"
        done
    fi
}

function run_tool_args {
    local tool=$1
    shift

    local args_str="$*"
    args_str=${args_str// /}
    args_str=${args_str//\'/}

    local tool_full=${tool}
    [[ -n $args_str ]] && tool_full+=_${args_str}

    local data_file=${DATA_FILE%.dat}_${tool_full}.dat
    printf "k\tt\n" >$data_file

    local failed=0
    local k
    for (( k=$MIN_K; $k <= $MAX_K; ++k )); do
        printf "k=%d ..." $k
        printf "%d\t" $k >>$data_file

        if (( $failed )); then
            printf "?" >>$data_file
        else
            local ofile=bottleneck/out_${tool_full}_${k}.txt

            exec_${tool} $@ >$ofile || exit $?

            local t=$(extract_t_${tool} <$ofile)
            printf "%.4f" $t >>$data_file
        fi

        ( (( $failed )) || failed_${tool} ) && {
            printf "\tX" >>$data_file
            failed=1
        }

        printf "\n"
        printf "\n" >>$data_file
    done
}

for tool in ${TOOLS[@]}; do
    run_tool $tool
done

printf "Done.\n"
exit 0
