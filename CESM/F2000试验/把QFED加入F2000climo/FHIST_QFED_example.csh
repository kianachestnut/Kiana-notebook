#!/bin/csh -fx
# CESM FHIST with QFED fire emissions - July 2018
# FHIST uses observed SST/sea-ice for more realistic simulation

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

setenv CASE    FHIST_QFED_201807
setenv CIME_OUTPUT_ROOT /share/home/ywliu/lxyyy/scratch/runout
setenv CASEROOT /share/home/ywliu/lxyyy/scratch/cesmrun/$CASE
setenv RUNDIR   $CIME_OUTPUT_ROOT/$CASE

# ====================================================================
# create new case
# ====================================================================

if ( -e ${CASEROOT} ) then
    rm -rf $CASEROOT
endif

if ( -e ${RUNDIR} ) then
    rm -rf $RUNDIR
endif

cd $CCSMROOT/cime/scripts

# Use FHIST compset for historical simulation
./create_newcase --case $CASEROOT --mach $MACH --res f09_f09_mg17 --compset FHIST \
                 --compiler intel --queue mpi --walltime 01:00 --run-unsupported

# ----------------------------------
# set environment
# ----------------------------------

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

cd $CASEROOT

# ----------------------------------
# configure for July 2018
# ----------------------------------

./xmlchange --file env_run.xml --id RUN_STARTDATE --val '2018-07-01'
./xmlchange --file env_run.xml --id RESUBMIT      --val '0'
./xmlchange --file env_run.xml --id STOP_N        --val '31'
./xmlchange --file env_run.xml --id STOP_OPTION   --val 'ndays'
./xmlchange --file env_run.xml --id REST_N        --val '10'
./xmlchange --file env_run.xml --id REST_OPTION   --val 'ndays'

# FHIST specific settings
./xmlchange --file env_run.xml --id RUN_TYPE --val 'hybrid'
./xmlchange --file env_run.xml --id RUN_REFCASE --val 'b.e21.BHIST.f09_g17.CMIP6-historical.001'
./xmlchange --file env_run.xml --id RUN_REFDATE --val '2015-01-01'

####--------------------------
##Modifying namelists of CAM6
####--------------------------

echo "user_nl_cam"
cat <<EOF >! user_nl_cam

avgflag_pertape = 'A'
nhtfrq          = -24
mfilt           = 1

fincl1 = 'bc_a1_num','dst_a1_num','dst_a3_num','PM25',
         'AODPOM','AODSOA','AODABS','AODUV',
         'num_a1','num_a2','num_a4',
         'CO','CO2','SO2','DMS',
         'T','Q','PS','PSL','PRECT','PRECC','PRECL',
         'UBOT','VBOT','TREFHT',
         'bc_a4','pom_a4','SO4_a1','SO4_a2',
         'SFBC','SFPOM','SFSO4',
         'FLNT','FSNT','FLNTC','FSNTC',
         'CLDTOT','LWCF','SWCF'

! ===== QFED Fire Emissions =====
srf_emis_specifier = 'bc_a4  -> /work13/zzsun/lxy_data/QEFD/qfed2.emis_bc.061.%y%m%d.nc4:biomass',
                     'pom_a4 -> /work13/zzsun/lxy_data/QEFD/qfed2.emis_oc.061.%y%m%d.nc4:biomass',
                     'SO2    -> /work13/zzsun/lxy_data/QEFD/qfed2.emis_so2.061.%y%m%d.nc4:biomass',
                     'CO     -> /work13/zzsun/lxy_data/QEFD/qfed2.emis_co.061.%y%m%d.nc4:biomass',
                     'NO     -> /work13/zzsun/lxy_data/QEFD/qfed2.emis_no.061.%y%m%d.nc4:biomass'

EOF

# submit and run scripts
cd $CASEROOT
./case.setup

./case.build --clean-all

./case.build --skip-provenance-check

./case.submit

date
