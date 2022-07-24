#!/bin/bash
#

TMP_FILE=$(mktemp /tmp/mcl5.XXXXXXXX)

git --version 2>/dev/null 1>/dev/null
IS_GIT_AVAILABLE=$?
if [ $IS_GIT_AVAILABLE -ne 0 ]; then
	echo "Please install git!\n\n"
fi

`git log --pretty="%an" 1>$TMP_FILE 2>/dev/null`
IS_GIT_REPO=$?
if [ $IS_GIT_REPO -ne 0 ]; then
	echo "You have to be inside a git repo to update CONTRUBUTOR_LIST.txt\n\n"
fi

# Edit names here:
sed -i 's/nikolaus-albinger/Niklp/g' $TMP_FILE

cat $TMP_FILE | sort | uniq >../mods/HUD/mcl_credits/CONTRUBUTOR_LIST.txt
