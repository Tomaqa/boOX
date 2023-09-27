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
TOOLS=(boox lra ccbs)

BOOX_ARGS=()
LRA_ARGS=(
    '-Fmakespan -B2'
    '-Fsoc -B2'
    '-Fmakespan -B1.5'
    '-Fsoc -B1.5'
    '-Fmakespan -B1.25'
    '-Fsoc -B1.25'
)
CCBS_ARGS=()

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

LRA_ROOT_DIRNAME="$BOOX_ROOT/.."
export LRA_ROOT="$LRA_ROOT_DIRNAME/mapf_r"
export LRA_BIN=bin/release/mathsat_solver

CCBS_ROOT_DIRNAME="$LRA_ROOT_DIRNAME"
export CCBS_ROOT="$CCBS_ROOT_DIRNAME/ccbs"
export CCBS_BIN=CCBS

function maybe_clone_dir (
    local tool=${1^^}
    local clone_args=($2)
    local add_cmd=($3)

    local -n root=${tool}_ROOT

    [[ -d $root/ ]] && return 0

    printf "%s implementation is missing, expected at '%s'\n" $tool "$root" >&2

    printf "\nDo you want me to git-clone it? [enter]\n"
    read

    local -n root_dirname=${tool}_ROOT_DIRNAME
    local root_basename=$(basename "$root")
    cd "$root_dirname" || exit $?
    git clone ${clone_args[@]} "$root_basename" || exit $?

    [[ -z ${add_cmd[*]} ]] && return 0

    cd "$root_basename" || exit $?
    ${add_cmd[@]} || exit $?

    return 0
)

function check_bin (
    local tool=${1^^}
    local make_rule=$2

    local -n root=${tool}_ROOT
    local -n bin=${tool}_BIN

    [[ -x $root/$bin ]] && return 0

    printf "%s binary is missing, expected at '%s'\n" $tool "$root/$bin" >&2

    cd "$root" || exit $?
    make $make_rule || exit $?
    [[ -x $bin ]] && return 0

    printf "'%s' not executable.\n" "$root/$bin" >&2
    exit 1
)

[[ -n ${USE_TOOL[boox]} ]] && {
    check_bin boox release
}

[[ -n ${USE_TOOL[lra]} ]] && {
    maybe_clone_dir lra '--recurse_submodules https://gitlab.com/Tomaqa/mapf_r.git'
    check_bin lra
}

[[ -n ${USE_TOOL[ccbs]} ]] && {
    maybe_clone_dir ccbs https://github.com/PathPlanning/Continuous-CBS.git 'cmake .'
    check_bin ccbs
}

[[ -n ${USE_TOOL[boox]} || -n ${USE_TOOL[lra]} ]] && {
    compgen -G '*.kruR' >/dev/null || {
        check_bin boox release
        ./expr_empty-16-16_kruR-gen.sh || exit $?
    }
}

OUT_DIR=out
mkdir -p $OUT_DIR >/dev/null

export BOOX_OUT_PREFIX=$OUT_DIR/out
export LRA_OUT_PREFIX=${BOOX_OUT_PREFIX}-lra
export CCBS_OUT_PREFIX=${BOOX_OUT_PREFIX}-ccbs
export BOOX_ERR_PREFIX=$OUT_DIR/err
export LRA_ERR_PREFIX=${BOOX_ERR_PREFIX}-lra
export CCBS_ERR_PREFIX=${BOOX_ERR_PREFIX}-ccbs

MIN_NEIGHBOR=2

function _solve {
    (( $EXTRACT_ONLY )) && return 0

    printf "\nSolving %s\n" "$run_str"
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
        printf "Waiting on %s (%d/%d done) ...\n" "$run_str" $n $max_n
    done

    printf "\nSolving %s done.\n" "$run_str"

    rm -f ${out_full_prefix}*.aux
    if (( ! $IGNORE_ERRORS )); then
        rm -f ${err_full_prefix}*.txt
    else
        compgen -G ${err_full_prefix}'*.txt' >/dev/null && for f in ${err_full_prefix}*.txt; do
            (( $(head -n 1 "$f" | wc -l) == 0 )) && rm "$f"
        done
    fi

    return 0
}

function _extract {
    local sfile=${results_full_prefix}_solved.dat

    (( !$APPEND && $timeout == ${TIMEOUTS[0]} )) && {
        >"$sfile"
        for (( n=$MIN_NEIGHBOR; $n <= $max_neighbor; ++n )); do
            printf "\tn=%d" $n >>"$sfile"
        done
        printf "\n" >>"$sfile"
    }
    printf "T=%d" $timeout >>"$sfile"

    printf "\nExtracting %s\n" "$run_str"
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
                    ccbs) ! grep -q 'Soulution found: true';;
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

    return 0
}

function _run {
    export ARGS="$@"
    export ARGS_PREFIX=

    local args_str
    [[ -n $ARGS ]] && {
        args_str=" with args \"$ARGS\""

        ARGS_PREFIX=_${ARGS// /}
        ARGS_PREFIX=${ARGS_PREFIX//\'/}
        out_full_prefix=${out_full_prefix_bak/$out_prefix/${out_prefix}$ARGS_PREFIX}
        err_full_prefix=${err_full_prefix_bak/$err_prefix/${err_prefix}$ARGS_PREFIX}
        results_full_prefix=${results_full_prefix_bak/$results_prefix/${results_prefix}$ARGS_PREFIX}
    }

    local run_str=$(printf "%s%s <- %s with timeout %d" $tool "$args_str" $experiments_full_name $timeout)

    _solve
    _extract

    return 0
}

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
    local results_prefix=${out_prefix#*/}

    local timeout=`cat timeout`

    local out_full_prefix=${out_prefix}_${experiments_full_name}_tout${timeout}
    local err_full_prefix=${err_prefix}_${experiments_full_name}_tout${timeout}
    local results_full_prefix=${results_prefix}_${experiments_full_name}

    local -n all_args=${tool^^}_ARGS
    if [[ -z ${all_args[*]} ]]; then
        _run
    else
        local out_full_prefix_bak=$out_full_prefix
        local err_full_prefix_bak=$err_full_prefix
        local results_full_prefix_bak=$results_full_prefix

        for args in "${all_args[@]}"; do
            _run $args
        done
    fi
}

for timeout in ${TIMEOUTS[@]}; do
    printf "%d" $timeout >timeout
    for tool in ${USE_TOOLS[@]}; do
        run $tool empty 16-16 random 5
    done
done
