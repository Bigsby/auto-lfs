sudo -s

export DRIVE=sdb
export PARTITION_NUMBER=1

cat >>  /etc/bash.bashrc << EOF
#######################################
## Helper functions
#######################################
function go_to_sources() {
    cd "$LFS/sources"
}

function tar_cd() {
    if [ -n "$3" ]; then
        last_package="$3"
    else
        last_package="$1"
    fi
    go_to_sources
    tar xf "$1.$2"
    cd $last_package
}

function rm_cd() {
    if [ -n "$last_package" ]; then
        go_to_sources
        rm -rf "$last_package"
    fi
}

log_file=/tmp/build.log

function build_log() {
    echo "$(formated_date) ($(whoami)) $1" >> $log_file
}

function pad() {
    [ $1 -gt 9 ] && echo $1 || echo "0"$1
}

function format_time() {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi

    sec=$(pad $sec)
    min=$(pad $min)
    hour=$(pad $hour)
    day=$(pad $day)
    echo "$day"d"$hour"h"$min"m"$sec"s
}

function formated_date() {
    echo $(date +%FT%H:%M:%S)
}

function start_timer() {
    start_time=$SECONDS
    timer_title="$1"
    build_log "($(format_time $start_time)) S $timer_title"
}

function end_timer() {
    if [ -n "$timer_title" ]; then
        end_time=$SECONDS
        elapsed="$(($end_time-$start_time))"
        build_log "($(format_time $elapsed)) F $timer_title"
        timer_title=""
    fi
}

function start_package() {
    start_timer "$1"
    tar_cd $2 $3 $4
}

function end_package() {
    rm_cd
    end_timer
}
EOF
