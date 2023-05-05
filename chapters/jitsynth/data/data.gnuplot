#!/usr/bin/env gnuplot

# set terminal pdf enhanced
# set output 'opt.pdf'

set terminal pdf size 5in,4in

set xlabel "Filter"

set key tmargin left

set style data histogram
set style histogram cluster gap 1

# set logscale y

set style fill solid border rgb "black"
set style fill pattern 0

set auto x
set yrange [0:*]

set ylabel "cycles"
set output 'cycles.pdf'
plot 'cycles.dat' using 2:xtic(1) title col lc rgb "black", \
             '' using 4:xtic(1) title col lc rgb "black", \
             '' using 3:xtic(1) title col lc rgb "black", \
             '' using 5:xtic(1) title col lc rgb "black", \

set ylabel "instret"
set output 'instret.pdf'
plot 'instret.dat' using 2:xtic(1) title col lc rgb "black", \
             '' using 3:xtic(1) title col lc rgb "black", \
             '' using 4:xtic(1) title col lc rgb "black", \



set ylabel "size (bytes)"
set output 'size.pdf'
plot 'size.dat' using 2:xtic(1) title col lc rgb "black", \
             '' using 3:xtic(1) title col lc rgb "black", \
             '' using 4:xtic(1) title col lc rgb "black", \

set ylabel "misses"
set output 'misses.pdf'
plot 'misses.dat' using 2:xtic(1) title col lc rgb "black", \
             '' using 3:xtic(1) title col lc rgb "black", \
             '' using 4:xtic(1) title col lc rgb "black", \
