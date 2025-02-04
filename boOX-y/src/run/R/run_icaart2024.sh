#!/bin/bash

function contains {
    local -n arr=$1
    local elem="$2"

    for e in "${arr[@]}"; do
        [[ $e == $elem ]] && return 0
    done

    return 1
}

function split_string {
    local in_str="$1"
    local -n out_arr=$2
    [[ -n $3 ]] && local IFS=$3

    out_arr=($in_str)
}

SCRIPT_KW=icaart2024

TIMEOUTS=(30 60 120 240 480 960)
TOOLS=(boox ccbs lra)

declare -A TOOL_NAMES
TOOL_NAMES=([boox]=SMT-CCBS [ccbs]=CCBS [lra]=SMT-LRA)

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

declare -A EXPERIMENT_TYPE{,2}
EXPERIMENTS=(empty road2-small)
EXPERIMENT_TYPE=([empty]=16-16)
EXPERIMENT_TYPE2=([empty]=random)

# it must match the n's in the underlying run scripts ...
declare -A {MIN,MAX}_NEIGHBOR
MIN_NEIGHBOR=([empty]=2)
MAX_NEIGHBOR=([empty]=5)

ACTION_SOLVE=0
ACTION_EXTRACT=0
ACTION_PLOT=0
CONFIRM=1
APPEND=0
IGNORE_ERRORS=0
while true; do
    [[ $1 =~ ^- ]] || break

    opt="$1"
    shift

    case "$opt" in
        -s) ACTION_SOLVE=1;;
        -x) ACTION_EXTRACT=1;;
        -p) ACTION_PLOT=1;;
        -n) CONFIRM=0;;
        -t) TIMEOUTS=($1); shift;;
        -a) APPEND=1;;
        -e) IGNORE_ERRORS=1;;
        *) printf "Unknown option: '%s'\n" "$opt" >&2; exit 1;;
    esac
done

(( $ACTION_SOLVE || $ACTION_EXTRACT || $ACTION_PLOT )) || {
    ACTION_SOLVE=1
    ACTION_EXTRACT=1
    ACTION_PLOT=1
}

if [[ -z $1 ]]; then
    USE_TOOLS=(${TOOLS[@]})
    RUN_EXPERIMENTS=(${EXPERIMENTS[@]})
else
    USE_TOOLS=()
    RUN_EXPERIMENTS=()
    for arg in "$@"; do
        if contains TOOLS "$arg"; then
            USE_TOOLS+=("$arg")
        elif contains EXPERIMENTS "$arg"; then
            RUN_EXPERIMENTS+=("$arg")
        else
            printf "Invalid argument: expected either\na tool - one of '%s',\nor an experiment - one of '%s',\nbut got: %s\n" "${TOOLS[*]}" "${EXPERIMENTS[*]}" "$arg" >&2
            exit 1
        fi
    done
    [[ -z ${USE_TOOLS[@]} ]] && USE_TOOLS=(${TOOLS[@]})
    [[ -z ${RUN_EXPERIMENTS[@]} ]] && RUN_EXPERIMENTS=(${EXPERIMENTS[@]})
fi

declare -A USE_TOOL
for tool in ${USE_TOOLS[@]}; do
    USE_TOOL[$tool]=1
done

declare -A RUN_EXPERIMENT
for exp in ${RUN_EXPERIMENTS[@]}; do
    RUN_EXPERIMENT[$exp]=1
done

export BOOX_ROOT=../../../
export BOOX_BIN=src/main/mapfR_solver_boOX

CCBS_ROOT_DIRNAME="$BOOX_ROOT/.."
export CCBS_ROOT="$CCBS_ROOT_DIRNAME/ccbs"
export CCBS_BIN=CCBS

LRA_ROOT_DIRNAME="$BOOX_ROOT/.."
export LRA_ROOT="$LRA_ROOT_DIRNAME/mapf_r"
export LRA_BIN=bin/release/mathsat_solver

function maybe_clone_dir (
    (( $ACTION_SOLVE )) || return 0

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
    (( $ACTION_SOLVE )) || return 0

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

function check_kruR {
    (( $ACTION_SOLVE )) || return 0

    local exp=$1

    compgen -G "${exp}*.kruR" >/dev/null && return 0

    local exp_full=$exp
    local exp_type=${EXPERIMENT_TYPE[$exp]}
    [[ -n $exp_type ]] && exp_full+=-${exp_type}

    check_bin boox release
    ./expr_${exp_full}_kruR-gen.sh || exit $?

    return 0
}

[[ -n ${USE_TOOL[boox]} || -n ${USE_TOOL[lra]} ]] && {
    for exp in ${RUN_EXPERIMENTS[@]}; do
        check_kruR $exp
    done
}

OUT_DIR=out
mkdir -p $OUT_DIR >/dev/null

export BOOX_OUT_PREFIX=$OUT_DIR/out
export CCBS_OUT_PREFIX=${BOOX_OUT_PREFIX}-ccbs
export LRA_OUT_PREFIX=${BOOX_OUT_PREFIX}-lra
export BOOX_ERR_PREFIX=$OUT_DIR/err
export CCBS_ERR_PREFIX=${BOOX_ERR_PREFIX}-ccbs
export LRA_ERR_PREFIX=${BOOX_ERR_PREFIX}-lra

function _solve {
    (( $ACTION_SOLVE )) || return 0

    printf "\nSolving %s\n" "$run_str"
    (( $CONFIRM )) && {
        printf "Confirm ...\n"
        read
    }

    export TIMEOUT=$timeout

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

function _extract_data_file_head {
    local key_var=$1
    local out_f="$2"

    local -n key_val=$key_var

    local key_name=$key_var
    case $key_var in
        timeout)
            local first_key_val=${TIMEOUTS[0]}
            key_name="T"
            ;;
        k)
            local first_key_val=${kruhobots[0]}
            ;;
        *)
            printf "_extract_data_file_head key_var ERROR\n" >&2
            exit 7
    esac

    (( !$APPEND && $key_val == $first_key_val )) && {
        printf "%s" "$key_name" >"$out_f"
        for n in ${ns[@]}; do
            [[ $n == $invalid_n ]] && continue
            printf "\tn=%d" $n >>"$out_f"
        done
        printf "\n" >>"$out_f"
    }
    printf "%d" $key_val >>"$out_f"
}

function _extract {
    (( $ACTION_EXTRACT )) || return 0

    _extract_data_file_head timeout "$results_solved_file"

    for f in extract_solved{,_{begin,finish}{,_n}}_f; do
        local -n f_link=$f
        f_link=_${f%_f}_$tool
        local -n f_callable_link=${f}_callable
        f_callable_link=0
        command -v $f_link &>/dev/null && f_callable_link=1
    done

    (( $extract_solved_begin_f_callable )) && $extract_solved_begin_f

    printf "\nExtracting %s\n" "$run_str"

    for n in ${ns[@]}; do
        local lsolved_data_var=lsolved_data_n$n
        [[ $n != $invalid_n ]] && lsolved_data_var+=_n$n
        local -n lsolved_data=$lsolved_data_var
        lsolved_data=()
    done

    for n in ${ns[@]}; do
        local solved=0
        local errors=0

        local lsolved_data_var=lsolved_data_n$n
        [[ $n != $invalid_n ]] && lsolved_data_var+=_n$n
        local -n lsolved_data=$lsolved_data_var

        local aux_n_f=`mktemp`
        (( $extract_solved_begin_n_f_callable )) && $extract_solved_begin_n_f

        for k in ${kruhobots[@]}; do
            printf "Extracting "
            [[ $n != $invalid_n ]] && printf "n=%d " $n
            printf "k=%d ..." $k
            local lsolved=0
            for s in ${scenarios[@]}; do
                local efile=${err_full_prefix}
                [[ $n != $invalid_n ]] && efile+=_n${n}
                efile+=-${s}_k${k}.txt
                (( $IGNORE_ERRORS )) && [[ -r $efile ]] && {
                    (( ++errors ))
                    continue
                }

                local ofile=${out_full_prefix}
                [[ $n != $invalid_n ]] && ofile+=_n${n}
                ofile+=-${s}_k${k}.txt
                [[ -r $ofile ]] || {
                    printf "'%s' not readable !!\n" "$ofile" >&2
                    exit 2
                }
                (( $(head -n 1 "$ofile" | wc -c) == 0 )) && {
                    printf "'%s' is empty !!\n" "$ofile" >&2
                    exit 2
                }

                local skip=0
                case $tool in
                    boox) ! grep -q 'SOLVABLE' || grep -q 'FAILED';;
                    lra) ! grep -q 'guaranteed suboptimal coefficient';;
                    ccbs) ! grep -q 'Soulution found: true';;
                    *) printf "TOOL_ERROR\n" >&2; exit 5;;
                esac <"$ofile" && skip=1
                (( $skip )) && continue

                (( ++solved ))
                (( ++lsolved ))

                (( $extract_solved_f_callable )) && $extract_solved_f <"$ofile"
            done
            printf " solved: %d\n" $lsolved

            lsolved_data[$k]=$lsolved
        done
        printf "Total solved instances"
        [[ $n != $invalid_n ]] && printf " for n=%d" $n
        printf ": %d\n" $solved
        (( $IGNORE_ERRORS && $errors > 0 )) && printf "Skipped error instances: %d\n" $errors

        printf "\t%d" $solved >>"$results_solved_file"

        (( $extract_solved_finish_n_f_callable )) && $extract_solved_finish_n_f
        rm -f $aux_n_f
    done
    printf "\n" >>"$results_solved_file"

    for k in ${kruhobots[@]}; do
        _extract_data_file_head k "$results_solved_rate_file"

        for n in ${ns[@]}; do
            local lsolved_data_var=lsolved_data_n$n
            [[ $n != $invalid_n ]] && lsolved_data_var+=_n$n
            local -n lsolved_data=$lsolved_data_var

            local lsolved=${lsolved_data[$k]}
            local lsolved_rate=$(( ($lsolved*100) / ${#scenarios[@]} ))

            printf "\t%d" $lsolved_rate >>"$results_solved_rate_file"
        done
        printf "\n" >>"$results_solved_rate_file"
    done

    (( $extract_solved_finish_f_callable )) && $extract_solved_finish_f

    return 0
}

function _extract_solved_begin_lra {
    _extract_data_file_head timeout "$results_coef_file"
}

function _extract_solved_lra {
    awk -f "$LRA_ROOT/tools/results.awk" >>$aux_n_f || exit $?
}

function _extract_solved_finish_n_lra {
    local avg_suboptimal_coef=$(awk 'BEGIN{coef_sum=0} {coef_sum+=$3} END{print coef_sum/NR}' $aux_n_f) || exit $?

    [[ $avg_suboptimal_coef =~ [1-9][0-9]*\.[0-9]+ ]] || {
        printf "Expected guaranteed suboptimal coefficient, got: %s\n" "$avg_suboptimal_coef" >&2
        exit 3
    }

    printf "\t%.2f" $avg_suboptimal_coef >>"$results_coef_file"
}

function _extract_solved_finish_lra {
    printf "\n" >>"$results_coef_file"
}

function _run_main {
    _solve
    _extract
}

GNUPLOT_SOLVED_SCRIPT=${SCRIPT_KW}_solved.gp
GNUPLOT_SOLVED_RATE_SCRIPT=${SCRIPT_KW}_solved_rate.gp

function _merge_and_plot {
    local rsfile="$1"
    local mrsfile="$2"
    local key_arr_var=$3
    local gnuplot_script="$4"

    [[ -r $rsfile ]] || {
        printf "Results file not readable: %s\n" "$rsfile" >&2
        exit 4
    }

    printf "\n"

    local -n key_arr=$key_arr_var
    local rows=$(( ${#key_arr[@]} + 1 ))

    local first=0
    [[ $tool_id == 0 && (-z $args_id || $args_id == 0) ]] && first=1

    local last=0
    [[ $tool_id == $((${#USE_TOOLS[@]}-1)) && (-z $args_id || $args_id == $((${#all_args[@]}-1))) ]] && last=1

    local mrsfile_bak="$mrsfile"
    for n in ${ns[@]}; do
        mrsfile="$mrsfile_bak"
        [[ $n != $invalid_n ]] && mrsfile="${mrsfile/_merged/_merged_n${n}}"

        printf "Merging %s" "$rsfile"
        [[ $n != $invalid_n ]] && printf " n=%d" $n
        printf " -> %s ...\n" "$mrsfile"

        if (( $first )); then
            awk "NR<=$rows{print \$1}" "$rsfile" >"$mrsfile"
        else
            [[ -w $mrsfile ]] || {
                printf "Shared results file not writable: %s\n" "$mrsfile" >&2
                exit 4
            }
        fi

        local col=2
        [[ $n != $invalid_n ]] && (( col += $n - $min_neighbor ))

        local aux_f=`mktemp`
        paste "$mrsfile" <(awk "BEGIN{print \"$tool_name_full\"} NR>1&&NR<=$rows{print \$$col}" "$rsfile") >$aux_f
        mv $aux_f "$mrsfile"

        (( $last )) || continue

        local psfile="${mrsfile%.dat}.svg"
        psfile="${psfile/_merged/}"

        #+ skip if the commands below are not available
        printf "Plotting %s -> %s ...\n" "$mrsfile" "$psfile"

        gnuplot -e "ifname='$mrsfile'; ofname='$psfile'" "$gnuplot_script" || exit $?

        local psfile_pdf="${psfile%.svg}.pdf"

        printf "Exporting to PDF %s -> %s ...\n" "$psfile" "$psfile_pdf"

        rsvg-convert -f pdf -o "$psfile_pdf" "$psfile" || exit $?
    done
}

function _run_plot {
    (( $ACTION_PLOT )) || return 0

    [[ $timeout ==  ${TIMEOUTS[0]} ]] && {
        _merge_and_plot "$results_solved_file" "$merged_results_solved_file" TIMEOUTS "$GNUPLOT_SOLVED_SCRIPT"
    }

    _merge_and_plot "$results_solved_rate_file" "$merged_results_solved_rate_file" kruhobots "$GNUPLOT_SOLVED_RATE_SCRIPT"
}

function split_args {
    local in_str="${1#_}"
    local -n out_str=$2

    local arr
    split_string "$in_str" arr -

    local arr2
    local comma
    for i in ${!arr[@]}; do
        (( $i == 0 )) && continue
        if (( $i == ${#arr[@]}-1 )); then
            comma=0
        else
            comma=1
        fi
        local elem="${arr[$i]}"
        if [[ $elem =~ ^F[a-z] ]]; then
            elem=${elem:1:1}
            elem=${elem^}:
            comma=0
        elif [[ $elem =~ ^B[1-9] ]]; then
            local e1=${elem:1:1}
            (( e1 -= 1 ))
            elem=${e1}${elem:2}
        fi
        (( $comma )) && elem+=,
        arr2+=("$elem")
    done

    out_str="${arr2[*]}"
    out_str="${out_str// /}"
}

function _run {
    local args_id=$1

    export ARGS=
    export ARGS_PREFIX=

    local args_str
    [[ -n $args_id ]] && {
        ARGS="${all_args[$args_id]}"

        args_str=" with args \"$ARGS\""

        ARGS_PREFIX=_${ARGS// /}
        ARGS_PREFIX=${ARGS_PREFIX//\'/}

        local tool_name_args
        split_args $ARGS_PREFIX tool_name_args
        tool_name_full="${tool_name_full_bak}($tool_name_args)"

        out_full_prefix=${out_full_prefix_bak/$out_prefix/${out_prefix}$ARGS_PREFIX}
        err_full_prefix=${err_full_prefix_bak/$err_prefix/${err_prefix}$ARGS_PREFIX}
        results_full_prefix=${results_full_prefix_bak/$results_prefix/${results_prefix}$ARGS_PREFIX}
    }

    local run_str=$(printf "%s%s <- %s with timeout %d" $tool "$args_str" $experiments_full_name $timeout)

    local results_solved_file=${results_full_prefix}_solved.dat
    local merged_results_solved_file=${merged_results_full_prefix}_solved_merged.dat

    local results_solved_rate_file=${results_full_prefix}_tout${timeout}_solved_rate.dat
    local merged_results_solved_rate_file=${merged_results_full_prefix}_tout${timeout}_solved_rate_merged.dat

    if [[ $tool == lra ]]; then
        local results_coef_file=${results_full_prefix}_coef.dat
    fi

    _run_${action}

    return 0
}

function run {
    local action=$1
    shift

    local tool_id=$1
    local experiments_kw=${2,,}
    local timeout=$3

    local tool=${USE_TOOLS[$tool_id],,}
    local tool_suffix
    [[ $tool != boox ]] && tool_suffix=-$tool
    local tool_name="${TOOL_NAMES[$tool]}"
    local tool_name_full="$tool_name"

    local experiments_type=${EXPERIMENT_TYPE[$experiments_kw]}
    local experiments_type2=${EXPERIMENT_TYPE2[$experiments_kw]}

    local experiments_name=${experiments_kw}
    [[ -n $experiments_type ]] && experiments_name+=-${experiments_type}
    local experiments_full_name=${experiments_name}
    [[ -n $experiments_type2 ]] && experiments_full_name+=-${experiments_type2}

    local min_neighbor=${MIN_NEIGHBOR[$experiments_kw]}
    local max_neighbor=${MAX_NEIGHBOR[$experiments_kw]}
    local n_neighbor=1
    local ns=()
    local invalid_n=0
    if [[ -n $min_neighbor && -n $max_neighbor ]]; then
        (( n_neighbor += $max_neighbor - $min_neighbor ))

        for (( n=$min_neighbor; $n <= $max_neighbor; ++n )); do
            ns+=($n)
        done
    else
        ns=($invalid_n)
    fi

    local scenarios=($(cat scenarios_$experiments_kw))
    local n_scenarios=${#scenarios[@]}

    local kruhobots=($(cat kruhobots_$experiments_kw))
    local n_kruhobots=${#kruhobots[@]}

    local max_n=$(( $n_kruhobots*$n_scenarios*$n_neighbor ))

    local -n out_prefix=${tool^^}_OUT_PREFIX
    local -n err_prefix=${tool^^}_ERR_PREFIX
    local results_prefix=${out_prefix#*/}
    local merged_results_prefix=${BOOX_OUT_PREFIX#*/}

    local out_full_prefix=${out_prefix}_${experiments_full_name}_tout${timeout}
    local err_full_prefix=${err_prefix}_${experiments_full_name}_tout${timeout}
    local results_full_prefix=${results_prefix}_${experiments_full_name}
    local merged_results_full_prefix=${merged_results_prefix}_${experiments_full_name}

    local -n all_args=${tool^^}_ARGS
    if [[ -z ${all_args[*]} ]]; then
        _run
    else
        local tool_name_full_bak="$tool_name_full"

        local out_full_prefix_bak=$out_full_prefix
        local err_full_prefix_bak=$err_full_prefix
        local results_full_prefix_bak=$results_full_prefix

        for args_id in ${!all_args[@]}; do
            _run $args_id
        done
    fi
}

for timeout in ${TIMEOUTS[@]}; do
    for tool_id in ${!USE_TOOLS[@]}; do
        for exp in ${RUN_EXPERIMENTS[@]}; do
            run main $tool_id $exp $timeout
        done
    done
done

for tool_id in ${!USE_TOOLS[@]}; do
    for exp in ${RUN_EXPERIMENTS[@]}; do
        for timeout in ${TIMEOUTS[@]}; do
            run plot $tool_id $exp $timeout
        done
    done
done

printf "\nDone.\n"
exit 0
