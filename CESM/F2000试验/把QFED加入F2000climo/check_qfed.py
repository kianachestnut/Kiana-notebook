#!/usr/bin/env python3
"""
检查QFED文件格式是否符合CESM要求
使用方法: python check_qfed.py /path/to/qfed/file.nc4
"""

import sys
import netCDF4 as nc
import numpy as np
from datetime import datetime

def check_qfed_file(filepath):
    """检查QFED文件的格式和内容"""
    
    print("="*70)
    print(f"检查文件: {filepath}")
    print("="*70)
    
    try:
        # 打开文件
        ds = nc.Dataset(filepath, 'r')
        
        # 1. 检查维度
        print("\n1. 维度信息:")
        print("-"*70)
        for dim_name, dim in ds.dimensions.items():
            print(f"  {dim_name}: {len(dim)}")
        
        # 2. 检查变量
        print("\n2. 变量信息:")
        print("-"*70)
        for var_name, var in ds.variables.items():
            if var_name not in ['lat', 'lon', 'time', 'lev']:
                print(f"\n  变量名: {var_name}")
                print(f"    维度: {var.dimensions}")
                print(f"    形状: {var.shape}")
                if hasattr(var, 'units'):
                    print(f"    单位: {var.units}")
                if hasattr(var, 'long_name'):
                    print(f"    描述: {var.long_name}")
                
                # 检查数据统计
                data = var[:]
                print(f"    最小值: {np.nanmin(data):.6e}")
                print(f"    最大值: {np.nanmax(data):.6e}")
                print(f"    平均值: {np.nanmean(data):.6e}")
                print(f"    NaN数量: {np.isnan(data).sum()}")
        
        # 3. 检查时间维度
        print("\n3. 时间信息:")
        print("-"*70)
        if 'time' in ds.variables:
            time_var = ds.variables['time']
            print(f"  时间单位: {time_var.units if hasattr(time_var, 'units') else '未定义'}")
            print(f"  时间点数: {len(time_var)}")
            if len(time_var) > 0:
                print(f"  时间值: {time_var[:]}")
        
        # 4. 检查空间维度
        print("\n4. 空间维度:")
        print("-"*70)
        if 'lat' in ds.variables:
            lat = ds.variables['lat'][:]
            print(f"  纬度范围: {lat.min():.2f} 到 {lat.max():.2f}")
            print(f"  纬度点数: {len(lat)}")
        
        if 'lon' in ds.variables:
            lon = ds.variables['lon'][:]
            print(f"  经度范围: {lon.min():.2f} 到 {lon.max():.2f}")
            print(f"  经度点数: {len(lon)}")
        
        # 5. CESM兼容性检查
        print("\n5. CESM兼容性检查:")
        print("-"*70)
        
        issues = []
        warnings = []
        
        # 检查必需维度
        required_dims = ['lat', 'lon', 'time']
        for dim in required_dims:
            if dim not in ds.dimensions:
                issues.append(f"缺少必需维度: {dim}")
        
        # 检查排放变量
        emission_vars = []
        for var_name in ds.variables:
            if var_name not in ['lat', 'lon', 'time', 'lev']:
                emission_vars.append(var_name)
        
        if len(emission_vars) == 0:
            issues.append("未找到排放变量")
        else:
            print(f"  找到排放变量: {', '.join(emission_vars)}")
            
            # 检查单位
            for var_name in emission_vars:
                var = ds.variables[var_name]
                if hasattr(var, 'units'):
                    units = var.units
                    if 'kg' not in units.lower() or 'm-2' not in units and 'm^-2' not in units and 'm2' not in units:
                        warnings.append(f"变量 {var_name} 的单位可能不正确: {units} (期望: kg/m2/s 或类似)")
                else:
                    warnings.append(f"变量 {var_name} 缺少单位属性")
        
        # 打印问题
        if issues:
            print("\n  ⚠️  发现问题:")
            for issue in issues:
                print(f"    - {issue}")
        
        if warnings:
            print("\n  ⚠️  警告:")
            for warning in warnings:
                print(f"    - {warning}")
        
        if not issues and not warnings:
            print("  ✓ 文件格式看起来正常!")
        
        # 6. CESM配置建议
        print("\n6. 建议的CESM配置:")
        print("-"*70)
        
        print("\n在user_nl_cam中添加:")
        print("```")
        print("srf_emis_specifier = \\")
        
        # QFED到CESM的物种映射
        qfed_to_cesm = {
            'bc': 'bc_a4',
            'oc': 'pom_a4',
            'so2': 'SO2',
            'co': 'CO',
            'no': 'NO',
            'nh3': 'NH3'
        }
        
        file_base = filepath.replace('.nc4', '').replace('.nc', '')
        
        configs = []
        for qfed_name, cesm_name in qfed_to_cesm.items():
            # 构建文件路径模式
            file_pattern = file_base.replace(filepath.split('_')[-2], qfed_name)  # 替换物种名
            file_pattern = file_pattern.replace('20180701', '%y%m%d')  # 替换日期
            
            # 检查是否有对应的排放变量
            var_found = False
            for var in emission_vars:
                if qfed_name.lower() in var.lower() or var.lower() in qfed_name.lower():
                    configs.append(f"  '{cesm_name:8s} -> {file_pattern}.nc4'")
                    var_found = True
                    break
        
        if configs:
            print(",\n".join(configs))
        else:
            print("  # 请根据实际文件路径和物种修改")
            print(f"  'bc_a4  -> {file_base.replace('bc', '%species%').replace('20180701', '%y%m%d')}.nc4'")
        
        print("```")
        
        ds.close()
        
        print("\n" + "="*70)
        print("检查完成!")
        print("="*70)
        
        return len(issues) == 0
        
    except Exception as e:
        print(f"\n错误: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def check_qfed_directory(qfed_dir, start_date='20180701', end_date='20180731'):
    """检查QFED目录中文件的完整性"""
    
    import os
    from datetime import datetime, timedelta
    
    print("\n" + "="*70)
    print(f"检查QFED目录: {qfed_dir}")
    print(f"日期范围: {start_date} 到 {end_date}")
    print("="*70)
    
    # 要检查的物种
    species = ['bc', 'oc', 'so2', 'co', 'no']
    
    # 转换日期
    start = datetime.strptime(start_date, '%Y%m%d')
    end = datetime.strptime(end_date, '%Y%m%d')
    
    missing_files = []
    
    # 检查每个物种的每一天
    current = start
    while current <= end:
        date_str = current.strftime('%Y%m%d')
        
        for sp in species:
            filename = f"qfed2.emis_{sp}.061.{date_str}.nc4"
            filepath = os.path.join(qfed_dir, filename)
            
            if not os.path.exists(filepath):
                missing_files.append(filename)
        
        current += timedelta(days=1)
    
    if missing_files:
        print(f"\n⚠️  缺少 {len(missing_files)} 个文件:")
        for f in missing_files[:10]:  # 只显示前10个
            print(f"  - {f}")
        if len(missing_files) > 10:
            print(f"  ... 还有 {len(missing_files)-10} 个文件")
    else:
        print("\n✓ 所有文件完整!")
    
    print("\n" + "="*70)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("使用方法:")
        print("  检查单个文件: python check_qfed.py /path/to/qfed/file.nc4")
        print("  检查目录完整性: python check_qfed.py /path/to/qfed/dir/ --check-dir")
        sys.exit(1)
    
    filepath = sys.argv[1]
    
    if '--check-dir' in sys.argv:
        check_qfed_directory(filepath)
    else:
        success = check_qfed_file(filepath)
        sys.exit(0 if success else 1)
