#!/bin/bash
# Copyright (C) 2022 Divyanshu-Modi <divyan.m05@gmail.com>
# based on <pig.priv@gmail.com> module importer

R='\033[1;31m'
G='\033[1;32m'
W='\033[1;37m'

echo -e "$G                 ___   __                 _  __     "
echo -e "$G                /   | / /_____  ________ | |/ /     "
echo -e "$G               / /| |/ __/ __ \/ __  __ \|   /      "
echo -e "$G              / ___ / /_/ /_/ / / / / / /   |       "
echo -e "$G             /_/  |_\__/\____/_/ /_/ /_/_/|_|       "
echo -e "$G           __  ___ ___  ____  __  __ _    ______    "
echo -e "$G          /  |/  / __ \/ __ \/ / / / /   / ____/    "
echo -e "$G         / /|_/ / / / / / / / / / / /   / __/       "
echo -e "$G        / /  / / /_/ / /_/ / /_/ / /___/ /___       "
echo -e "$G       /_/  /_/\____/_____/\____/_____/_____/       "
echo -e "$G     ______  _______  ____  ____  ________________  "
echo -e "$G    /  _/  |/  / __ \/ __ \/ __ \/_  __/ ____/ __ \ "
echo -e "$G    / // /|_/ / /_/ / / / / /_/ / / / / __/ / /_/ / "
echo -e "$G  _/ // /  / / ____/ /_/ / _, _/ / / / /___/ _, _/  "
echo -e "$G /___/_/  /_/_/    \____/_/ |_| /_/ /_____/_/ |_|   "
echo -e "$W"

error()
{
	clear
	echo -e ""
	echo -e "$R Error! $W" "$@"
	echo -e ""
	exit 1
}

success()
{
	echo -e ""
	echo -e "$G" "$@" "$W"
	echo -e ""
}

# Commonised Importer
importer()
{
	MTD=$1
	DIR=$2
	REPO=$3
	TAG=$4
	if [[ "$MTD" == MERGE || "$MTD" == UPDATE ]]; then
		git fetch "$REPO" "$TAG"
	fi
	case "$MTD" in
		SUBTREE)
			MSG=$5
			git subtree add --prefix="$DIR" "$REPO" "$TAG" -m "$MSG"
			git commit --amend --no-edit
			;;
		MERGE)
			git merge --allow-unrelated-histories -s ours --no-commit FETCH_HEAD
			git read-tree --prefix="$DIR" -u FETCH_HEAD
			git commit --no-edit
			;;
		UPDATE)
			git merge -X subtree="$DIR" FETCH_HEAD --no-edit
			;;
	esac
}

# Import dts
dts_import()
{
	if [[ ! -d $dir ]]; then
		repo='https://github.com/Atom-X-Devs/android_kernel_qcom_devicetree'
		if [ "$kv" = '4.19' ]; then
			soc="sdm660/636"
		elif [ "$kv" = '5.4' ]; then
			soc="sm7325 (yupik)"
			repo=${repo}_5.4
		else
			error 'Invalid target kernel version,\
				 supported kernel versions are 4.19 and 5.4\
				 for sdm660 and sm7325 respectively'
		fi

		msg="ARM64: dts/qcom: Import vendor device tree overlay for $soc"
		importer "SUBTREE" "arch/arm64/boot/dts/vendor" "$repo" main "$msg"
		success "Successfully imported DTS for $soc on $kv"
	else
		error "DTS directory is already present."
	fi

	exit 0
}

# Import exFAT
exfat_import()
{
	if [[ ! -d $dir ]]; then
		importer "SUBTREE" "fs/exfat" https://github.com/arter97/exfat-linux master "fs: Import exFAT driver"
		success "Successfully imported exFAT" "$cmd"
	else
		error "exFAT is already present"
	fi

	exit 0
}

# Import Kprofiles
kprofiles_import()
{
	if [[ ! -d $dir ]]; then
	    msg="drivers/misc: Introduce KernelSpace Profile Modes"
		importer "SUBTREE" "drivers/misc/kprofiles" https://github.com/dakkshesh07/Kprofiles main "$msg"
		success "Successfully imported Kprofiles" "$cmd"
	else
		error "Kprofiles is already present"
	fi

	exit 0
}

# Read git cmd
readcmd()
{
	case $cmd in
		s)
			msg1=$(echo '`DUMMY_TAG`' | sed s/DUMMY_TAG/"$br"/g)
			importer "SUBTREE" "$dir" clo/"$mod" "$br" "$msg from $msg1"
			;;
		m)
			if [ "$option" = 'u' ]; then
				importer "UPDATE" "$dir" clo/"$mod" "$br"
			else
				importer "MERGE" "$dir" clo/"$mod" "$br"
			fi
			;;
		*)
			error "Invalid target cmd, aborting!"
			;;
	esac
}

# Add remote
addremote()
{
	if [ "$num" -lt '4' ]; then
		url=qcom-opensource/wlan/$mod
	elif [ "$num" = '6' ]; then
		url=qcom-opensource/$mod
	elif [ "$num" = '7' ] || [ "$num" = '8' ]; then
		url=qcom/opensource/$mod
	else
		url=opensource/$mod
	fi
	git remote add clo/"$mod" https://git.codelinaro.org/clo/la/platform/vendor/"$url".git

	success "Add remote for target module ${mod} done."
}

# Update/Import modules
moduler()
{
	if ! grep -q "$mod" .git/config; then
		addremote
	fi
	if [[ -d $dir && "$option" == "u" ]]; then
		cmd=m
	fi
	readcmd

	if [[ ! $(git diff HEAD~) ]]; then
		git reset -q --hard HEAD~
		success "HEAD resetted b'cuz empty commit for ${br}, ${mod}."
	else
		success "Import from target ${br} for target ${mod} done."
	fi
}

# Indicate module directories
indicatemodir()
{
	if [[ $br == "" ]]; then
		error "tag not defined"
	fi

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
			mod=datarmnet
			prefix=$mod
			;;
		8)
			mod=datarmnet-ext
			prefix=$mod
			;;
		9)
			mod=dataipa
			prefix=$mod
			;;
		10)
			mod=display-drivers
			prefix=display
			;;
		11)
			mod=video-driver
			prefix=video
			;;
		12)
			dts_import
			;;
		13)
			exfat_import
			;;
		14)
			kprofiles_import
			;;
		*)
			clear
			error "Invalid target input, aborting!"
			;;
	esac

	if [ "$num" -lt '4' ]; then
		msg="staging: $modules: Import"
		dir="drivers/staging/$mod"
	else
		msg="techpack: $modules: Import"
		dir="techpack/$prefix"
	fi
	moduler
}

# Initialize
init()
{
	COLUMNS=45
	PS3="Select a module: "
	options=("qcacld-3.0" "qca-wifi-host-cmn" "fw-api" "audio-kernel"
		"camera-kernel" "data-kernel" "datarmnet" "datarmnet-ext"
		"dataipa" "display-drivers" "video-driver" "device tree source" "exFAT driver" "kprofiles")
	select modules in "${options[@]}"; do
		num=$REPLY
		case $num in
			1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14)
				if [ "$num" -le '11' ]; then
					if [[ $br == "" ]]; then
						read -rp "Target tag / branch: " br
					fi
					read -rp "Import (i) / Update (u): " option
					if [ "$option" != u ]; then
						read -rp "Target cmd: merge (m) subtree (s) " cmd
					else
						cmd=m
					fi
				elif [[ "$num" == "12" ]]; then
					read -rp "Target kernel version: " kv
				fi
				indicatemodir
				break
				;;
			*)
				break
				;;
		esac
	done
}

init
