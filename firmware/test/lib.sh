# include this to create the fake serial directory, add function for starting
# fake tty, and exit trap fn to clean up processes - this is here because the
# e2e tests duplicate a lot of stuff in the firmware tests

dev=./dev

rm -rf $dev
mkdir $dev

processes=""

function remember {
    processes="$processes $@"
}

function _cleanup {
    echo
    echo --------------------- CLEAN UP ------------------------
    echo background process list
    echo $processes | xargs -n2 echo
    ids=$(echo $processes | xargs -n2 echo | awk '{ print $2 }')
    echo kill $ids
    kill $ids || echo nothing to clean-up
    rm -rfv $dev
    echo -------------------------------------------------------
    echo
}
