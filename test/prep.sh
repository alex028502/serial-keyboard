echo ----------------------- E2E PREP ----------------------
dev=$PWD/dev

rm -rf $dev
mkdir $dev

processes=""

function remember {
    processes="$processes $@"
}

function cleanup {
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

trap cleanup EXIT
