import math
import sys
import itertools as it

LED_SPACING = 0.68
LED_STRIP_SPACING = 1.04
LEDS_PER_STRIP = 72
STRIP_LENGTH = (LEDS_PER_STRIP - 1)*LED_SPACING + LED_STRIP_SPACING
WBR = 1.5
BRW = 0.87
WW = 2.4
WBL = 0.87
BLW = 1.5
WBC = WW / 2
BCW = WBC
KEY_SPACINGS = (WBR, BRW, WW, WBL, BLW, WBR, BRW, WW, WBL, BLW, WBC, BCW)

A4 = 440
A4N = 48
START_NOTE = 15 # C2
END_NOTE = 87
START_FREQUENCY = A4 * 2**((START_NOTE - A4N)/12)
LOWEST_FREQUENCIES = [START_FREQUENCY*2**(i/12) for i in range(12)]
FREQUENCIES = LOWEST_FREQUENCIES
for i in range(END_NOTE - START_NOTE - 12):
    FREQUENCIES.append(2*FREQUENCIES[i])

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

CHUNKN = 9
THRESHOLD = 0.05
start = True
key_spacings = it.cycle(KEY_SPACINGS)
for _ in range(START_NOTE):
    next(key_spacings)
running_key_distance = it.accumulate(key_spacings, initial=0)

seen = set()
duplicates = []

print('(', end='')
for chunki, chunk in enumerate(parameters[i:i+CHUNKN] for i in range(0, len(parameters), CHUNKN)):
    if start:
        start = False
        print('(', end='')
    else:
        print(', (', end='')

    cstart = True
    for i, (k, N) in enumerate(chunk):
        index = chunki*CHUNKN + i
        key_distance = next(running_key_distance)

        # Id of the nearest LED
        skipped_strips = key_distance // STRIP_LENGTH
        skipped_strips_length = skipped_strips * STRIP_LENGTH
        distance_in_strip = key_distance - skipped_strips_length
        ledid = int(round(distance_in_strip / LED_SPACING) + skipped_strips*LEDS_PER_STRIP)

        if ledid in seen:
            duplicates.append(ledid)
        seen.add(ledid)
        s = f'(k => {k}, N => {N}, ledid => {ledid}, threshold => to_sfixed({THRESHOLD}, MULTIPLIER_LEFT, MULTIPLIER_RIGHT))'
        if cstart:
            cstart = False
        else:
            s = ', ' + s
        print(s, end='', sep='')
    print(')', end='')
print(')')

if duplicates:
    print(f'Error: duplicate LED IDs={duplicates}', file=sys.stderr)
    sys.exit(-1)

leftover = set(range(145)) - seen
if leftover:
    print(f'Unassigned LEDs: {leftover}')

