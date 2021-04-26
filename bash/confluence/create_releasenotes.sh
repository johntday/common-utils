#!/bin/bash
#
# install httpie:              https://snapcraft.io/http
# httpie doc:                  https://httpie.org/doc
# create atlassian API token:  https://confluence.atlassian.com/cloud/api-tokens-938839638.html
#
# Example
# ./create_releasenotes.sh -u <atlassian-username> -p <atlassian-api-token> -s HRP3 -a 647097183 -g /opt/lyonscg/sapcc-rlp -t1 sapcc-rlp-3.0.54 -t2 sapcc-rlp-3.0.55 -bn 30 -dn 15 -e DEV -d Y
#

### CONSTANTS ###
CONFLUENCE_BASE_URL="https://lyonscg.atlassian.net"
CONFLUENCE_REST_API="/wiki/rest/api/content"

### FUNCTIONS ###
usage()
{
		echo "usage: create_releasenotes -u atlassian-user -p atlassian-api-token -s atlassian-space -a ancestor-page-id -g git-repo-path -t1 tag1 -t2 tag2 -e env [optional parms]"
    echo "  u  = Atlassian username"
    echo "  p  = Atlassian API token"
    echo "  s  = Confluence space"
    echo "  a  = Ancestor (parent) Confluence page ID number.  New page will be a child of ancestor"
    echo "  g  = Local git repo absolute path"
    echo "  t1 = git Tag 1 or commit 1"
    echo "  t2 = git Tag 2 (after Tag1) or commit 2"
    echo "  e  = Deployment environment (DEV, STG, PRD)"
    echo "  bn = OPTIONAL Build number"
    echo "  dn = OPTIONAL Deployment number"
    echo "  b  = OPTIONAL Confluence base URL.  Default is https://lyonscg.atlassian.net"
    echo "  d  = OPTIONAL Test mode (Y, N). Default is N. When Y, display calculated variable values and will not create confluence page"
    echo "  h  = OPTIONAL help"
}

validate_input()
{
	if [ -z "$CONFLUENCE_USERNAME" ] || [ -z "$CONFLUENCE_PASSWORD" ] || [ -z "$GITDIR" ] ||
		 [ -z "$SPACEKEY" ] || [ -z "$PARENTPAGEID" ] || [ -z "$CONFLUENCE_BASE_URL" ] ||
		 [ -z "$TAG1" ] || [ -z "$TAG2" ] || [ -z "$ENV" ]
	then
			usage
			exit
	fi
}

page_content()
{
	PAGE_CONTENT="h1. Summary\n"
	PAGE_CONTENT="||Commit Hash||Author||Date||Commit Message||\n"

	GITCMD="$( cd ${GITDIR};git log ${TAG1}..${TAG2} --no-merges --date=local --pretty=tformat:'|%H|%aN <%aE>|%ad|%f|')"
	while IFS= read -r line
	do
		PAGE_CONTENT+="${line}\n"
	done < <(printf '%s\n' "$GITCMD")

	PAGE_CONTENT+="\n\n"
	PAGE_CONTENT+="h1. Metadata\n"
	PAGE_CONTENT+="# Excluding merges, commits between tags '${TAG1}' and '${TAG2}'\n"
	if [ ! -z "$BUILD_NUMBER" ]; then
		PAGE_CONTENT+="# Build Number ${BUILD_NUMBER}\n"
	fi
	if [ ! -z "$DEPLOY_NUMBER" ]; then
		PAGE_CONTENT+="# Deployment Number ${DEPLOY_NUMBER}\n"
	fi
}

payload()
{
PAYLOAD=$(cat <<EOF
{
    "title": "$(date '+%F %T') ${ENV} Release Notes",
    "type": "page",
    "space": {
        "key": "${SPACEKEY}"
    },
    "ancestors": [{"id": ${PARENTPAGEID}}],
    "body": {
        "wiki": {
            "value": "${PAGE_CONTENT}",
            "representation": "wiki"
        }
    }
}
EOF
)
}

print_input()
{
	echo "CONFLUENCE_USERNAME (-u)  = $CONFLUENCE_USERNAME"
	#echo "CONFLUENCE_PASSWORD (-p)  = $CONFLUENCE_PASSWORD"
	echo "SPACEKEY            (-s)  = $SPACEKEY"
	echo "PARENTPAGEID        (-a)  = $PARENTPAGEID"
	echo "GITDIR              (-g)  = $GITDIR"
	echo "TAG1                (-t1) = $TAG1"
	echo "TAG2                (-t2) = $TAG2"
	echo "ENV                 (-e)  = $ENV"
	echo "DISPLAY             (-d)  = $DISPLAY"
	echo "BUILD_NUMBER        (-bn) = $BUILD_NUMBER"
	echo "DEPLOY_NUMBER       (-dn) = $DEPLOY_NUMBER"
	echo "CONFLUENCE_BASE_URL (-b)  = $CONFLUENCE_BASE_URL"
	echo "PAGE_CONTENT              = $PAGE_CONTENT"
}

confluence_api()
{
	echo "${PAYLOAD}" | http -a ${CONFLUENCE_USERNAME}:${CONFLUENCE_PASSWORD} \
    POST ${CONFLUENCE_BASE_URL}${CONFLUENCE_REST_API}
}


### MAIN ###
while [ "$1" != "" ]; do
    case $1 in
        -u )                    shift
                                CONFLUENCE_USERNAME=$1
                                ;;
        -p )                    shift
                                CONFLUENCE_PASSWORD=$1
                                ;;
        -s )                    shift
                                SPACEKEY=$1
                                ;;
        -a )                    shift
                                PARENTPAGEID=$1
                                ;;
        -b )                    shift
                                CONFLUENCE_BASE_URL=$1
                                ;;
        -g )                    shift
                                GITDIR=$1
                                ;;
        -t1 )                   shift
                                TAG1=$1
                                ;;
        -t2 )                   shift
                                TAG2=$1
                                ;;
        -bn )                   shift
                                BUILD_NUMBER=$1
                                ;;
        -dn )                   shift
                                DEPLOY_NUMBER=$1
                                ;;
        -e )                    shift
                                ENV=$1
                                ;;
        -h )                    usage
                                exit
                                ;;
        -d )                    DISPLAY="Y"
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

validate_input

page_content

if [ "$DISPLAY" = "Y" ]; then
	print_input
fi

payload

if [ "$DISPLAY" != "Y" ]; then
	confluence_api
fi
