#! /bin/bash

# exit script on errors
set -e

show_help ()
{
	echo "RenameFiles.sh"
	echo "         -h | --help | ?"
	echo "         -p | --prefix"
	echo "         -s | --suffix"
	echo "         -m | --match"
	echo "         -r | --recurse"
	echo "         --replace"
}

# For now only works in current directory

# options
while [[ $1 == -* ]]; do
    case "$1" in
      -h|--help|-\?) show_help; exit 0;;
      -p|--prefix) if (($# > 1)); then
		  prefix=$2; shift 2
          else
            echo "--prefix requires an argument" 1>&2
            exit 1
          fi ;;
      -s|--suffix) if (($# > 1)); then
		  suffix=$2; shift 2
          else
            echo "--suffix requires an argument" 1>&2
            exit 1
          fi ;;
      -m|--match) if (($# > 1)); then
		  match=$2; shift 2
          else
            echo "--match requires an argument" 1>&2
            exit 1
          fi ;;
      --replace) if (($# > 1)); then
		  replace=$2; shift 2
          else
            echo "--replace requires an argument" 1>&2
            exit 1
          fi ;;
      -r|--recurse) shift; recurse=1;;
      --) shift; break;;
      -*) echo "invalid option: $1" 1>&2; show_help; exit 1;;
    esac
done

# Checks
if [[ -z "$prefix" && -z "$suffix" && -z "$replace" ]]; then
   	echo "at least one of --prefix, --suffix, or --replace options required" 1>&2
	exit 1
fi
if [[ -z $match && ! -z "$replace" ]]; then
	echo "--replace requires --match '<regex>'" 1>&2
	exit 1
fi

prompt_is_yes ()
{
	unset REPLY
	local _resultvar=$1
	msg=$2;
	if [ -n "$msg" ]; then echo "$msg"; fi;
	until [ -n "$REPLY" ]
	do
		read
		if [[ $REPLY == "y" ]]; then
			eval $_resultvar=1
		elif [[ $REPLY == "n" ]]; then
			eval $_resultvar=0
		else
			echo "please answer y/n [n]? "
			read
		fi
	done
}

prompt_yes_to_continue ()
{
	unset REPLY
	msg=$1;
	flist=$2;
	if [ -n "$msg" ]; then echo "$msg"; fi;
	until [ -n "$REPLY" ]
	do
		read
		if [[ $REPLY == "y" ]]; then
			continue
		elif [[ $REPLY == "n" ]]; then
			echo 'no files renamed'
			exit
		else
			prompt_yes_to_continue 'continue? please answer [y/n]?'
		fi
	done
}

if [[ $recurse == 1 ]]; then
	while IFS= read -r -d $'\0' file; do
		files[i++]="$file"
	done < <(find . -name '*' -type f -print0)
else
	while IFS= read -r -d $'\0' file; do
		files[i++]="$file"
	done < <(find . -maxdepth 1 -name '*' -type f -print0)
fi

# Match on the name without the path
if [ ! -z "$match"  ]; then
	for i in "${!files[@]}"; do
		fname=${files[$i]}
		name_nopath="${fname##*/}"

		if [[ $name_nopath =~ $match ]]; then
			tmp+=("${files[$i]}")
		fi
	done
	files=("${tmp[@]}")
fi

echo "Files to be renamed are: "
for fname in "${files[@]}"; do
	echo $fname
done

# here for extra safety I should require type_yes_to_continue so that user needs to type 'yes'
prompt_yes_to_continue 'continue [y/n]?'
echo

for fname in "${files[@]}"; do

	# these generally work well when files have extensions, not so much when they don't
	# dir="${fname%/*}"
	# name="${fname##*/}"
	# base="${fname%.*}"
	# ext="${fname##*.}"
	# base_nopath="${base##*/}"

	# Does file have an extension? Can also be a hidden file with or w/o ext
	dir="${fname%/*}"
	if [[ $fname =~ /.{0,}[^./]+\.[^./]+$ ]]; then
		ext="${fname##*.}"
		ext=".$ext"
		base_nopath=`basename "$fname" "$ext"`
	else 
		ext=''
		base_nopath=`basename "$fname"`
	fi

	if [ ! -z "$prefix"  ]; then
		newname="$dir/$prefix$base_nopath$ext"
	elif [ ! -z "$suffix"  ]; then
		newname="$dir/$base_nopath$suffix$ext"
	fi

	if [ ! -z "$replace" ]; then
		base_nopathext="$base_nopath$ext"
		replacedname=`echo $base_nopathext | sed -r "s/$match/$replace/"`
		newname="$dir/$replacedname"
	fi

	prompt_is_yes rename_file "Rename '$fname'  to  '$newname' [y/n]?'"

	if [[ $rename_file == 1 ]]; then
		mv "$fname" "$newname"
	else
		echo "name not changed: '$fname'"
		echo
	fi
done

exit

# Examples

./RenameFiles.sh --prefix 'yo buddy ' --match '\.sh$'
./RenameFiles.sh --match '([a-z]{2,2}).*(o{2,})([^.]*)$' --replace '\1 found 2 letters \2 and multiple o \3'
