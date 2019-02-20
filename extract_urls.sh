#!/bin/bash

if [ -z "$1" ] 
then
	echo "[-] Must provide an input file"
	echo "[-] Syntax: extract_urls.sh <input> <output>"
	exit 1
fi

if [ -z "$2" ] 
then
	echo "[-] Must provide an output file"
	echo "[-] Syntax: extract_urls.sh <input> <output>"
	exit 1
fi

FILENAME=$1
OUTPUT='output.txt'
REPORT=$2

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

# Check if APK file
if [[ $FILENAME == *"apk"* ]]; then
	echo "[+] APK file found, extracting..."
	if [[ ! -d "./tmp" ]]; then
		mkdir ./tmp
	fi
	
	unzip -o -q "${FILENAME}" -d "./tmp/unzip_result"
	apktool --quiet -f d "${FILENAME}" -o "./tmp/apktool_result"

	# TMP
	rm -rf ./tmp/unzip_result/res
	rm -rf ./tmp/apktool_result/res
	# END TMP

	echo "### Urls Found:" > $OUTPUT

	fileCount=0
	IFS=$'\n' files=( $(find "./tmp" -type f) )
	for f in "${files[@]}"; do
		fileCount=$(( fileCount+1 ))
		result=$(is_binary $f)
		if [[ $result == *"bin"* ]]; then
			process_binary $f $OUTPUT
		else
			process_plaintext $f $OUTPUT
		fi
    	echo -ne "[+] Files Checked: [${fileCount} / ${#files[@]}]\r";
	done
	echo -e "\r"
	echo "[+] Done."
	rm -rd "./tmp"
else
	echo "[+] Checking file..."
	echo "### Urls Found:" > $OUTPUT
	process_plaintext $f $OUTPUT
fi
# echo "[+] Cleaning duplicated urls..."
# python remove_duplicates.py $OUTPUT $REPORT
cp $OUTPUT $REPORT
rm $OUTPUT