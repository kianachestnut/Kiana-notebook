#!/bin/csh -fx
# ====================================================================
# CESM F2000climo with QFED Fire Emissions
# Purpose: Simulation with QFED fire emissions for July 2018
# ====================================================================

setenv MACH hpcc
setenv CCSMTAG CESM2-release-2.1.0
setenv CCSMROOT /share/home/minghuai/yliang/model/$CCSMTAG
setenv DATADIR  /share/home/minghuai/yliang/model/CESM_INPUT
setenv QFED_DIR /work13/zzsun/lxy_data/QFED

setenv CASE    F2000_QFED_201807
setenv CIME_OUTPUT_ROOT /share/home/ywliu/lxyyy/scratch/runout
setenv CASEROOT /share/home/ywliu/lxyyy/scratch/cesmrun/$CASE
setenv RUNDIR   $CIME_OUTPUT_ROOT/$CASE

if ( -e ${CASEROOT} ) then
    rm -rf $CASEROOT
endif
if ( -e ${RUNDIR} ) then
    rm -rf $RUNDIR
endif

cd $CCSMROOT/cime/scripts
./create_newcase --case $CASEROOT --mach $MACH --res f09_f09_mg17 --compset F2000climo \
                 --compiler intel --queue mpi --walltime 01:00 --run-unsupported

cd $CASEROOT
./xmlchange --file env_build.xml --id EXEROOT --val "${RUNDIR}/bld"
./xmlchange --file env_run.xml   --id RUNDIR  --val "${RUNDIR}/run"
./xmlchange --file env_run.xml   --id DOUT_S  --val 'FALSE'

set N = 48
set M = 48
./xmlchange --file env_mach_pes.xml --id NTASKS_ATM --val "$N"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ATM --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_ATM --val '0'
./xmlchange --file env_mach_pes.xml --id NTASKS_LND --val "$N"
./xmlchange --file env_mach_pes.xml --id NTHRDS_LND --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_LND --val '0'
./xmlchange --file env_mach_pes.xml --id NTASKS_ICE --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ICE --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_ICE --val '0'
./xmlchange --file env_mach_pes.xml --id NTASKS_OCN --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_OCN --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_OCN --val '0'
./xmlchange --file env_mach_pes.xml --id NTASKS_CPL --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_CPL --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_CPL --val '0'
./xmlchange --file env_mach_pes.xml --id NTASKS_GLC --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_GLC --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_GLC --val '0'
./xmlchange --file env_mach_pes.xml --id NTASKS_ROF --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ROF --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_ROF --val '0'
./xmlchange --file env_mach_pes.xml --id NTASKS_WAV --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_WAV --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_WAV --val '0'
./xmlchange --file env_mach_pes.xml --id NTHRDS_ESP --val '1'

./xmlchange --file env_run.xml --id RUN_STARTDATE --val '2018-07-01'
./xmlchange --file env_run.xml --id RESUBMIT      --val '0'
./xmlchange --file env_run.xml --id STOP_N        --val '3'
./xmlchange --file env_run.xml --id STOP_OPTION   --val 'ndays'
./xmlchange --file env_run.xml --id REST_N        --val '1'
./xmlchange --file env_run.xml --id REST_OPTION   --val 'ndays'

cat <<EOF >! user_nl_cam
avgflag_pertape = 'A'
nhtfrq          = -24
mfilt           = 31

fincl1 = 'SFbc_a4','SFpom_a4','SFbc_a1','SFpom_a1',
         'SFso4_a1','SFso4_a2','SFSO2','SFH2SO4',
         'bc_a4','pom_a4','bc_a1','pom_a1','so4_a1','so4_a2',
         'bc_a4_SRF','pom_a4_SRF','so4_a1_SRF','so4_a2_SRF',
         'AODPOM','AODSOA','AODDUST','AEROD_v','AODVIS',
         'PM25','SO2','SO2_SRF','DMS','DMS_SRF',
         'FSNT','FSNTC','FLNT','FLNTC','SWCF','LWCF',
         'CLDTOT','CLDLOW','CLDMED','CLDHGH','CDNUMC',
         'PRECT','PRECC','PRECL',
         'T','U','V','OMEGA','Q','PS','PSL','TREFHT','UBOT','VBOT'

srf_emis_specifier = 'bc_a4  -> /work13/zzsun/lxy_data/QFED/qfed2.emis_bc.061.%y%m%d.nc4:biomass',
                     'pom_a4 -> /work13/zzsun/lxy_data/QFED/qfed2.emis_oc.061.%y%m%d.nc4:biomass',
                     'SO2    -> /work13/zzsun/lxy_data/QFED/qfed2.emis_so2.061.%y%m%d.nc4:biomass',
                     'num_a4 -> /work13/zzsun/lxy_data/QFED/qfed2.emis_bc.061.%y%m%d.nc4:biomass'

&cam_initfiles_nl
 bnd_topo = '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/topo/fv_0.9x1.25_nc3000_Nsw042_Nrs008_Co060_Fi001_ZR_sgh30_24km_GRNL_c170103.nc'
 ncdata = '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/inic/fv/f.e20.FCSD.f09_f09_mg17.cesm2.1-exp002.001.cam.i.2005-01-01-00000_c180801_32L.nc'
/
EOF

./case.setup
./case.build --clean-all
./case.build --skip-provenance-check
./case.submit
date
