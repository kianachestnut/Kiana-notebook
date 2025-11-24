# CESM运行失败诊断指南

## 当前状态
- ✅ Case创建成功
- ✅ 编译成功 (cesm.exe存在)
- ⚠️ 运行失败 (17秒后失败)

## 立即查看错误日志

### 1. 查看主日志
```bash
tail -200 /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/cesm.log.16186768.251124-194725
```

### 2. 查看大气模式日志
```bash
tail -200 /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/atm.log.16186768.251124-194725
```

### 3. 查看coupler日志
```bash
tail -100 /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/cpl.log.16186768.251124-194725
```

### 4. 搜索错误关键字
```bash
grep -i "error\|fail\|fatal\|abort" /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/*.log*
```

## 常见问题及解决方案

### 问题1: 找不到输入文件
**错误信息示例:**
```
ERROR: Could not find file: xxx.nc
ERROR: NetCDF: file not found
```

**解决方案:**
检查user_nl_cam中的文件路径是否正确:
```bash
cat /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control/user_nl_cam
```

特别检查:
- bnd_topo路径
- ncdata路径

验证文件是否存在:
```bash
ls -lh /share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/topo/fv_0.9x1.25_nc3000_Nsw042_Nrs008_Co060_Fi001_ZR_sgh30_24km_GRNL_c170103.nc

ls -lh /share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/inic/fv/f.e20.FCSD.f09_f09_mg17.cesm2.1-exp002.001.cam.i.2005-01-01-00000_c180801_32L.nc
```

### 问题2: Namelist变量名错误
**错误信息示例:**
```
ERROR: unknown variable in namelist: xxx
ERROR: Invalid namelist variable
```

**解决方案:**
检查user_nl_cam中的变量名是否正确。原始脚本中有个问题:

```fortran
fincl1 = 'bc_a1_num','dst_a1_num','dut_a3_num','PM25',
```

注意 `'dut_a3_num'` 应该是 `'dst_a3_num'` (dust不是dut)

修正后的user_nl_cam:
```bash
cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control

cat > user_nl_cam << 'EOF'

avgflag_pertape = 'A'
nhtfrq          = -24
mfilt           = 1

fincl1 = 'bc_a1_num','dst_a1_num','dst_a3_num','PM25',
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
```

然后重新提交:
```bash
cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control
./case.submit
```

### 问题3: 时间设置问题
**错误信息示例:**
```
ERROR: Initial file date does not match RUN_STARTDATE
```

**解决方案:**
检查初始场文件的日期是否与RUN_STARTDATE匹配。

初始场文件日期: 2005-01-01
运行开始日期: 2018-07-01

这个不匹配通常不是问题,除非compset有特殊要求。

### 问题4: MPI/并行问题
**错误信息示例:**
```
ERROR: MPI initialization failed
ERROR: Insufficient resources
```

**解决方案:**
检查是否请求了正确的CPU数:
```bash
cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control
./xmlquery NTASKS_ATM
./xmlquery NTASKS_CPL
```

### 问题5: 内存不足
**错误信息示例:**
```
ERROR: Cannot allocate memory
Segmentation fault
```

**解决方案:**
减少输出变量或减少CPU数。

## 修复后重新运行

### 方法1: 直接resubmit (如果只是临时问题)
```bash
cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control
./case.submit
```

### 方法2: 修改配置后重新运行
```bash
cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control

# 1. 修改user_nl_cam (如果需要)
vi user_nl_cam

# 2. 清理旧的运行文件
./case.submit --clean-all

# 3. 重新提交
./case.submit
```

### 方法3: 完全重新构建 (如果怀疑编译问题)
```bash
cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control

# 1. 清理编译
./case.build --clean-all

# 2. 重新编译
./case.build --skip-provenance-check

# 3. 提交
./case.submit
```

## 检查运行是否成功

成功的标志:
```bash
# 1. 检查是否有输出文件
ls -lh /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/*.cam.h0.*

# 2. 检查日志最后几行
tail -20 /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/cesm.log.*

# 应该看到类似:
# SUCCESSFUL TERMINATION OF CPL7-CCSM4
```

## 作业队列命令 (你的系统使用LSF)

```bash
# 查看作业状态
bjobs

# 查看详细信息
bjobs -l 16186768

# 如果作业还在运行,可以取消
bkill 16186768
```

## 最可能的问题

根据你的配置,我怀疑是 **user_nl_cam中的拼写错误**:
```
'dut_a3_num'  # 错误!
```
应该是:
```
'dst_a3_num'  # 正确 (dust)
```

请先查看日志确认,然后修复这个错误。
