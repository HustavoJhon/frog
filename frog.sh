#!/usr/bin/env bash

#colors
#bold="(tput bold)"
magenta="\033[1;35m"
green="\033[1;32m"
white="\033[1;37m"
blue="\033[1;34m"
red="\033[1;31m"
black="\033[1;40;30m"
yellow="\033[1;33m"
cyan="\033[1;36m"
reset="\033[0m"
bgyellow="\033[1;43;33m"
bgwhite="\033[1;47;37m"
c0=${reset}
c1=${magenta}
c2=${green}
c3=${white}
c4=${blue}
c5=${red}
c6=${yellow}
c7=${cyan}
c8=${black}
c9=${bgyellow}
c10=${bgwhite}

# Get the kernel
# This will decide the further actionsvand command usages as bsd and gnu tools even with same name are DIFFERENT.
kernel=$(uname -o)

# Setup fonts
setup_fonts() {
	if [ "$kernel" != Android ]; then
		if ! fc-match :family='Material' 2>/dev/null | grep -Eq '^Material.ttf' ; then
			mkdir -p "$HOME/.local/share/fonts"
			cp ttf-material-design-icons/* "$HOME/.local/share/fonts"
			fc-cache -vf &>/dev/null
		fi
	fi
}
# Get the init
get_init() {
	if [ "$kernel" = "Android" ]; then
		echo 'init.rc'
	elif [ "$kernel" = "Darwin" ]; then
		echo 'launchd'
	elif pidof -q systemd; then
		echo 'systemd'
	elif [ -f '/sbin/openrc' ]; then
		echo 'openrc'
	elif [ -f '/sbin/dinit' ]; then
		echo 'dinit'
	else
		cut -d ' ' -f 1 /proc/1/comm
	fi
}

# Get count of packages installed
get_pkg_count() {
	package_managers=('xbps-install' 'apk' 'port' 'apt' 'pacman' 'nix' 'dnf' 'rpm' 'emerge' 'eopkg')
	for package_manager in "${package_managers[@]}"; do
		if command -v "$package_manager" 2>/dev/null >&2; then
			case "$package_manager" in
			xbps-install) xbps-query -l | wc -l ;;
			apk) apk search | wc -l ;;
			apt) if [ "$kernel" != "Darwin" ]; then 
					echo $(($(apt list --installed 2>/dev/null | wc -l) - 1))
				 else
					echo 0
				 fi
				 ;;
			pacman) pacman -Q | wc -l ;;
			nix) nix-env -qa --installed '*' | wc -l ;;
			dnf) dnf list installed | wc -l ;;
			rpm) rpm -qa | wc -l ;;
			emerge) qlist -I | wc -l ;;
			port) port installed 2>/dev/null | wc -l | awk 'NR==1{print $1}' ;;
			eopkg) eopkg li | wc -l ;;
			esac

			# if a package manager is found return from the function
			return
		fi
	done
	echo 0
}

# Get count of snaps installed
get_snap_count() {
	if command -v snap 2>/dev/null >&2; then
		count=$(snap list | wc -l)

		# snap list shows a header line
		echo $((count - 1))

		return
	fi

	echo 0
}

# Get count of flatpaks installed
get_flatpak_count() {
	if command -v flatpak 2>/dev/null >&2; then
		flatpak list | wc -l
		return
	fi

	echo 0
}

#Get count of brews(formulas + casks) installed
get_brew_count() {
	if command -v brew 2>/dev/null >&2; then
		brew list | wc -l | awk 'NR==1{print $1}'
		return
	fi

	echo 0
}

# Get package information formatted
get_package_info() {
	pkg_count=$(get_pkg_count)
	snap_count=$(get_snap_count)
	flatpak_count=$(get_flatpak_count)
	brew_count=$(get_brew_count)

	if [ "$pkg_count" -ne 0 ]; then
		echo -n "$pkg_count"
		if [ "$snap_count" -ne 0 ]; then
			echo -n " ($snap_count snaps"
			if [ "$flatpak_count" -ne 0 ]; then
				echo ", $flatpak_count flatpaks)"
			else
				echo ")"
			fi
		elif [ "$flatpak_count" -ne 0 ]; then
			echo " ($flatpak_count flatpaks)"
		elif [ "$brew_count" -ne 0 ]; then
			cask_count=$(brew list --casks | wc -l | awk 'NR==1{print $1}')
			formula_count=$(brew list --formula | wc -l | awk 'NR==1{print $1}')
			echo ", $brew_count brews ($formula_count formulas & $cask_count casks)"
		else
			echo ""
		fi
	elif [ "$snap_count" -ne 0 ]; then
		echo -n "$snap_count snaps"

		if [ "$flatpak_count" -ne 0 ]; then
			echo ", $flatpak_count flatpaks"
		else
			echo ""
		fi
	elif [ "$flatpak_count" -ne 0 ]; then
		echo "$flatpak_count flatpaks"
	elif [ "$brew_count" -ne 0 ]; then
		cask_count=$(brew list --casks | wc -l | awk 'NR==1{print $1}')
		formula_count=$(brew list --formula | wc -l | awk 'NR==1{print $1}')
		echo "$brew_count brews ($formula_count formulas & $cask_count casks)"
	else
		echo "Unknown"
	fi
}

# Get distro name
get_distro_name() {
	if [ "$kernel" = "Android" ]; then
		echo 'Android'
	elif [ "$kernel" = "Darwin" ]; then
		echo "macOS $(uname) $(sw_vers -productVersion)"
	else
		awk -F '"' '/PRETTY_NAME/ { print $2 }' /etc/os-release
	fi
}

# Get root partition space used
get_storage_info() {
	if [ "$kernel" = Android ]; then
		_MOUNTED_ON="/data"
		_GREP_ONE_ROW="$(df -h | grep ${_MOUNTED_ON})"
		_SIZE="$(echo "${_GREP_ONE_ROW}" | awk '{print $2}')"
		_USED="$(echo "${_GREP_ONE_ROW}" | awk '{print $3}')"
		echo "$(head -n1 <<<"${_USED}")B / $(head -n1 <<<"${_SIZE}")B"
	elif [ "$kernel" = "Darwin" ]; then
		total_size=$(df -Hl | grep -w "/" | awk '{print $2}')
		free_size=$(df -Hl | grep -w "/" | awk '{print $4}')
		used_size=$(( ${total_size::-1} - ${free_size::-1} ))
		echo "${used_size}G / $total_size"
	else
		df -h --output=used,size / | awk 'NR == 2 { print $1" / "$2 }'
	fi
}

# Get Memory usage
get_mem() {
	if [ "$kernel" = "Darwin" ]; then
		total_mem=$(($(sysctl -a | awk '/hw./' | awk '/mem/' | awk 'NR==1{print $2}') / 2**20 ))
		used_mem=$(vm_stat | grep -E "Pageouts:" | awk 'NR==1{print $2}')
		echo "${used_mem::-1} / $total_mem MB"
	else
		free --mega | awk 'NR == 2 { print $3" / "$2" MB" }'
	fi
}

# Get uptime
get_uptime() {
	if [ "$kernel" = "Darwin" ]; then
		up=$(uptime | awk 'NR==1{print $3}')
		echo " ${up::-1}"
	else
		uptime -p | sed 's/up//'
	fi
}

# Get DE/WM
# Reference: https://github.com/unixporn/robbb/blob/master/fetcher.sh
get_de_wm() {
	wm="${XDG_CURRENT_DESKTOP#*:}"
	[ "$wm" ] || wm="$DESKTOP_SESSION"

	# for most WMs
	[ ! "$wm" ] && [ "$DISPLAY" ] && command -v xprop >/dev/null && {
		id=$(xprop -root -notype _NET_SUPPORTING_WM_CHECK 2>/dev/null)
		id=${id##* }
		wm=$(xprop -id "$id" -notype -len 100 -f _NET_WM_NAME 8t 2>/dev/null | grep '^_NET_WM_NAME' | cut -d\" -f 2)
	}

	# for non-EWMH WMs
	[ ! "$wm" ] || [ "$wm" = "LG3D" ] && {
		wms=('sway' 'kiwmi' 'wayfire' 'sowm' 'catwm' 'fvwm' 'dwm' '2bwm' 'monsterwm' 'tinywm' 'xmonad')
		for current_wm in "${wms[@]}"; do
			if pgrep -x "$current_wm" 2>/dev/null >&2; then
				wm="${current_wm}";
				break
			fi
		done
	}

	echo "${wm:-unknown}"
}

setup_fonts

echo "               "

if [ "$kernel" = Android ]; then
	echo -e "               ${c5}phone${c3}  $(getprop ro.product.brand) $(getprop ro.product.model)"
fi

# os
# echo -e "               ${c1}󰊠 ${c3}  $(get_distro_name) $(uname -m)"

# kernel
# echo -e "               ${c2}󰊠 ${c3}  |$(uname -r)"

# pkgs
# echo -e "     ${c3}•${c8}_${c3}•${c0}       ${c7}󰮯 ${c3}|$(get_package_info)"

#sh
# echo -e "     ${c8}${c0}${c9}oo${c0}${c8}|${c0}       ${c4}󰊠 ${c3}|${SHELL##*/}"

#ram
# echo -e "    ${c8}/${c0}${c10} ${c0}${c8}'\'${c0}      ${c6}󰊠 ${c3}|$(get_mem)"

#init
# echo -e "   ${c9}(${c0}${c8}\_;/${c0}${c9})${c0}      ${c1}󰊠 ${c3}|$(get_init)"

# de/wm
# if [ -n "$DISPLAY" ]; then
#	echo -e "               ${c2}󰊠 ${c3}  $(get_de_wm)"
# fi

# up time
# echo -e "               ${c7}󰊠 ${c3}   $(get_uptime)"

# disk
# echo -e "               ${c6}󰊠 ${c3}|$(get_storage_info)"

# ================================================================================
clear # clear screen

echo -e "   ${c7}󰌠 ${c7}         ${c4}󰏘 ${c4}    ${c3}${c6}󰮯 |$(get_distro_name) $(uname -m)"
echo -e "${c3}   _        @..@    ${c3}${c5}󰊠 |$(uname -r)"
echo -e "${c3} ('v')     (----)   ${c3}${c4}󰊠 |$(get_de_wm)"
echo -e "${c3}//-=-\\    ( >__< )  ${c3}${c7}󰊠 |${SHELL##*/}"
echo -e "${c3}(\_=_/)   ^^ ~~ ^^  ${c3}${c1}󰊠 |${USER}${c5}" 

# if [ "$kernel" != Android ] && [ "$kernel" != Darwin ]; then
#	echo -e "        ${c6}󰻀 ${c6}$"
# fi

binary="01001001 00100000 01001100 01001111 01010110 01000101 00100000 01000111 01001001 01000001"

binary_array=($(echo $binary | tr -d ' ' | sed 's/.\{8\}/& /g'))

echo -n "·····" 

for byte in "${binary_array[@]}"; do
    decimal_value=$((2#$byte))
    printf "\\$(printf '%03o' "$decimal_value")"
done

echo "·····"