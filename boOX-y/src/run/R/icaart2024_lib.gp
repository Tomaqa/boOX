set terminal svg size 400,320 enhance

set output ofname

stats ifname using 1 nooutput
cols = STATS_columns
n_tools = cols-1

xmin = STATS_min
xmax = STATS_max

ymin = 1e6
ymax = 0
do for [i=2:cols] {
    stats ifname using i nooutput
    ymin = (ymin < STATS_min) ? ymin : STATS_min
    ymax = (ymax > STATS_max) ? ymax : STATS_max
}

rgba(r, g, b, a) = 2**24*int(a) + 2**16*int(r) + 2**8*int(g) + int(b)
rgb(r, g, b) = rgba(r, g, b, 0)

rgbac(r, g, b, a, c) = rgba(r*c, g*c, b*c, a)
rgbc(r, g, b, c) = rgbac(r, g, b, 0, c)
rgbacc(r, g, b, ac, c) = rgbac(r, g, b, (1.-ac)*255, c)

# (233, 30, 99),
# (33, 150, 243),
# (76, 175, 80),
# (255, 152, 0),
# (0, 188, 212),
# (156, 39, 176),
# (121, 85, 72),
# (255, 187, 59),
# (244, 67, 54),
# (96, 125, 139),
# (0, 150, 136),
# (63, 81, 181),

palleteacc(i, ac, c) = \
    i==1 ? rgbacc(76, 175, 80, ac, c) :\
    i==2 ? rgbacc(255, 152, 0, ac, c) :\
    i==3 ? rgbacc(0, 188, 212, ac, c) :\
    i==4 ? rgbacc(233, 30, 99, ac, c) :\
    i==5 ? rgbacc(33, 150, 243, ac, c) :\
    i==6 ? rgbacc(156, 39, 176, ac, c) :\
    i==7 ? rgbacc(121, 85, 72, ac, c) :\
           rgbacc(255, 187, 59, ac, c)
palleteac(i, ac) = palleteacc(i, ac, 1.)
## does not seem to be useful - it may result in ugly colors
# palletec(i, c) = palleteacc(i, 1., c)
pallete(i) = palleteac(i, 1.)

log2(x) = log(x)/log(2)

set key enhance autotitle columnhead
