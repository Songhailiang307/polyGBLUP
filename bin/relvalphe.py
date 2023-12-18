import sys

relid=open(sys.argv[1])
valid=open(sys.argv[2])
phe=open(sys.argv[3])
q1=open(sys.argv[4],'w')
q2=open(sys.argv[5],'w')

dick1={}
dick2={}
for i in phe.readlines()[1:]:
	f=i.split()
	dick1[f[0]]=f[5]
	dick2[f[0]]=f[6]


for i in relid:
	f=i.split()
	if f[0] in dick1:
		q1.write(f[0]+'\t'+'1'+'\t'+dick1[f[0]]+'\n')



for i in valid:
	f=i.split()
	if f[0] in dick2:
		q2.write(f[0]+'\t'+dick2[f[0]]+'\n')
relid.close()
valid.close()
phe.close()
q1.close()
q2.close()