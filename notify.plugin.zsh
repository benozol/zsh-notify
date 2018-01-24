# vim: set nowrap filetype=zsh:
# 
# See README.md.
#
fpath=($fpath $(dirname $0:A))

zstyle ':notify:*' resources-dir $(dirname $0:A)/resources
zstyle ':notify:*' parent-pid $PPID

# Notify an error with no regard to the time elapsed (but always only
# when the terminal is in background).
function notify-error {
    notify-if-background error < /dev/stdin &!
}

# Notify of successful command termination, but only if it took at least
# 30 seconds (and if the terminal is in background).
function notify-success() {
    local now diff start_time message command_complete_timeout

    start_time=$1
    message="$2"

    zstyle -s ':notify:' command-complete-timeout command_complete_timeout \
        || command_complete_timeout=30

    ((diff = $(date +%s) - $start_time))
    if (( $diff > $command_complete_timeout )); then
        notify-if-background success <<< "$message" &!
    fi
}

function get-my-message() {
    local start_time last_status diff time suff
    start_time=$1
    last_status=$2
    ((diff = $(date +%s) - $start_time))
    if [ "$diff" -lt 60 ]; then
        time="$diff seconds"
    elif [ "$diff" -lt 3600 ]; then
        time="$(printf '%02d:%02d minutes' $(($diff/60)) $(($diff%60)))"
    else
        time="$(printf '%02d:%02d:%02d hours' $((($diff/3600))) $((($diff/60)%60)) $(($diff%60)))"
    fi
    [ "$last_status" -gt 0 ] && suff=" (status: $last_status)"
    echo "'$last_command' exited at $(date +%H:%M) after $time$suff"
}

# Notify about the last command's success or failure.
function notify-command-complete() {
    last_status=$?
    message="$(get-my-message $start_time $last_status)"
    if [[ $last_status -gt "0" ]]; then
        echo $message|notify-error
    elif [[ -n $start_time ]]; then
        notify-success "$start_time" "$message"
    fi
    unset last_command start_time last_status
}

function store-command-stats() {
    last_command=$1
    start_time=`date "+%s"`
}

if [[ -z "$PPID_FIRST" ]]; then
  export PPID_FIRST=$PPID
fi

if [ -n "$DISPLAY" ]; then
    autoload add-zsh-hook
    autoload -U notify-if-background
    add-zsh-hook preexec store-command-stats
    add-zsh-hook precmd notify-command-complete
fi
