def sea(f):
    for i in range(8):
        p = 2 ** i
        nearest = round(f / p)

A4 = 440
LOWEST_FREQUENCIES = [440/(2**4)*(2**(i/12)) for i in range(12)]
F_SAMPLE = 2500000 / 64

print(LOWEST_FREQUENCIES)


for lf in LOWEST_FREQUENCIES:
    print(f"Investigating {lf}Hz")

    Nideal = F_SAMPLE / (2*lf)
    
    for i in range(1, 8):
        p = 2**i
        nearest = round(Nideal / p)
        best = nearest * p
        rf = F_SAMPLE / (2*best)
        Ntotal = best * 2**(7-i);
        print(f"{i}=>{p}: {best} ({rf} | {abs(rf/lf - 1)*100}%)\t{Ntotal}")
    print('')


