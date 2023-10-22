set terminal svg size 400,320 enhance

set output ofname

n_sota_tools = 2
n_overlap = 3

stats ifname using 1 nooutput
cols = STATS_columns
n_tools = cols-1

n_overlap_sets = (n_tools-n_sota_tools)/n_overlap
n_tools = n_tools - n_overlap_sets*(n_overlap-1)

xmin = STATS_min
xmax = STATS_max

ymin = 1e6
ymax = 0
do for [i=2:cols] {
    stats ifname using i nooutput
    ymin = (ymin < STATS_min) ? ymin : STATS_min
    ymax = (ymax > STATS_max) ? ymax : STATS_max
}

bw = 0.2
set style data boxes
set boxwidth bw absolute
set style fill solid border lc "black"

set xlabel "Timeout [s]"
set ylabel "Solved instances"

# default_fsize = 12.
# fsize = 8.
# fcoef = fsize/default_fsize
# font = sprintf(",%d", fsize)

# 'keywidth' does not seem to accept lower values
# 'width' does not seem to accept lower values
# force #cols with 'columns'?
# font size with 'font'?
set key horizontal Left reverse samplen 0 spacing 1
set key tmargin left
set key enhance autotitle columnhead

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

do for [i=1:n_sota_tools] {
    set style line i lc rgb (pallete(i))
}
do for [k=1:n_overlap_sets] {
    k_ = n_sota_tools+k
    do for [j=1:n_overlap] {
        i = n_sota_tools+(k-1)*n_overlap+j
        set style line i lc rgb (palleteac(k_, 0.35+0.25*(j-1)))
    }
}

log2(x) = log(x)/log(2)
fx(x) = log2(x/xmin)+1
finv(x) = 2**(x-1)*xmin

set xtics scale 0 1
set for [i=1:fx(xmax)] xtics add (sprintf("%d", finv(i)) i)
set link y2
set ytics scale 0.5 100
set y2tics scale 0.5 100

ystep = 100

xrange_min = fx(xmin)-bw*(n_tools*0.5+1)
xrange_max = fx(xmax)+bw*(n_tools*0.5+1)
yrange_min = ymin - int(ymin)%ystep
yrange_max = ymax + ystep - int(ymax)%ystep

set xrange [xrange_min:xrange_max]
set yrange [yrange_min:yrange_max]

xpos(x, col) = fx(x)+bw*(col-1.5-n_tools*0.5)

last_sota_col = 2+n_sota_tools-1

plot for [y=yrange_min:yrange_max:ystep] y with line notitle lc black lw 0.5 dashtype 2,\
    for [i=2:last_sota_col] ifname using (xpos($1, i)):i ls (i-1), \
    for [k=1:n_overlap_sets] for [j=1:n_overlap] i=last_sota_col+(k-1)*n_overlap+j \
        "" using (xpos($1, last_sota_col+k)):i ls i-1 \
        title j==n_overlap ? columnhead(i)[1:strstrt(columnhead(i), ":")-1].", {/Symbol d})" : ""
