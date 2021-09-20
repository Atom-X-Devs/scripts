#!/bin/bash
#
# Copyright (C) 2020 Pig <pig.priv@gmail.com>
# Copyright (C) 2021 Divyanshu-Modi <divyan.m05@gmail.com>
#
# Simple script to import/update kernel modules
# Version v2
#

# Aliases
cai='git commit --amend --no-edit'
ci='git commit --no-edit'
ds='drivers/staging'
f='git fetch caf'
fn='FETCH_HEAD --no-edit'
mo='git merge --allow-unrelated-histories -s ours --no-commit FETCH_HEAD'
ms='git merge -X subtree'
os='opensource'
qc='qcom'
r='git read-tree --prefix'
rm='https://source.codeaurora.org/quic/la/platform/vendor'
rma='git remote add caf'
sa='git subtree add --prefix'
tp='techpack'
uf='-u FETCH_HEAD'
wl=$qc-$os/wlan

# COLORS
    R='\033[1;31m'
    G='\033[1;32m'
    Y='\033[1;33m'
    B='\033[1;34m'
    W='\033[1;37m'

error () {
    echo -e ""
    echo -e "$R Error! $W$1"
    echo -e ""
    exit 1
}

success () {
    echo -e ""
    echo -e "$G $1 $W"
    echo -e ""
}

# Read git cmd
function readcmd() {
    case $cmd in
        s)
            tag=$(echo '`DUMMY_TAG`' | sed s/DUMMY_TAG/$br/g)
            $f/$mod $br && $sa=$dir caf/$mod $br -m "$msg `echo $tag`" && $cai
        ;;
        m)
            if [ $option = 'u' ]; then
                $f/$mod $br && $ms=$dir $fn
            else 
                $f/$mod $br && $mo && $r=$dir $uf && $ci
            fi
        ;;
        *)
            error "Invalid target cmd, aborting!"
        ;;
    esac
}

# Indicate module directories
function indicatemodir() {
    case $num in
        1)
            mod=qcacld-3.0
        ;;
        2)
            mod=qca-wifi-host-cmn
        ;;
        3)
            mod=fw-api
        ;;
        4)
            mod=audio-kernel
            prefix=audio
        ;;
        5)
            mod=camera-kernel
            prefix=camera
        ;;
        6)
            mod=dataipa
            prefix=$mod
        ;;
        7)
            mod=display-drivers
            prefix=display
        ;;
        8)
            mod=video-driver
            prefix=video
        ;;
        *)
            clear
            error "Invalid target input, aborting!"
        ;;
    esac

    if [ $num -lt '4' ]; then
        msg="drivers: $mod: Import from"
        dir=$ds/$mod
    else
        msg="techpack: $mod: Import from"
        dir=$tp/$prefix
    fi
    process
}

# Add remote
function addremote() {
if [ "$(cat .git/config | grep $mod)" ]; then
    success "remote for target module ${mod} already present."
else
    if [ $num -lt '4' ]; then
        $rma/$mod $rm/$wl/$mod
    else
        $rma/$mod $rm/$os/$mod
    fi

    success "Add remote for target module ${mod} done."
fi
}

# Initialize
function init() {
echo "Available modules
    1.qcacld-3.0
    2.qca-wifi-host-cmn
    3.fw-api
    4.audio-kernel
    5.camera-kernel
    6.dataipa
    7.display-drivers
    8.video-driver
                    "

read -p "Target kernel module: " num
case $num in
    1 | 2 | 3 | 4 | 5 | 6 | 7 | 8)
        read -p "Target tag / branch: " br
        read -p "Import (i) / Update (u): " option
        if [ $option != u ]; then
            read -p "Target cmd: merge (m) subtree (s) " cmd
        else
            cmd=m
        fi
esac
indicatemodir
}

# Update/Import modules
function moduler() {
    if [ $1 = 'import' ]; then
        addremote
    fi
    case $mod in
        qcacld-3.0 | qca-wifi-host-cmn | fw-api | audio-kernel | camera-kernel |  dataipa | display-drivers | video-driver)
        readcmd
        success "Import from target ${br} for target ${mod} done."
    esac
}

# Process import or update
function process() {
    case $option in
        i)
            moduler import
        ;;
        u)
            moduler 
        ;;
        *)
            error "Invalid target option, aborting!"
        ;;
    esac
}

init
