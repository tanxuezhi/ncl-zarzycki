#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q geyser                # queue
#BSUB -J h1_process
#BSUB -W 12:00                    # wall clock limit
#BSUB -P P35201098               # account number

################################################################

date

YEAR=1998
OUTDIR=/glade/scratch/zarzycki/MERRA2
OUTPUTDIR=/glade/scratch/zarzycki/h1files/MERRA2/${YEAR}
mkdir -p $OUTDIR
mkdir -p $OUTPUTDIR

for j in `seq 0 36`   # 0 36
#for j in `seq 0 0`   # 0 36
do
  st=$(($j*10))
  en=$(($j*10+9))
  echo $st
  echo $en
  echo "-----"
  for i in `seq ${st} ${en}`
  do
  (  yyyy=`date -d "${YEAR}-01-01 $i days" +%Y`
    mm=`date -d "${YEAR}-01-01 $i days" +%m`
    dd=`date -d "${YEAR}-01-01 $i days" +%d`
    echo ${yyyy}${mm}${dd}
    cd ${OUTDIR}
    modlevs=MERRA2_200.inst6_3d_ana_Nv.${yyyy}${mm}${dd}.nc4
    preslevs=MERRA2_200.inst6_3d_ana_Np.${yyyy}${mm}${dd}.nc4
    if [ ! -f ${modlevs} ]; then
      wget --quiet ftp://goldsmr5.gesdisc.eosdis.nasa.gov/data/s4pa/MERRA2/M2I6NVANA.5.12.4/${yyyy}/${mm}/${modlevs}
    fi
    if [ ! -f ${preslevs} ]; then
      wget --quiet ftp://goldsmr5.gesdisc.eosdis.nasa.gov/data/s4pa/MERRA2/M2I6NPANA.5.12.4/${yyyy}/${mm}/${preslevs}
    fi
    cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/MERRA2
    ncl generateTrackerFilesMERRA.ncl 'YYYYMMDD="'${yyyy}${mm}${dd}'"' 'outDir="'${OUTPUTDIR}'"'
    rm ${OUTDIR}/${modlevs}
    rm ${OUTDIR}/${preslevs} 
  ) &
  done
  sleep 450
done

date
