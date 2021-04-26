#!/bin/bash
# PURPOSE: create gensrc directory for all projects to avoid errors in eclipse
# EXAMPLE
# ./eclipse_gensrc.sh -t -g /opt/lyonscg/sapcc-rlp
#

### CONSTANTS ###
GENSRCOUT="gensrc.txt"

### FUNCTIONS ###
usage()
{
    echo "usage: eclipse_gensrc -t -g git-project-home"
    echo "  g = git project home (e.g. '/opt/lyonscg/sapcc-rlp')"
    echo "  t = test mode.  Do not create gensrc directories"
    echo "  h = display help"
}

validate_input()
{
	if [ -z "$GITDIR" ]; then
		usage
		exit
	else
		[ ! -d "$GITDIR" ] && echo "Directory '$GITDIR' does not exist" && exit
	fi
}

### MAIN ###
while [ "$1" != "" ]; do
    case $1 in
        -g )                    shift
                                GITDIR=$1
                                ;;
        -h )                    usage
                                exit
                                ;;
        -t )                    TEST="Y" && echo "Test mode"
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

validate_input

cd "$GITDIR"

grep -rl -e 'gensrc' --include ".classpath" . | sed 's/\.classpath$//g' > "$GENSRCOUT"

declare -i cnt=0

if [ TEST = "Y" ]; then
	echo "Test mode"
	cnt=$(cat $GENSRCOUT | wc -l)
else
	while IFS= read -r line || [[ -n "$line" ]]; do
	    mkdir -p  "$line/gensrc"
	    ((cnt+=1))
	done < "$GENSRCOUT"
fi

echo "Line Count $cnt"
echo "Finished"
