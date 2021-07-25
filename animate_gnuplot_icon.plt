reset

#=================== Parameter ====================
color_num = 3
array graph_domain_num[color_num] = [4, 3, 3]
array color_name[color_num] = ['green', 'red', 'blue']

# Arrays to store slopes and intercepts of linear functions
# One-dimensional array as two-dimensional (1st column: slope, 2nd column: intercept)
column_num = 2
do for [i=1:color_num:1] {
    eval sprintf("array coef_%s[%d]", color_name[i], graph_domain_num[i]*column_num)
}

grid_dx = 70.3
grid_dy = 82.0
xmin = -56.0
xmax = 232.0
ymin = -67.0
ymax = 221.0

line_w = 18
wndw_w = 960
wndw_h = 960

# This file saves the coordinates of the break points of each graph.
data_icon_pos = "pos_break_point.txt"
# This file saves the coordinates of sample points on each graph.
data_fitting = "fitting_parameter.txt"

folder_data = 'data'
folder_img = 'png'

# Select terminal type
qtMode = 0     # ==1: qt (simulator) / !=1: png (output images for making video)
print sprintf("[MODE] %s", (qtMode==1 ? 'Simulate in Qt window' :'Output PNG images'))

#=================== Functions ====================
# Index to treat one-dimensional array as two-dimensional
idx(i, j) = j + (i-1) * column_num
# Return the mean value of two variables x and y
mean(x, y) = (x+y)/2
# Text file to store data of each graph
data_graph(n) = "graph_".color_name[n].".txt"

#=================== Calculation ====================
# Create a folder for storing text files.
system sprintf('mkdir %s', folder_data)

# Calculate slopes and intercepts of linear functions using fitting
set fit nolog quiet     # Not print fitting results to terminal

set print sprintf("%s/%s", folder_data, data_fitting)
print sprintf("# %s\n# slope / intercept", data_fitting)

do for [j=1:color_num:1] {
    print sprintf("\n# %s", color_name[j])

    do for [i=1:graph_domain_num[j]:1] {
        # Find parameters of a linear function passing through two points using fitting.
        fit a*x+b data_icon_pos using 2*j-1:2*j every ::(i-1)::i via a, b   # a: slope / b: intercept
        eval sprintf("coef_%s[idx(i, 1)] = a", color_name[j])
        eval sprintf("coef_%s[idx(i, 2)] = b", color_name[j])
        print a, b      # Save these parameters to the text file
    }
}
unset print

# Make text files in which coordinates of points on each graph are saved, in order to draw 3 graphs gradually
sampling_dx = 0.5
set yrange [*:*]    # This command enables to remove restrictions on the range of the stats command.

do for [i=1:color_num:1] {
    pos_x = xmin
    domain_num = 1

    set print sprintf("%s/%s", folder_data, data_graph(i))
    stats data_icon_pos using 2*i-1 every ::domain_num::domain_num nooutput
    next_domain_xmax = STATS_max

    while(pos_x <= xmax){
        if((domain_num < graph_domain_num[i]) && (next_domain_xmax < pos_x)){
            domain_num = domain_num + 1
            stats data_icon_pos using 2*i-1 every ::domain_num::domain_num nooutput
            next_domain_xmax = STATS_max
        }
        eval sprintf("pos_y = coef_%s[idx(domain_num, 1)]*pos_x + coef_%s[idx(domain_num, 2)]", color_name[i], color_name[i])
        print pos_x, pos_y      # Save the coordinates of sample points on each graph to the text file
        pos_x = pos_x + sampling_dx
    }
    unset print
}

#=================== Setting ====================
if(qtMode==1){
    set term qt size wndw_w, wndw_h font "Times, 20"
} else {
set term pngcairo size wndw_w, wndw_h font "Times, 20"
    system sprintf('mkdir %s', folder_img)
}

set xrange[xmin:xmax]
set yrange[ymin:ymax]
set size ratio -1
unset key
unset tics

#=================== Plot ====================
frame_num = int((xmax-xmin)/sampling_dx+1)   # Number of frames
print sprintf("Start %s", (qtMode==1 ? "simulation" : sprintf("outputting %d images ...", frame_num)))
arw_num = 0 # arw -> arrow

# Axes
set arrow (arw_num=arw_num+1, arw_num) nohead from 0, ymin+1 to 0, ymax-1 lw line_w lt -1 front
set arrow (arw_num=arw_num+1, arw_num) nohead from xmin+1, 0 to xmax-1, 0 lw line_w lt -1 front

# Border
# - You only need to run one of the commands to display the border. 
# - However, they each lack a different corner, so you'll need to run both.
set border lw line_w
set object 1 rectangle center mean(xmin, xmax), mean(ymin, ymax) size xmax-xmin, ymax-ymin fs empty border lt -1 lw line_w front

# Grid lines
do for [i=1:3:1]{ # x-axis
    set arrow (arw_num=arw_num+1, arw_num) nohead from grid_dx*i, ymin+1 to grid_dx*i, ymax-1 lw line_w lc rgb 'gray' back
}
do for [i=1:2:1]{ # y-axis
    set arrow (arw_num=arw_num+1, arw_num) nohead from xmin+1, grid_dy*i to xmax-1, grid_dy*i lw line_w lc rgb 'gray' back
}

# Graphs
do for [i=1:frame_num:1] {
    if(qtMode != 1) {
        set output sprintf('%s/img_%04d.png', folder_img, i)
    }

    plot for [j=1:color_num:1] folder_data."/".data_graph(color_num+1-j) using 1:2 every ::0::i-1 w l lw line_w lc rgb color_name[color_num+1-j]

    if(qtMode == 1) {   
        pause ((i == 1 || i == frame_num) ? 1 : 0.01)   # Adjust the drawing speed
    } else {
        set out     # terminal pngcairo
    }
}

# Output PNG image
set term pngcairo size wndw_w, wndw_h font "Times, 20"
set output 'icon_pngcairo.png'
plot for [j=1:color_num:1] folder_data."/".data_graph(color_num+1-j) using 1:2 every ::0::frame_num-1 w l lw line_w lc rgb color_name[color_num+1-j]
set out
print 'Finish!'