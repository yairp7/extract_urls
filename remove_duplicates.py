import sys

if len(sys.argv) < 3:
	print '[-] Must provide a input file and an output file'
	print '[-] Syntax: python remove_duplicates.py <input> <output>'
	exit()

f = open(sys.argv[1], 'r')
if f:
	lines = f.readlines()
	f.close()
	clean = set()
	result = []
	for line in lines:
	    if line not in clean:
	        clean.add(line)
	        result.append(line)

	f = open(sys.argv[2], 'w+')
	if f:
		for line in result:
			f.write(line)

	f.close()