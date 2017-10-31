#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q geyser                 # queue
#BSUB -J sub_ncl 
#BSUB -W 23:59                   # wall clock limit
#BSUB -P P54048000               # account number

################################################################

date

START=1140
END=1161

ncl crossTrackCW_chunk.ncl stIx=${START} enIx=${END}
 
date 
