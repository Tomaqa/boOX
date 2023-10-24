load "icaart2024_lib.gp"

lw = 1.5
dashl = 10
set style data lines

dashcoef(k) = 1./k
dashsl(k) = dashl*dashcoef(k)
dashel(k) = dashl*0.5*dashcoef(k)

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
do for [x=xmin+1:xmax-1] {
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
do for [x=xmax-1:xmin_uniq+1:-1] {
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

xrange_min = max(xmin, xmin_uniq-1)
xrange_max = min(xmax, xmax_uniq+1)
yrange_min = 0
yrange_max = 100

set xrange [xrange_min:xrange_max]
set yrange [yrange_min:yrange_max]

last_sota_col = 2+n_sota_tools-1

plot for [i=2:last_sota_col] ifname using 1:i ls (i-1) lw lw, \
    for [k=1:n_overlap_sets] for [j=1:n_overlap] i=last_sota_col+(k-1)*n_overlap+j \
        "" using 1:i ls i-1 lw lw dashtype (dashsl(k),dashel(k)) title j==n_overlap ? lra_title(i) : ""
