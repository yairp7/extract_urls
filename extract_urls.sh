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

# Check if APK file
if [[ $FILENAME == *"apk"* ]]; then
	echo "[+] APK file found, extracting..."
	if [[ ! -d "./tmp" ]]; then
		mkdir ./tmp
	fi
	
	unzip -o -q "${FILENAME}" -d "./tmp/unzip_result"
	apktool --quiet -f d "${FILENAME}" -o "./tmp/apktool_result"

	echo "### Urls Found:" > $OUTPUT

	fileCount=0
	IFS=$'\n' files=( $(find "./tmp" -type f) )
	for d in "${files[@]}"; do
		fileCount=$(( fileCount+1 ))
    	strings $d | egrep -o 'https?://[^ ]+' >> $OUTPUT
    	echo -ne "[+] Files Checked: [${fileCount} / ${#files[@]}]\r";
	done
	echo -e "\r"
	echo "[+] Done."
	rm -rd "./tmp"
else
	echo "[+] Checking file..."
	echo "### Urls Found:" > $OUTPUT
	strings $FILENAME | egrep -o 'https?://[^ ]+' >> $OUTPUT
fi
echo "[+] Cleaning duplicated urls..."
python remove_duplicates.py $OUTPUT $REPORT
rm $OUTPUT