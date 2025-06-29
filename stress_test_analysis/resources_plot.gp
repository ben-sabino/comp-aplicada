set terminal png size 1200,800
set output 'system_resources.png'
set title 'Uso de Recursos do Sistema'
set xlabel 'Tempo'
set ylabel 'Uso (%)'
set grid
set key outside

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M:%S"

plot 'resources_data.csv' using 1:2 with lines title 'CPU (%)', \
     'resources_data.csv' using 1:3 with lines title 'Memória (%)'
