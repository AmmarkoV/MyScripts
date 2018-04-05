reset
fontSpec(s) = sprintf("Times-Roman, %d", s)

set term post eps enhanced fontSpec(16)
set output 'avg_waste.eps'

set grid
set auto y
set auto x

ticsFont=fontSpec(16)
set xtics font ticsFont
set ytics font ticsFont

set ylabel "Average Resource Wastage" font fontSpec(25) offset char -1,0
set xlabel "Workflows" font fontSpec(25) offset 0,char -1

set style fill pattern border -1
set style data histograms
set boxwidth 1.0
set style histogram clustered gap 1

keyFont=fontSpec(18)
set key spacing 2 font keyFont
#using directly 'set key spacing 2 font fontSpec(18)' doesn't seem to work...

set key at graph 0.25, 0.9

fn(v) = sprintf("%.1f", v)

plot \
    for [COL=2:3] 'multi.val' using COL:xticlabels(1) title columnheader fs pattern 2, \
    'multi.val' u ($0-1-1./6):2:(fn($2)) w labels font fontSpec(14) offset char 0,0.5 t '' , \
    'multi.val' u ($0-1+1./6):3:(fn($3)) w labels font fontSpec(14) offset char 0,0.5 t ''
