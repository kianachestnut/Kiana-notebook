#!/bin/csh -fx
# CESM with QFED fire emissions - July 2018
# Based on standard QFED format (variable name: biomass)

# ====================================================================
# define directories
# ====================================================================

setenv MACH hpcc
setenv CCSMTAG CESM2-release-2.1.0
setenv CCSMROOT /share/home/minghuai/yliang/model/$CCSMTAG
setenv DATADIR  /share/home/minghuai/yliang/model/CESM_INPUT

# ====================================================================
# case-specific stuff
# ====================================================================

setenv CASE    F2000_QFED_201807
setenv CIME_OUTPUT_ROOT /share/home/ywliu/lxyyy/scratch/runout
setenv CASEROOT /share/home/ywliu/lxyyy/scratch/cesmrun/$CASE
setenv RUNDIR   $CIME_OUTPUT_ROOT/$CASE

# ====================================================================
# create new case, configure, compile and run
# ====================================================================

if ( -e ${CASEROOT} ) then
    rm -rf $CASEROOT
endif

if ( -e ${RUNDIR} ) then
    rm -rf $RUNDIR
endif

# ----------------------------------
# create new case
# ----------------------------------

cd $CCSMROOT/cime/scripts

./create_newcase --case $CASEROOT --mach $MACH --res f09_f09_mg17 --compset F2000climo \
                 --compiler intel --queue mpi --walltime 01:00 --run-unsupported

# ----------------------------------
# set environment
# ----------------------------------

cd $CASEROOT

./xmlchange --file env_build.xml --id EXEROOT --val "${RUNDIR}/bld"
./xmlchange --file env_run.xml   --id RUNDIR  --val "${RUNDIR}/run"
./xmlchange --file env_run.xml   --id DOUT_S  --val 'FALSE'

# edit env_batch.xml
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

cd $CASEROOT

# ----------------------------------
# configure
# ----------------------------------

./xmlchange --file env_run.xml --id RUN_STARTDATE --val '2018-07-01'
./xmlchange --file env_run.xml --id RESUBMIT      --val '0'
./xmlchange --file env_run.xml --id STOP_N        --val '3'
./xmlchange --file env_run.xml --id STOP_OPTION   --val 'ndays'
./xmlchange --file env_run.xml --id REST_N        --val '1'
./xmlchange --file env_run.xml --id REST_OPTION   --val 'ndays'

####--------------------------
##Modifying namelists of CAM6
####--------------------------

echo "user_nl_cam"
cat <<EOF >! user_nl_cam

avgflag_pertape = 'A'
nhtfrq          = -24
mfilt           = 1

fincl1 = 'bc_a1_num','dst_a1_num','dst_a3_num','PM25',
         'AODPOM','AODSOA',
         'num_a1','num_a2','num_a4',
         'CO','CO2','SO2','DMS',
         'T','Q','PS','PSL','PRECT',
         'UBOT','VBOT',
         'bc_a4','pom_a4','SO4_a1','SO4_a2',
         'SFBC','SFPOM','SFSO4'

! ===== QFED Fire Emissions =====
! Standard QFED variable name is 'biomass'
! %y%m%d will be replaced by YYYYMMDD automatically

srf_emis_specifier = 'bc_a4  -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_bc.061.%y%m%d.nc4:biomass',
                     'pom_a4 -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_oc.061.%y%m%d.nc4:biomass',
                     'SO2    -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_so2.061.%y%m%d.nc4:biomass',
                     'CO     -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_co.061.%y%m%d.nc4:biomass',
                     'NO     -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_no.061.%y%m%d.nc4:biomass'

&cam_initfiles_nl
 bnd_topo = '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/topo/fv_0.9x1.25_nc3000_Nsw042_Nrs008_Co060_Fi001_ZR_sgh30_24km_GRNL_c170103.nc'
 ncdata = '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/inic/fv/f.e20.FCSD.f09_f09_mg17.cesm2.1-exp002.001.cam.i.2005-01-01-00000_c180801_32L.nc'
/

EOF

# submit and run scripts
cd $CASEROOT
./case.setup

./case.build --clean-all

./case.build --skip-provenance-check

./case.submit

date
