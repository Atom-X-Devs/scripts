#!/bin/bash
#
# Copyright (C) 2020 Pig <pig.priv@gmail.com>
#
# Simple script to import/update kernel modules
# Version 0.2
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
uf='-u FETCH_HEAD'
wl=$qc-$os/wlan
echo -e "Available modules:\n1.qcacld-3.0\n2.qca-wifi-host-cmn\n3.fw-api\n4.opensource/audio-kernel"
read -p "The name of kernel module u want: " num
case $num in 
    1|2|3|4)
    read -p "The git cmd u want to use: merge (m) / subtree (s) " cmd
    read -p "The tag/br of module: " br
    read -p "Import (i) / Update (u)): " option
esac

if [ $num = '1' ]; then
    mod=qcacld-3.0
    dir=$ds/$mod
    elif [ $num = '2' ]; then
    mod=qca-wifi-host-cmn
    dir=$ds/$mod
    elif [ $num = '3' ]; then
    mod=fw-api
    dir=$ds/$mod
    elif [ $num = '4' ]; then
    mod=opensource/audio-kernel
    dir=techpack/audio
    else echo "Invalid input, aborting!"
fi

case $option in
    import | i)
        if [ $num -ne '4' ]; then
        $rma/$mod $rm/$wl/$mod
        else $rma/$mod $rm/$mod
        fi
        echo "Add remote for module" $mod "done."
        case $mod in
            qcacld-3.0 | qca-wifi-host-cmn | fw-api | opensource/audio-kernel)
            if [ $cmd = 's' ]; then
            $f/$mod $br && $sa=$dir caf/$mod $br && $cai
            elif [ $cmd = 'm' ]; then
            $f/$mod $br && $mo && $r=$dir $uf && $ci
            else echo "Invalid cmd, aborting!"
            fi
            ;;
            esac
            echo "Import from" $br "for" $mod "done."
            ;;
        update | u)
        case $mod in
            qcacld-3.0 | qca-wifi-host-cmn | fw-api | opensource/audio-kernel)
                $f/$mod $br && $ms=$dir $fn
                echo "Update to "$br "for module "$mod "done."
        esac
        ;;
        *)
            echo "Invalid option, aborting!"
        ;;
esac
