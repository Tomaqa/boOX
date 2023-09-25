#!/bin/bash

function contains {
    local -n arr=$1
    local elem="$2"

    for e in "${arr[@]}"; do
        [[ $e == $elem ]] && return 0
    done

    return 1
}

TIMEOUTS=(30 60 120 240 480 960)
TOOLS=(boox lra)

CONFIRM=1
EXTRACT_ONLY=0
APPEND=0
IGNORE_ERRORS=0
while true; do
    [[ $1 =~ ^- ]] || break

    opt="$1"
    shift

    case "$opt" in
        -n) CONFIRM=0;;
        -x) EXTRACT_ONLY=1;;
        -t) TIMEOUTS=($1); shift;;
        -a) APPEND=1;;
        -e) IGNORE_ERRORS=1;;
        *) printf "Unknown option: '%s'\n" "$opt" >&2; exit 1;;
    esac
done

if [[ -z $1 ]]; then
    USE_TOOLS=(${TOOLS[@]})
else
    USE_TOOLS=()
    for t in "$@"; do
        contains TOOLS "$t" || {
            printf "Invalid tool: expected one of '%s', got: %s\n" "${TOOLS[*]}" "$t" >&2
            exit 1
        }
        USE_TOOLS+=("$t")
    done
fi

declare -A USE_TOOL
for tool in ${USE_TOOLS[@]}; do
    USE_TOOL[$tool]=1
done

export BOOX_ROOT=../../../
export BOOX_BIN=src/main/mapfR_solver_boOX

export LRA_ROOT="$BOOX_ROOT/../mapf_r"
export LRA_BIN=bin/release/mathsat_solver

function check_bin {
    local tool=${1^^}
    local make_rule=$2

    local -n root=${tool}_ROOT
    local -n bin=${tool}_BIN

    [[ -x $root/$bin ]] && return 0

    cd $root
    make $make_rule || return $?
    [[ -x $bin ]] && return 0

    printf "'%s' not executable.\n" "$root/$bin" >&2
    return 1
}

[[ -n ${USE_TOOL[boox]} ]] && {
    check_bin boox release || exit $?
}

[[ -n ${USE_TOOL[lra]} ]] && {
    [[ -d $LRA_ROOT/ ]] || {
        printf "SMT-LRA implementation is missing, expected at '%s'\n" $LRA_ROOT >&2

        printf "\nDo you want me to git-clone it? [enter]\n"
        read
        cd $(basename $LRA_ROOT)
        git clone --recurse-submodules https://gitlab.com/Tomaqa/mapf_r.git || exit $?
    }

    check_bin lra || exit $?
}

compgen -G '*.kruR' >/dev/null || {
    check_bin boox release || exit $?
    ./expr_empty-16-16_kruR-gen.sh || exit $?
}

OUT_DIR=out
mkdir -p $OUT_DIR >/dev/null

export BOOX_OUT_PREFIX=$OUT_DIR/out
export LRA_OUT_PREFIX=${BOOX_OUT_PREFIX}-lra
export BOOX_ERR_PREFIX=$OUT_DIR/err
export LRA_ERR_PREFIX=${BOOX_ERR_PREFIX}-lra

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
    local -n err_prefix=${tool^^}_ERR_PREFIX

    local timeout=`cat timeout`

    local out_full_prefix=${out_prefix}_${experiments_full_name}_tout${timeout}
    local err_full_prefix=${err_prefix}_${experiments_full_name}_tout${timeout}

    (( $EXTRACT_ONLY )) || {
        printf "\nSolving %s <- %s with timeout %d\n" $tool $experiments_full_name $timeout
        (( $CONFIRM )) && {
            printf "Confirm ...\n"
            read
        }

        rm -f ${out_full_prefix}*.txt
        rm -f ${out_full_prefix}*.aux
        rm -f ${err_full_prefix}*.txt
        ./run_solve${tool_suffix}_${experiments_name}.sh

        while true; do
            sleep 5
            (( ! $IGNORE_ERRORS )) && compgen -G ${err_full_prefix}'*.txt' >/dev/null && for f in ${err_full_prefix}*.txt; do
                (( $(head -n 1 "$f" | wc -l) == 0 )) && continue
                printf "Error in '%s' :\n" "$f" >&2
                cat "$f" >&2
                exit 3
            done
            local n=$(
                compgen -G ${out_full_prefix}'*.aux' >/dev/null || {
                    echo 0
                    exit
                }
                for f in ${out_full_prefix}*.aux; do head -n 1 "$f"; done | wc -l
            )
            (( $n == $max_n )) && break
            printf "Waiting on %s <- %s (%d/%d done) ...\n" $tool $experiments_full_name $n $max_n
        done

        printf "\nSolving %s <- %s done.\n" $tool $experiments_full_name

        rm -f ${out_full_prefix}*.aux
        if (( ! $IGNORE_ERRORS )); then
            rm -f ${err_full_prefix}*.txt
        else
            compgen -G ${err_full_prefix}'*.txt' >/dev/null && for f in ${err_full_prefix}*.txt; do
                (( $(head -n 1 "$f" | wc -l) == 0 )) && rm "$f"
            done
        fi
    }

    local sfile=${out_prefix#*/}_${experiments_full_name}_solved.dat

    (( !$APPEND && $timeout == ${TIMEOUTS[0]} )) && {
        >"$sfile"
        for (( n=$MIN_NEIGHBOR; $n <= $max_neighbor; ++n )); do
            printf "\tn=%d" $n >>"$sfile"
        done
        printf "\n" >>"$sfile"
    }
    printf "T=%d" $timeout >>"$sfile"

    printf "\nExtracting %s <- %s with timeout %d\n" $tool $experiments_full_name $timeout
    for (( n=$MIN_NEIGHBOR; $n <= $max_neighbor; ++n )); do
        local solved=0
        local errors=0
        for k in ${kruhobots[@]}; do
            printf "Extracting n=%d k=%d ..." $n $k
            local lsolved=0
            for s in ${scenarios[@]}; do
                local efile=${err_full_prefix}_n${n}-${s}_k${k}.txt
                (( $IGNORE_ERRORS )) && [[ -r $efile ]] && {
                    (( ++errors ))
                    continue
                }

                local ofile=${out_full_prefix}_n${n}-${s}_k${k}.txt
                [[ -r $ofile ]] || {
                    printf "'%s' not readable !!\n" "$ofile" >&2
                    exit 2
                }
                (( $(head -n 1 "$ofile" | wc -l) == 1 )) || {
                    printf "'%s' is empty !!\n" "$ofile" >&2
                    exit 2
                }

                local skip=0
                case $tool in
                    boox) ! grep -q 'SOLVABLE';;
                    lra) ! grep -q 'guaranteed suboptimal coefficient';;
                    *) printf "TOOL_ERROR\n" >&2; exit 5;;
                esac <"$ofile" && skip=1
                (( $skip )) && continue

                (( ++solved ))
                (( ++lsolved ))
            done
            printf " solved: %d\n" $lsolved
        done
        printf "Total solved instances for n=%d: %d\n" $n $solved
        (( $IGNORE_ERRORS && $errors > 0 )) && printf "Skipped error instances: %d\n" $errors

        printf "\t%d" $solved >>"$sfile"
    done
    printf "\n" >>"$sfile"
}

for timeout in ${TIMEOUTS[@]}; do
    printf "%d" $timeout >timeout
    for tool in ${USE_TOOLS[@]}; do
        run $tool empty 16-16 random 5
    done
done
