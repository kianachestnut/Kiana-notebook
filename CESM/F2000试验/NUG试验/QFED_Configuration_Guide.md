# CESM QFED火灾排放配置说明

## 主要修改内容

### 1. 案例名称修改
```csh
setenv CASE    F2000_QFED_201807  # 从F2000_control改为明确标识有QFED的名称
```

### 2. user_nl_cam中的关键配置

#### 方案A: 使用srf_emis_specifier (地表排放 - 推荐)
```
srf_emis_specifier = 'bc_a4  -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_bc.061.%y%m%d.nc4',
                     'pom_a4 -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_oc.061.%y%m%d.nc4',
                     'SO2    -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_so2.061.%y%m%d.nc4',
                     'CO     -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_co.061.%y%m%d.nc4',
                     'NO     -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_no.061.%y%m%d.nc4'
```

#### 方案B: 使用ext_frc_specifier (外部强迫 - 可包含垂直分布)
```
ext_frc_type = 'SERIAL'
ext_frc_cycle_yr = 2018
ext_frc_specifier = 'bc_a4  -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_bc.061.%y%m%d.nc4',
                    'pom_a4 -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_oc.061.%y%m%d.nc4',
                    'SO2    -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_so2.061.%y%m%d.nc4'
```

## 关键注意事项

### 1. QFED文件格式要求
**必须检查的内容:**
```bash
# 在服务器上运行以下命令检查文件
module load netcdf  # 或类似命令加载netcdf
ncdump -h /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_bc.061.20180701.nc4
```

检查项目:
- [ ] 变量名称 (可能是'biomass', 'emission', 'emis_flux'等)
- [ ] 维度顺序 (应该是 time, lat, lon 或 time, lev, lat, lon)
- [ ] 单位 (应该是 kg/m2/s)
- [ ] 时间维度格式

### 2. CESM物种名称映射

QFED变量 -> CESM变量 (F2000climo/CAM6-chem):
- bc  -> bc_a4  (黑碳气溶胶模态4)
- oc  -> pom_a4 (有机碳气溶胶模态4)
- so2 -> SO2    (二氧化硫)
- co  -> CO     (一氧化碳)
- no  -> NO     (一氧化氮)

### 3. 文件名模式
```
%y%m%d 会被CESM自动替换为实际日期
例如: 2018年7月1日 -> 20180701
```

### 4. 时间设置一致性
确保以下设置一致:
```csh
./xmlchange --file env_run.xml --id RUN_STARTDATE --val '2018-07-01'
ext_frc_cycle_yr = 2018  # 在user_nl_cam中
```

## 诊断输出变量

在fincl1中添加了火灾相关诊断变量:
```
'bc_a4'    # 黑碳混合比
'pom_a4'   # 有机碳混合比
'SO4_a1'   # 硫酸盐 (SO2氧化产物)
'SFBC'     # 黑碳地表通量
'SFPOM'    # 有机碳地表通量
'SFSO4'    # 硫酸盐地表通量
```

## 常见问题排查

### 问题1: 模式找不到QFED文件
**症状:** 错误信息类似 "Cannot find file: qfed2.emis_bc..."

**解决方案:**
1. 检查文件路径是否正确
2. 确保文件名格式完全匹配,包括日期部分
3. 检查权限: `ls -l /share/home/ywliu/lxyyy/data/QFED/`

### 问题2: 变量名不匹配
**症状:** 错误信息类似 "Variable 'biomass' not found"

**解决方案:**
需要修改srf_emis_specifier,添加变量映射:
```
srf_emis_specifier = 'bc_a4 -> /path/to/file:variable_name_in_file'
```

例如,如果QFED文件中变量名是'biomass':
```
srf_emis_specifier = 'bc_a4 -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_bc.061.%y%m%d.nc4:biomass'
```

### 问题3: 单位不正确
**症状:** 排放值异常大或异常小

**解决方案:**
CESM期望单位: kg/m2/s
如果QFED是其他单位(如 kg/m2/day),需要转换文件或在代码中处理

## 验证步骤

运行前验证:
```bash
# 1. 检查QFED文件完整性
ls /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_bc.061.201807*.nc4
# 应该看到7月1-31日所有文件

# 2. 检查案例配置
cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_QFED_201807
cat CaseDocs/atm_in | grep -A5 srf_emis
```

运行后检查:
```bash
# 查看输出文件
ls /share/home/ywliu/lxyyy/scratch/runout/F2000_QFED_201807/run/*.cam.h0.*

# 使用ncview或其他工具查看bc_a4, pom_a4等变量
# 火灾区域应该有明显的排放信号
```

## 高级配置 (可选)

### 添加更多QFED物种
如果需要其他物种:
```
srf_emis_specifier = 'bc_a4  -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_bc.061.%y%m%d.nc4',
                     'pom_a4 -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_oc.061.%y%m%d.nc4',
                     'SO2    -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_so2.061.%y%m%d.nc4',
                     'CO     -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_co.061.%y%m%d.nc4',
                     'NO     -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_no.061.%y%m%d.nc4',
                     'NH3    -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_nh3.061.%y%m%d.nc4'
```

### 排放注入高度配置
如果需要指定垂直分布(需要修改源代码或使用特定格式):
```
! 这通常需要QFED文件包含垂直层信息
! 或者使用默认的火灾烟羽注入参数化方案
```

## 对照试验建议

建议运行两个案例进行对比:
1. **F2000_control** - 无QFED排放(背景场)
2. **F2000_QFED_201807** - 加入QFED排放

对比分析:
- AOD差异
- BC/OC浓度差异
- 降水和温度响应
- 辐射强迫

## 下一步工作

1. 先运行3天测试,确认配置正确
2. 检查输出文件中的排放信号
3. 如果正常,可以延长运行时间
4. 分析火灾排放的气候影响

## 参考资料

CESM排放配置文档:
- https://www.cesm.ucar.edu/models/cesm2/config/compsets.html
- CAM6化学用户手册

QFED数据说明:
- https://portal.nccs.nasa.gov/datashare/iesa/aerosol/emissions/QFED/
