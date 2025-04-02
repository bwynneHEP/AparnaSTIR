#! /bin/sh -e


time ./simulate_data.sh FDG.hv CTAC.hv template_sinogram.hs scatter_simulation.par scatter_template.hs

#rm -f *log my_zoomed* *.par *.sh
#mv *g${g}.* GATE${g}/
#rm -f  *.s *.hs  CTAC*v FDG*v

echo DONE
