set terminal svg size 400,240 noenhance

set output ofname

n_orig_tools = 2
n_overlap = 3

stats ifname using 1 nooutput
cols = STATS_columns
n_tools = cols-1

n_overlap_sets = (n_tools-n_orig_tools)/n_overlap
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

bw = 0.1
set style data boxes
set boxwidth bw absolute
set style fill solid noborder

set xlabel "Timeout [s]"
set ylabel "Solved instances"

set key horizontal tmargin left
set key autotitle columnhead

log2(x) = log(x)/log(2)
fx(x) = log2(x/xmin)+1
finv(x) = 2**(x-1)*xmin

set xtics scale 0 1
set for [i=1:fx(xmax)] xtics add (sprintf("%d", finv(i)) i)
set link y2
set ytics scale 0.5
set y2tics scale 0.5

ystep = 100

xrange_min = fx(xmin)-bw*(n_tools*0.5+1)
xrange_max = fx(xmax)+bw*(n_tools*0.5+1)
yrange_min = ymin - int(ymin)%ystep
yrange_max = ymax + ystep - int(ymax)%ystep

set xrange [xrange_min:xrange_max]
set yrange [yrange_min:yrange_max]

xpos(x, col) = fx(x)+bw*(col-1.5-n_tools*0.5)

last_orig_col = 2+n_orig_tools-1

plot for [y=yrange_min:yrange_max:ystep] y with line notitle lc black lw 0.5 dashtype 2,\
    for [i=2:last_orig_col] ifname using (xpos($1, i)):i, \
    for [k=1:n_overlap_sets] for [j=1:n_overlap] "" using (xpos($1, last_orig_col+k)):last_orig_col+(k-1)*n_overlap+j
