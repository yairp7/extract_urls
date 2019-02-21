#!/bin/bash

if [ -z "$1" ] 
then
	echo "[-] Must provide an input file"
	echo "[-] Syntax: extract_urls.sh <input> <output>"
	exit 1
fi

if [ ! -z "$2" ]; then
	REPORT=$2
fi

FILENAME=$1
OUTPUT='output.txt'

function process_binary {
	urls=$(rabin2 -z $1 | egrep -w 'https?://[^ ]+')
	if [ ! -z "${urls}" ]; then
		{ printf "@${1}[binary]: \n"; rabin2 -z $1 | egrep -w 'https?://[^ ]+'; } >> $2
	fi
}

function process_plaintext {
	urls=$(strings $1 | egrep -o 'https?://[^ ]+')
	if [ ! -z "${urls}" ]; then
		{ printf "@${1}[plaintext]: \n"; strings $1 | egrep -o 'https?://[^ ]+'; } >> $2
	fi
}

function is_binary() {
	filetype=$(file -b --mime-type $1 | sed 's|/.*||')
	if [[ $filetype == *"application"* ]]; then
		echo "bin"
	else
		echo "txt"
	fi
}

function process {
	result=$(is_binary $1)
		if [[ $result == *"bin"* ]]; then
			process_binary $1 $2
		else
			process_plaintext $1 $2
		fi
}

echo "### Urls Found:" > $OUTPUT

# Check if APK file
if [[ $FILENAME == *".apk"* ]]; then
	echo "[+] APK file found, extracting..."
	if [[ ! -d "./tmp" ]]; then
		mkdir ./tmp
	fi
	
	unzip -o -q "${FILENAME}" -d "./tmp/unzip_result"
	apktool --quiet -f d "${FILENAME}" -o "./tmp/apktool_result"

	fileCount=0
	IFS=$'\n' files=( $(find "./tmp" -type f) )
	for f in "${files[@]}"; do
		fileCount=$(( fileCount+1 ))
		process $f $OUTPUT
    	echo -ne "[+] Files Checked: [${fileCount} / ${#files[@]}]\r";
	done
	echo -e "\r"
	echo "[+] Done."
	rm -rd "./tmp"
else
	echo "[+] Checking file..."
	
	process $FILENAME $OUTPUT
fi
# echo "[+] Cleaning duplicated urls..."
# python remove_duplicates.py $OUTPUT $REPORT
if [ -z "$REPORT" ]; then
	cat $OUTPUT
else
	cp $OUTPUT $REPORT
fi
rm $OUTPUT