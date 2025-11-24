# CESM火灾排放研究 - 完整文件包

## 📦 文件清单

### 📘 文档类

1. **COMPLETE_WORKFLOW.md** - 完整流程指南
   - 详细的分步骤操作说明
   - 时间安排建议
   - 常见问题排查
   - 完成检查清单

2. **fire_variables_guide.txt** - 火灾相关变量完整指南
   - 所有可用变量列表
   - 变量命名规则
   - 推荐配置方案

### 🔧 CESM模式脚本 (在校服ywliu用户运行)

3. **F2000_control.csh** - Control试验脚本
   - 无火灾排放的基准模拟
   - 用于对比分析

4. **F2000_QFED.csh** - QFED试验脚本
   - 包含QFED火灾排放
   - 主要研究对象

### 🐍 Python分析脚本 (在组服zzsun用户运行)

5. **check_qfed.py** - QFED数据检查工具
   - 验证文件完整性
   - 查看变量信息
   - 生成CESM配置建议

6. **analyze_cesm_output.py** - CESM输出分析脚本
   - 加载和处理模式输出
   - 生成对比图
   - 区域统计分析

7. **install_conda_onestep.sh** - Conda一键安装脚本
   - 自动安装Miniconda
   - 无需手动交互
   - 适配老系统

## 🚀 快速开始

### 第一步: 环境准备 (组服)

```bash
# 在组服 zzsun用户
bash install_conda_onestep.sh
source ~/.bashrc
conda create -n cesm_analysis python=3.8 -y
conda activate cesm_analysis
conda install -c conda-forge netcdf4 xarray matplotlib cartopy -y
```

### 第二步: 数据检查 (组服)

```bash
# 检查QFED数据
conda activate cesm_analysis
python check_qfed.py /work13/zzsun/lxy_data/QFED/ --check-dir
python check_qfed.py /work13/zzsun/lxy_data/QFED/qfed2.emis_bc.061.20180701.nc4
```

### 第三步: 运行Control试验 (校服)

```bash
# 在校服 ywliu用户
cd /share/home/ywliu/lxyyy/scripts
csh F2000_control.csh

# 监控
bjobs
tail -f /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/cesm.log.*
```

### 第四步: 运行QFED试验 (校服)

```bash
# 确保Control成功后
csh F2000_QFED.csh

# 监控
bjobs
tail -f /share/home/ywliu/lxyyy/scratch/runout/F2000_QFED_201807/run/cesm.log.*
```

### 第五步: 分析结果 (组服)

```bash
# 在组服 zzsun用户
conda activate cesm_analysis
cd /work13/zzsun/cesm_analysis/scripts
python analyze_cesm_output.py
```

## 📊 文件用途详解

### F2000_control.csh
- **用途**: 创建和运行无火灾排放的基准模拟
- **输出**: `/share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/*.nc`
- **运行时间**: ~30-40分钟(3天模拟)

### F2000_QFED.csh
- **用途**: 创建和运行含QFED火灾排放的模拟
- **关键配置**: `srf_emis_specifier` 指定QFED文件
- **输出**: `/share/home/ywliu/lxyyy/scratch/runout/F2000_QFED_201807/run/*.nc`
- **验证**: 检查`SFbc_a4`和`SFpom_a4`是否有非零值

### check_qfed.py
- **功能1**: 检查文件完整性
  ```bash
  python check_qfed.py /path/to/qfed/ --check-dir
  ```
- **功能2**: 查看详细信息
  ```bash
  python check_qfed.py /path/to/qfed/file.nc4
  ```

### analyze_cesm_output.py
- **功能**: 全面分析Control vs QFED
- **输出**: 
  - 对比图: BC排放、浓度、AOD
  - 区域统计
  - 时间序列
- **位置**: `/work13/zzsun/cesm_analysis/figures/`

## ⚠️ 重要注意事项

### 1. 路径检查
- QFED数据: `/work13/zzsun/lxy_data/QFED/`
- 确保ywliu用户可以访问此路径

### 2. 变量名拼写
- ❌ `dut_a3_num` (错误)
- ✅ `dst_a3_num` (正确)

### 3. QFED配置
- 变量名必须是 `:biomass`
- 单位已验证为 `kg s-1 m-2` (正确)
- 文件名模式: `%y%m%d` 会自动替换

### 4. 输出变量
- 所有变量都已验证存在于F2000climo
- 不要使用不存在的变量(如`CO`、`AODBC`)
- 参考 `fire_variables_guide.txt`

## 📈 预期结果

### Control vs QFED 应该看到:
- ✅ `SFbc_a4`, `SFpom_a4` 在火灾区域明显增加
- ✅ `bc_a4_SRF`, `pom_a4_SRF` 浓度升高
- ✅ `AODPOM` 光学厚度增加
- ✅ `PM25` 浓度上升
- ✅ `SWCF` 辐射强迫变化

### 关键验证点:
1. **排放生效**: `SFbc_a4` > 0 在火灾区域
2. **浓度响应**: `bc_a4_SRF` QFED > Control
3. **光学效应**: `AEROD_v` QFED > Control
4. **空间分布**: 火灾活跃区域(亚马逊、加州、西伯利亚等)

## 🆘 遇到问题?

### 常见问题快速索引

1. **Conda安装失败** → 使用 `install_conda_onestep.sh -b` 批量模式
2. **CESM运行17秒失败** → 检查变量名拼写
3. **找不到QFED文件** → 检查路径和权限
4. **SFbc_a4全为零** → 检查`srf_emis_specifier`配置
5. **Python无法读取nc文件** → 重装netCDF4

详细排查方法见 `COMPLETE_WORKFLOW.md` 的"常见问题排查"章节

## 📞 技术支持

- 完整流程: 参考 `COMPLETE_WORKFLOW.md`
- 变量问题: 参考 `fire_variables_guide.txt`
- QFED数据: 使用 `check_qfed.py`
- 分析方法: 参考 `analyze_cesm_output.py` 中的注释

## ✅ 完成标志

### 运行成功:
- [ ] Control有输出文件 `*.cam.h0.*.nc`
- [ ] QFED有输出文件
- [ ] `SFbc_a4` 有非零值
- [ ] 能生成对比图

### 科学结果:
- [ ] 排放空间分布合理
- [ ] 浓度响应符合预期
- [ ] 辐射效应有物理意义
- [ ] 可以撰写研究报告

---

**版本**: 2025-11-24
**作者**: lxy

会成功的! 🔥🌍🎉
