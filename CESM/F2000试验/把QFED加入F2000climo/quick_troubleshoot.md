# CESM运行问题快速排查清单

## 你需要在服务器上运行以下命令来诊断问题:

### 1. 首先运行诊断脚本
```bash
cd /share/home/ywliu/lxyyy/
bash diagnose_cesm.sh > cesm_diagnosis.txt 2>&1
cat cesm_diagnosis.txt
```

### 2. 快速检查关键路径

```bash
# 检查case是否创建
ls -la /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control/

# 如果存在,查看日志
ls -lht /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control/*.log

# 查看最新的错误
tail -100 /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control/case.*.log
```

### 3. 检查脚本执行状态

```bash
# 查看你的csh脚本最后是否执行完成
echo $?  # 在运行完F2000_control.csh后立即执行

# 或者查看是否有core dump或错误文件
ls -la /share/home/ywliu/lxyyy/*.err
ls -la /share/home/ywliu/lxyyy/*.out
```

## 最可能的问题场景:

### 场景A: create_newcase就失败了
**症状:** /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control/ 目录不存在

**可能原因:**
1. CESM路径不对
2. 机器配置 'hpcc' 不存在
3. 权限问题

**排查:**
```bash
# 检查CESM是否存在
ls /share/home/minghuai/yliang/model/CESM2-release-2.1.0/cime/scripts/

# 检查可用的机器配置
cd /share/home/minghuai/yliang/model/CESM2-release-2.1.0/cime/scripts/
./query_config --machines

# 如果hpcc不在列表中,需要使用其他机器名或添加配置
```

### 场景B: case.setup失败
**症状:** case目录存在,但没有CaseDocs/目录或不完整

**排查:**
```bash
cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control/
ls -la
cat case.setup.log  # 如果存在
```

### 场景C: case.build失败
**症状:** case setup完成,但编译失败

**排查:**
```bash
# 查看编译日志
ls -la /share/home/ywliu/lxyyy/scratch/runout/F2000_control/bld/
tail -200 /share/home/ywliu/lxyyy/scratch/runout/F2000_control/bld/cesm.bldlog

# 查看是否有编译错误
grep -i "error" /share/home/ywliu/lxyyy/scratch/runout/F2000_control/bld/*.log
```

### 场景D: case.submit失败或没有运行
**症状:** 编译成功,但作业没有提交或没有输出

**排查:**
```bash
# 检查作业队列
squeue -u $(whoami)
# 或
qstat -u $(whoami)

# 检查是否有运行日志
ls -lh /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/

# 如果有日志,查看
tail -100 /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/cesm.log.*
```

## 推荐的排查顺序:

### Step 1: 确认脚本执行到哪一步
```bash
# 在F2000_control.csh中每个关键步骤后添加echo
# 例如:
#!/bin/csh -fx
...
echo "DEBUG: Starting create_newcase"
./create_newcase ...
echo "DEBUG: create_newcase completed with status: $status"

echo "DEBUG: Starting xmlchange commands"
./xmlchange ...
echo "DEBUG: xmlchange completed"

# 然后重新运行脚本
```

### Step 2: 手动逐步执行
如果自动脚本有问题,使用manual_run_guide.sh中的步骤手动执行

### Step 3: 检查特定错误

```bash
# 查找所有错误信息
find /share/home/ywliu/lxyyy/scratch/ -name "*.log" -exec grep -l "ERROR\|Error\|error" {} \;

# 查看最近修改的文件
find /share/home/ywliu/lxyyy/scratch/ -type f -mmin -60 -ls
```

## 需要你提供的信息:

请在服务器上运行以下命令并把结果发给我:

```bash
# 1. 检查基本状态
echo "=== Case目录 ==="
ls -la /share/home/ywliu/lxyyy/scratch/cesmrun/ 2>&1

echo "=== Run目录 ==="
ls -la /share/home/ywliu/lxyyy/scratch/runout/ 2>&1

# 2. 如果case目录存在
echo "=== Case内容 ==="
ls -la /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control/ 2>&1

# 3. 查看最新日志
echo "=== 最新日志 ==="
find /share/home/ywliu/lxyyy/scratch/ -name "*.log" -mmin -120 -exec ls -lh {} \; 2>&1

# 4. 检查作业队列
echo "=== 作业状态 ==="
squeue -u $(whoami) 2>&1 || qstat -u $(whoami) 2>&1

# 5. 查看任何错误消息
echo "=== 错误搜索 ==="
find /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control -name "*.log" -exec tail -20 {} \; 2>&1 | grep -i error
```

## 关于QFED的问题

如果control实验都跑不起来,先不要考虑加QFED。应该:
1. 先让control实验成功运行
2. 确认输出正常
3. 再基于成功的control添加QFED

加QFED时只需要修改user_nl_cam,其他配置保持不变。
