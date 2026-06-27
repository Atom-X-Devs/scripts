#!/usr/bin/env bash
# Copyright (c) 2026, Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>.

set -euo pipefail

kernel_root=$(pwd)

xxksu_dir="$HOME/xxksu"
kowsu_dir="$HOME/kowsu"

source_dir="$xxksu_dir/kernel"
target_dir="$kernel_root/drivers/kernelsu"

prep_xxksu_commit="4b11137eeb"

ded() {
	echo "Error: $*" >&2
	exit 1
}

update_repo() {
	local dir="$1"
	local url="$2"

	if [[ ! -d "$dir/.git" ]]; then
		echo "==> Cloning $(basename "$dir")"
		git clone "$url" "$dir"
		return
	fi

	echo "==> Updating $(basename "$dir")"
	git -C "$dir" fetch -q origin master
	git -C "$dir" reset --hard -q FETCH_HEAD
}

ensure_clean_tree() {
	[[ -d "$kernel_root/.git" ]] || ded "run from kernel source root"

	if [[ -n "$(git status --porcelain -- drivers/kernelsu)" ]]; then
		ded "drivers/kernelsu is not clean"
	fi
}

update_sources() {
	update_repo "$xxksu_dir" "https://github.com/backslashxx/KernelSU"
	update_repo "$kowsu_dir" "https://github.com/KOWX712/KernelSU"

	[[ -d $source_dir ]] || ded "$source_dir does not exist"
}

collect_metadata() {
	read -r xxksu_short xxksu_subject < <(
		git -C "$xxksu_dir" log -1 --format='%h %s'
	)

	xxksu_version=$(
		rg -o 'KSU_VERSION=[0-9]+' "$source_dir/Makefile" |
			head -n1 |
			cut -d= -f2
	)

	kowsu_version=$((30000 + $(git -C "$kowsu_dir" rev-list --count HEAD)))

	if ((xxksu_version > kowsu_version)); then
		final_version="$xxksu_version"
	else
		final_version="$kowsu_version"
	fi

	last_imported_hash=$(
		git log --format='%B' -- drivers/kernelsu |
			sed -n 's/^Commit HEAD: \([0-9a-f]\+\).*/\1/p' |
			head -n1
	)

	current_tree_version=""

	if [[ -f "$target_dir/Makefile" ]]; then
		current_tree_version=$(
			rg -o 'KSU_VERSION=[0-9]+' "$target_dir/Makefile" |
				head -n1 |
				cut -d= -f2 || true
		)
	fi
}

already_up_to_date() {
	[[ ${last_imported_hash:-} == "$xxksu_short" ]] &&
		[[ ${current_tree_version:-} == "$final_version" ]]
}

sync_driver() {
	echo "==> Syncing drivers/kernelsu"

	mkdir -p "$target_dir"

	rsync -a --delete --exclude='.*' "$source_dir"/ "$target_dir"/
}

patch_makefile() {
	# Update version
	sed -Ei \
		"s/(KSU_VERSION=)[0-9]+/\1${final_version}/g" \
		"$target_dir/Makefile"

	# Update compliance hash
	sed -Ei \
		"s/^# compliant to last upstream kernel change as of .*/# compliant to last upstream kernel change as of ${xxksu_short}/" \
		"$target_dir/Makefile"
}

create_commit() {
	git add drivers/kernelsu

	git commit -s \
		-m "drivers: kernelsu: Upstream to v${final_version}" \
		-m "Commit HEAD: ${xxksu_short} (\"${xxksu_subject}\")"
}

apply_prep_patch() {
	echo "==> Cherry-picking XXKSU additions"

	local cherry_output

	set +e
	cherry_output=$(git cherry-pick -n "$prep_xxksu_commit" 2>&1)
	set -e

	printf '%s\n' "$cherry_output"

	# Check if rerere has auto-resolved conflict
	if [[ $cherry_output == *"using previous resolution"* ]]; then
		echo "==> rerere resolved conflict"

		git add drivers/kernelsu
		git commit --amend --no-edit

		return
	fi

	# Now we check other unresolved conflicts
	if git ls-files -u | grep -q .; then
		ded "unresolved conflicts remain after cherry-pick"
	fi

	git add drivers/kernelsu

	if ! git diff --cached --quiet; then
		git commit --amend --no-edit
	fi
}

main() {
	ensure_clean_tree
	update_sources
	collect_metadata

	if already_up_to_date; then
		echo "drivers/kernelsu already up to date"
		echo "HEAD    : $xxksu_short"
		echo "VERSION : $final_version"
		exit 0
	fi

	sync_driver
	patch_makefile
	create_commit
	apply_prep_patch

	echo "==> Done"
	echo "HEAD    : $xxksu_short"
	echo "VERSION : $final_version"
}

main "$@"
