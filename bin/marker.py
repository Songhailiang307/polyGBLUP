import sys

geno=open(sys.argv[1])
poly=sys.argv[2]
q=open(sys.argv[3],'w')

for i in geno:
	f=i.split()
	for e in range(0,len(f)):
		if f[e]=='0':
			f[e]='0'
		elif f[e]==poly:
			f[e]='2'
		else:
			f[e]='1'

	q.write(' '.join(f[:])+'\n')
geno.close()
q.close()