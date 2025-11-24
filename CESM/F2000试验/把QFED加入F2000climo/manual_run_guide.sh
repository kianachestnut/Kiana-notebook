#!/bin/bash
# CESM手动逐步运行指导
# 当自动脚本失败时,使用这个方法手动执行每一步

echo "======================================================================"
echo "CESM手动逐步运行指导"
echo "======================================================================"
echo ""
echo "按照以下步骤手动执行,每步都检查是否成功"
echo ""

cat << 'STEP1'
====================================================================== 
步骤 1: 创建新case
======================================================================

cd /share/home/minghuai/yliang/model/CESM2-release-2.1.0/cime/scripts

./create_newcase \
  --case /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control \
  --mach hpcc \
  --res f09_f09_mg17 \
  --compset F2000climo \
  --compiler intel \
  --queue mpi \
  --walltime 01:00 \
  --run-unsupported

# 检查是否成功
if [ $? -eq 0 ]; then
    echo "✓ Case创建成功"
else
    echo "✗ Case创建失败,请检查错误信息"
    exit 1
fi

STEP1

cat << 'STEP2'
====================================================================== 
步骤 2: 配置case环境
======================================================================

cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control

# 设置路径
./xmlchange --file env_build.xml --id EXEROOT --val "/share/home/ywliu/lxyyy/scratch/runout/F2000_control/bld"
./xmlchange --file env_run.xml --id RUNDIR --val "/share/home/ywliu/lxyyy/scratch/runout/F2000_control/run"
./xmlchange --file env_run.xml --id DOUT_S --val 'FALSE'

# 设置CPU配置
./xmlchange --file env_mach_pes.xml --id NTASKS_ATM --val "48"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ATM --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_ATM --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_LND --val "48"
./xmlchange --file env_mach_pes.xml --id NTHRDS_LND --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_LND --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_ICE --val "48"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ICE --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_ICE --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_OCN --val "48"
./xmlchange --file env_mach_pes.xml --id NTHRDS_OCN --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_OCN --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_CPL --val "48"
./xmlchange --file env_mach_pes.xml --id NTHRDS_CPL --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_CPL --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_GLC --val "48"
./xmlchange --file env_mach_pes.xml --id NTHRDS_GLC --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_GLC --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_ROF --val "48"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ROF --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_ROF --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_WAV --val "48"
./xmlchange --file env_mach_pes.xml --id NTHRDS_WAV --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_WAV --val '0'

./xmlchange --file env_mach_pes.xml --id NTHRDS_ESP --val '1'

# 设置运行参数
./xmlchange --file env_run.xml --id RUN_STARTDATE --val '2018-07-01'
./xmlchange --file env_run.xml --id RESUBMIT --val '0'
./xmlchange --file env_run.xml --id STOP_N --val '1'
./xmlchange --file env_run.xml --id STOP_OPTION --val 'ndays'
./xmlchange --file env_run.xml --id REST_N --val '1'
./xmlchange --file env_run.xml --id REST_OPTION --val 'ndays'

echo "✓ 环境配置完成"

STEP2

cat << 'STEP3'
====================================================================== 
步骤 3: 创建user_nl_cam
======================================================================

cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control

cat > user_nl_cam << 'EOF'

avgflag_pertape = 'A'
nhtfrq          = -24
mfilt           = 1

fincl1 = 'bc_a1_num','dst_a1_num','dut_a3_num','PM25',
         'AODPOM','AODSOA',
         'num_a1','num_a2','num_a4',
         'CO','CO2','SO2','DMS',
         'T','Q','PS','PSL','PRECT',
         'UBOT','VBOT'

&cam_initfiles_nl
 bnd_topo = '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/topo/fv_0.9x1.25_nc3000_Nsw042_Nrs008_Co060_Fi001_ZR_sgh30_24km_GRNL_c170103.nc'
 ncdata = '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/inic/fv/f.e20.FCSD.f09_f09_mg17.cesm2.1-exp002.001.cam.i.2005-01-01-00000_c180801_32L.nc'
/

EOF

echo "✓ user_nl_cam创建完成"
cat user_nl_cam

STEP3

cat << 'STEP4'
====================================================================== 
步骤 4: Setup case
======================================================================

cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control

./case.setup 2>&1 | tee case.setup.log

# 检查是否成功
if [ $? -eq 0 ]; then
    echo "✓ Case setup成功"
    echo "检查生成的文件:"
    ls -lh CaseDocs/ | head -10
else
    echo "✗ Case setup失败"
    echo "查看错误: tail -50 case.setup.log"
    exit 1
fi

STEP4

cat << 'STEP5'
====================================================================== 
步骤 5: Build case
======================================================================

cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control

# 清理之前的编译(如果有)
./case.build --clean-all

# 开始编译(这一步可能需要较长时间,20-60分钟)
./case.build --skip-provenance-check 2>&1 | tee case.build.log

# 检查是否成功
if [ $? -eq 0 ]; then
    echo "✓ Case build成功"
    echo "检查可执行文件:"
    ls -lh /share/home/ywliu/lxyyy/scratch/runout/F2000_control/bld/*.exe
else
    echo "✗ Case build失败"
    echo "查看错误: tail -100 case.build.log"
    echo "或者查看: /share/home/ywliu/lxyyy/scratch/runout/F2000_control/bld/cesm.bldlog"
    exit 1
fi

STEP5

cat << 'STEP6'
====================================================================== 
步骤 6: Submit case
======================================================================

cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control

./case.submit 2>&1 | tee case.submit.log

# 检查作业状态
echo ""
echo "检查作业队列:"
squeue -u $(whoami) || qstat -u $(whoami)

echo ""
echo "如果作业正在运行,可以监控日志:"
echo "tail -f /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/cesm.log.*"

STEP6

cat << 'MONITORING'
====================================================================== 
步骤 7: 监控运行
======================================================================

# 实时查看日志
tail -f /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/cesm.log.*

# 检查运行状态
cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control
./xmlquery RUN_STARTDATE
./xmlquery STOP_N
./xmlquery STOP_OPTION

# 检查输出文件
ls -lh /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/*.cam.h0.*

MONITORING

cat << 'TROUBLESHOOT'
====================================================================== 
常见问题排查
======================================================================

问题1: create_newcase失败
  - 检查CESM路径是否正确
  - 检查机器配置文件: config_machines.xml中是否有hpcc
  - 尝试列出可用机器: ./query_config --machines

问题2: case.setup失败
  - 检查: cat CaseDocs/env_mach_specific.xml
  - 检查: ls -l /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control/

问题3: case.build失败
  - 常见原因: 编译器配置问题
  - 检查: module list (查看加载的模块)
  - 查看详细错误: grep -i error /share/home/ywliu/lxyyy/scratch/runout/F2000_control/bld/cesm.bldlog

问题4: case.submit后没有输出
  - 检查作业是否提交成功: squeue -u $(whoami)
  - 检查作业脚本: cat case.run
  - 手动运行: ./case.submit --no-batch (前台运行,用于调试)

问题5: 运行中断
  - 查看: tail -100 /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/cesm.log.*
  - 查看: tail -100 /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/atm.log.*
  - 常见错误: 输入文件缺失、磁盘空间不足、内存不足

TROUBLESHOOT

echo ""
echo "======================================================================"
echo "现在请按照上述步骤逐一执行,每步完成后检查结果"
echo "======================================================================"
