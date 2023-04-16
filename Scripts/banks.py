import numpy as np
import matplotlib.pyplot as plt
import math

FS = 2500000/64

x = np.linspace(-FS/2, FS/2, 100000)

o = 2*np.pi*x/FS

for m,N in ((0, 500), (0, 1000)):
    #H = (np.absolute(-np.exp(-1j*m/N)*np.exp(-1j*(N-1) * o / 2)*np.sin(N*o/2) / np.sin(np.pi*m/N - o/2)))/N
    H = np.absolute(np.sin(N*o/2) / np.sin(np.pi*m/N - o/2)) / N
    plt.plot(x, H)
    print(f'Half width for N={N} is {FS/N}')

plt.legend(('N=500', 'N=1000'))
plt.xlim(-2*FS/500, 2*FS/500)
plt.title('|H(f)| for varying N')
plt.axhline(y=0.8, color='r', linestyle='-')
plt.show()

