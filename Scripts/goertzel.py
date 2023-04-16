import sys
import math



N = 1024
k = 0

xs = [1 / N]*(N - 1)
#xs = [1, -1]*(N//2)

cosomega2 = 2*math.cos(2 * math.pi * k / N)

s2, s1 = 0, 0

s = 0

for x in xs:
    sn = x / 1024 + cosomega2*s1 - s2
    
    s2, s1 = s1, sn

    s = sn

    print(sn)

print(s1*s1 + s2*s2 - cosomega2*s1*s2)
print((s1*s1 + s2*s2 - cosomega2*s1*s2) / 1024**2)

