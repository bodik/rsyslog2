#!/usr/bin/python

flags = "CEUAPRSF"
def d(i):
	o=""
	if (i & 128) == 128:
		o = o+"C"	
	if (i & 64) == 64:
		o = o+"E"
	if (i & 32) == 32:
		o = o+"U"
	if (i & 16) == 16:
		o = o+"A"
	if (i & 8) == 8:
		o = o+"P"
	if (i & 4) == 4:
		o = o+"R"
	if (i & 2) == 2:
		o = o+"S"
	if (i & 1) == 1:
		o = o+"F"
	return o

print("translate {\n\tfield => \"[nf][tf]\"\n\tdictionary => [")

for i in range(0,255):
	print "\"%d\",\"%s\"," % (i,d(i))

print("]\n\t}\n")
