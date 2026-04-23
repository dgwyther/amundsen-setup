#!/bin/bash

module load nco

infile="amundsen_v2.5km_1992_v1.1_cycle365_bry.nc"
tmpdir="./tmp_cycles"
mkdir -p $tmpdir

X=20   # number of repeats

for i in $(seq 0 $((X-1))); do

    echo "Processing cycle $i"

    offset=$(echo "$i * 365" | bc)

    outfile="${tmpdir}/bry_cycle_${i}.nc"
    echo $outfile

    nccopy $infile $outfile

    if [ "$i" -eq 0 ]; then
        echo "Keeping full first cycle (including t=0)"
    else
        echo "Dropping first time slice and shifting by ${offset}"

        # --- drop first time step ---
        ncks -O -d temp_time,1, $outfile $outfile
	ncks -O -d salt_time,1, $outfile $outfile
	ncks -O -d v3d_time,1, $outfile $outfile
	ncks -O -d v2d_time,1, $outfile $outfile
	ncks -O -d zeta_time,1, $outfile $outfile

        # --- shift all time variables ---
        ncap2 -O -s "temp_time=temp_time+${offset}; \
                     salt_time=salt_time+${offset}; \
                     v3d_time=v3d_time+${offset}; \
                     v2d_time=v2d_time+${offset}; \
                     zeta_time=zeta_time+${offset}" \
              $outfile $outfile
    fi

done

# --- concatenate ---
ncrcat ${tmpdir}/bry_cycle_*.nc amundsen_bry_cycle${X}.nc

if ncdump -h amundsen_bry_cycle${X}.nc | grep -q cycle_length; then
    for v in temp_time salt_time v3d_time v2d_time zeta_time
    do
        ncatted -O -h -a cycle_length,$v,d,, amundsen_bry_cycle${X}.nc
    done
fi

echo "Done"
