#!/bin/bash

export BOOX_ROOT=../../../
export BOOX_BIN=src/main/mapfR_solver_boOX

[[ -x $BOOX_ROOT/$BOOX_BIN ]] || (
    cd $BOOX_ROOT
    make release || exit $?
    [[ -x $BOOX_BIN ]] && exit 0
    printf "'%s' not executable.\n" "$BOOX_ROOT/$BOOX_BIN" >&2
    exit 1
)

export LRA_ROOT="$BOOX_ROOT/../mapf_r"
export LRA_BIN=bin/release/mathsat_solver

[[ -d $LRA_ROOT/ ]] || (
    printf "SMT-LRA implementation is missing, expected at '%s'\n" >&2

    printf "\nDo you want me to git-clone it? [enter]\n"
    read
    cd $(basename $LRA_ROOT)
    git clone --recurse-submodules https://gitlab.com/Tomaqa/mapf_r.git || exit $?
)

[[ -x $LRA_ROOT/$LRA_BIN ]] || (
    cd $LRA_ROOT
    make || exit $?
    [[ -x $LRA_BIN ]] && exit 0
    printf "'%s' not executable.\n" "$LRA_ROOT/$LRA_BIN" >&2
    exit 1
)

compgen -G '*.kruR' >/dev/null || (
    ./expr_empty-16-16_kruR-gen.sh || exit $?
)

export BOOX_OUT_PREFIX=out
export LRA_OUT_PREFIX=${BOOX_OUT_PREFIX}-lra

MIN_NEIGHBOR=2

function run {
    local tool=${1,,}
    local experiments_kw=${2,,}
    local experiments_type=$3
    local experiments_type2=$4
    local max_neighbor=$5

    local experiments_name=${experiments_kw}-${experiments_type}
    local experiments_full_name=${experiments_name}-${experiments_type2}

    local tool_suffix
    [[ $tool != boox ]] && tool_suffix=-$tool

    local n_neighbor=$(( $max_neighbor - $MIN_NEIGHBOR + 1 ))

    local scenarios=($(cat scenarios_$experiments_kw))
    local n_scenarios=${#scenarios[@]}

    local kruhobots=($(cat kruhobots_$experiments_kw))
    local n_kruhobots=${#kruhobots[@]}

    local max_n=$(( $n_kruhobots*$n_scenarios*$n_neighbor ))

    local -n out_prefix=${tool^^}_OUT_PREFIX

    local timeout=`cat timeout`

    printf "\nSolving %s <- %s with timeout %d\n" $tool $experiments_full_name $timeout
    (( $CONFIRM )) && {
        printf "Confirm ...\n"
        read
    }

    rm -f ${out_prefix}_*${experiments_full_name}*.txt
    ./run_solve${tool_suffix}_${experiments_name}.sh

    while true; do
        sleep 5
        local n=$(for f in ${out_prefix}_*${experiments_full_name}*.txt; do tail -n 1 "$f"; done | wc -l)
        (( $n == $max_n )) && break
        printf "Waiting on %s <- %s (%d/%d done) ...\n" $tool $experiments_full_name $n $max_n
    done

    printf "\nSolving %s <- %s done.\n" $tool $experiments_full_name

    local sfile=${out_prefix}_${experiments_full_name}_solved.dat

    (( $timeout == ${TIMEOUTS[0]} )) && {
        >"$sfile"
        for (( n=$MIN_NEIGHBOR; $n <= $max_neighbor; ++n )); do
            printf "\tn=%d" $n >>"$sfile"
        done
        printf "\n" >>"$sfile"
    }
    printf "T=%d" $timeout >>"$sfile"

    for (( n=$MIN_NEIGHBOR; $n <= $max_neighbor; ++n )); do
        printf "Extracting n=%d ...\n" $n
        local solved=0
        for k in ${kruhobots[@]}; do
            for s in ${scenarios[@]}; do
                local ofile=${out_prefix}_$experiments_full_name'_n'$n'-'$s'_k'$k'.txt'
                printf "Extracting '%s' ...\n" "$ofile"
                [[ -r $ofile ]] || {
                    printf "'%s' not readable !!\n" "$ofile" >&2
                    exit 2
                }
                (( $(tail -n 1 "$ofile" | wc -l) == 1 )) || {
                    printf "'%s' is empty !!\n" "$ofile" >&2
                    exit 2
                }

                local skip=0
                case $tool in
                    boox) grep -q 'INDETERMINATE';;
                    lra) ! grep -q 'minimized objective time';;
                esac <"$ofile" && skip=1
                (( $skip )) && continue

                (( ++solved ))
            done
        done
        printf "Total solved instances for n=%d: %d\n" $n $solved

        printf "\t%d" $solved >>"$sfile"
    done
    printf "\n" >>"$sfile"
}

TIMEOUTS=(10 20)
TOOLS=(boox lra)

CONFIRM=1
[[ $1 == -n ]] && {
    CONFIRM=0
    shift
}

[[ -n $1 ]] && {
    found=0
    for t in ${TOOLS[@]}; do
        [[ $t != $1 ]] && continue
        found=1
        break
    done
    (( $found )) || {
        printf "Invalid tool: expected one of %s, got: %s\n" ${TOOLS[@]} "$1" >&2
    }
    TOOLS=($1)
}

for timeout in ${TIMEOUTS[@]}; do
    printf "%d" $timeout >timeout
    for tool in ${TOOLS[@]}; do
        run $tool empty 16-16 random 5
    done
done
