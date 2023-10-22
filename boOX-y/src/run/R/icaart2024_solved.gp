load "icaart2024_lib.gp"

n_sota_tools = 2
n_overlap = 3

n_overlap_sets = (n_tools-n_sota_tools)/n_overlap
n_tools = n_tools - n_overlap_sets*(n_overlap-1)

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

fx(x) = log2(x/xmin)+1
finv(x) = 2**(x-1)*xmin

ystep = 100

set xtics scale 0 1
set for [i=1:fx(xmax)] xtics add (sprintf("%d", finv(i)) i)
set link y2
set ytics scale 0.5 ystep
set y2tics scale 0.5 ystep

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
