load "icaart2024_lib.gp"

lw = 1.5
dashsl = 10
dashel = 5
set style data lines

set xlabel "Number of agents"
set ylabel "Succes rate [%]"

set key samplen 1.5

xstep = 10
ystep = 20

set xtics scale 0.5 xstep
set link y2
set ytics ystep
set y2tics ystep

xmin_uniq = -1e6
do for [x=xmin:xmax] {
    set xrange [x:xmax]
    do for [i=2:cols] {
        stats ifname using 1:i nooutput
        if (STATS_max_y < ymax) {
            xmin_uniq = x
            break
        }
    }
    if (xmin_uniq >= xmin) {
        break
    }
}
xmax_uniq = 1e6
do for [x=xmax:xmin_uniq+1:-1] {
    set xrange [xmin_uniq:x]
    do for [i=2:cols] {
        stats ifname using 1:i nooutput
        if (STATS_min_y > ymin) {
            xmax_uniq = x
            break
        }
    }
    if (xmax_uniq <= xmax) {
        break
    }
}

xrange_min = xmin_uniq-1 > xmin ? xmin_uniq-1 : xmin
xrange_max = xmin_uniq+1 < xmax ? xmax_uniq+1 : xmax
yrange_min = 0
yrange_max = 100

set xrange [xrange_min:xrange_max]
set yrange [yrange_min:yrange_max]

last_sota_col = 2+n_sota_tools-1

plot for [i=2:last_sota_col] ifname using i ls (i-1) lw lw, \
    for [k=1:n_overlap_sets] for [j=1:n_overlap] i=last_sota_col+(k-1)*n_overlap+j \
        "" using i ls i-1 lw lw dashtype (dashsl,dashel) title j==n_overlap ? lra_title(i) : ""
