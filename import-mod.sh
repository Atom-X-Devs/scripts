#!/bin/bash
#
# Copyright (C) 2020 Pig <pig.priv@gmail.com>
# Copyright (C) 2021 Divyanshu-Modi <divyan.m05@gmail.com>
#
# Simple script for kernel imports
# Version v5
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
e='https://github.com/arter97/exfat-linux'
# private repository
repo='https://github.com/Atom-X-Devs/android_kernel_qcom_devicetree'
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
    clear
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

# Import dts
function dts_import() {
if [[ ! -d "$dir" ]]; then
    success "Note: Only usable by Atom-X-Devs"
    if [ $kv = '4.19' ]; then
        soc="sdm660/636"
    elif [ $kv = '5.4' ]; then
        soc="sm7325 (yupik)"
        repo=${repo}_5.4
    else
        error 'Invalid target kernel version,\
                 supported kernel versions are 4.19 and 5.4\
                 for sdm660 and sm7325 respectively'
    fi

    msg="ARM64: dts/qcom: Import vendor device tree overlay for $soc"
    $sa=$dir $repo main -m "$msg" && $cai
    success "Successfully imported DTS for $soc on $kv"
    exit 0
else
    error "DTS directory is already present."
fi
}

# Import exFAT
function exfat_import() {
if [[ ! -d "$dir" ]]; then
    success "Beginning exFAT import"

    msg="fs: Import exFAT driver"
    $sa=$dir $e master -m "$msg" && $cai
    success "Successfully imported exFAT" $cmd
    exit 0
else
    error "exFAT is already present"
fi
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
            mod=data-kernel
            prefix=data
        ;;
        7)
            mod=dataipa
            prefix=$mod
        ;;
        8)
            mod=display-drivers
            prefix=display
        ;;
        9)
            mod=video-driver
            prefix=video
        ;;
        10)
            dir='arch/arm64/boot/dts/vendor'
            dts_import
        ;;
        11)
            dir='fs/exfat'
            exfat_import
        ;;
        *)
            clear
            error "Invalid target input, aborting!"
        ;;
    esac

    if [ $num -lt '4' ]; then
        msg="staging: $mod: Import from"
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
    elif [ $num = '6' ]; then
        $rma/$mod $rm/$qc-$os/$mod
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
    6.data-kernel
    7.dataipa
    8.display-drivers
    9.video-driver
    10.device tree source
    11.exFAT driver
                    "

read -p "Target kernel module: " num
case $num in
    1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11)
    if [ $num -lt '10' ]; then
        read -p "Target tag / branch: " br
        read -p "Import (i) / Update (u): " option
        if [ $option != u ]; then
            read -p "Target cmd: merge (m) subtree (s) " cmd
        else
            cmd=m
        fi
    elif [ $num = '10' ]; then
        read -p "Target kernel version: " kv
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
        qcacld-3.0 | qca-wifi-host-cmn | fw-api | audio-kernel | camera-kernel | data-kernel | dataipa | display-drivers | video-driver | dts | exFAT)
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
