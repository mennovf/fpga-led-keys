import math

def sea(f):
    for i in range(8):
        p = 2 ** i
        nearest = round(f / p)

A4 = 440
LOWEST_FREQUENCIES = [440/(2**4)*(2**(i/12)) for i in range(12)]
FREQUENCIES = LOWEST_FREQUENCIES
for i in range(12, 88):
    FREQUENCIES.append(2*FREQUENCIES[i - 12])

FS = 2500000 / 64

THR_DELTAF_0P8 = 14.2 * 1000

parameters = []

for fi, f in enumerate(FREQUENCIES):
    fneighbour = FREQUENCIES[fi - 1] if fi >= 1 else FREQUENCIES[1]
    deltaf = abs(fneighbour - f)

    Nspacing = math.ceil(FS / deltaf)
    N = Nspacing
    while True:
        acceptable_frequency_range = THR_DELTAF_0P8 / N
        m = round(f/FS * N)
        error = abs(math.sin(N*math.pi*f/FS) / math.sin(math.pi * m/N - math.pi*f/FS) / N)
        if abs(m / N * FS - f) < acceptable_frequency_range:
            print(f'({fi}: {f} at m/N={m}/{N} has error {error})')
            parameters.append((m, N))
            break
        N += 1

CHUNKN = 11
THRESHOLD = 0.05
start = True
print('(', end='')
for chunki, chunk in enumerate(parameters[i:i+CHUNKN] for i in range(0, len(parameters), CHUNKN)):
    if start:
        start = False
        print('(', end='')
    else:
        print(', (', end='')

    cstart = True
    for i, (k, N) in enumerate(chunk):
        s = f'(k => {k}, N => {N}, ledid => {chunki*CHUNKN + i}, threshold => to_sfixed({THRESHOLD}, MULTIPLIER_LEFT, MULTIPLIER_RIGHT))'
        if cstart:
            cstart = False
        else:
            s = ', ' + s
        print(s, end='', sep='')
    print(')', end='')
print(')')

