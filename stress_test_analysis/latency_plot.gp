set terminal png size 1200,800
set output 'latency_over_time.png'
set title 'Latência das Operações ao Longo do Tempo'
set xlabel 'Tempo'
set ylabel 'Latência (ms)'
set grid
set key outside

# Converter timestamp para segundos desde o início
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M:%S"

plot 'latency_data.csv' using 1:4 with points title 'Latência', \
     'latency_data.csv' using 1:4 smooth bezier title 'Tendência'
