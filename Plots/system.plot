reset
fontSpec(s) = sprintf("Times-Roman, %d", s)

set term post eps enhanced fontSpec(25)
set output 'system.eps'

set grid
set auto y
set auto x

ticsFont=fontSpec(25) 
set xtics font ticsFont
set ytics font ticsFont
set yrange [0:46];
set ylabel "Frames Per Second" font fontSpec(25) offset char -1,0
set xlabel "System Overhead Experiments" font fontSpec(25) offset 0,char -1

set style fill pattern border -1
set style data histograms
set boxwidth 0.95
set style histogram clustered gap 1

keyFont=fontSpec(18)
set key spacing 2 font keyFont
#using directly 'set key spacing 2 font fontSpec(18)' doesn't seem to work...

#set key at graph 0.25, 0.9

fn(v) = sprintf("%.1f", v)

plot \
    for [COL=2:4] 'system.val' using COL:xticlabels(1) title columnheader fs pattern 2, \
    'system.val' u ($0-1-1./6):2:(fn($2)) w labels font fontSpec(20) offset char -0.9,0.5 t '' , \
    'system.val' u ($0-1+1./6):3:(fn($3)) w labels font fontSpec(20) offset char -2.0,0.5 t '' , \
    'system.val' u ($0-1+3./6):4:(fn($4)) w labels font fontSpec(20) offset char -3.0,0.5 t ''
