#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
CESM Output Analysis Script
Process CESM fire emission simulation outputs

Usage:
    conda activate cesm_analysis
    python analyze_cesm_output.py
"""

import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from pathlib import Path

# Configuration
CONTROL_DIR = "/share/home/ywliu/lxyyy/scratch/runout/F2000_control/run"
QFED_DIR = "/share/home/ywliu/lxyyy/scratch/runout/F2000_QFED_201807/run"
OUTPUT_DIR = "/work13/zzsun/cesm_analysis/figures"

# Or if using soft link
# CONTROL_DIR = "/work13/zzsun/cesm_output/ywliu_runs/F2000_control/run"
# QFED_DIR = "/work13/zzsun/cesm_output/ywliu_runs/F2000_QFED_201807/run"

def load_cesm_data(data_dir, case_name, start_date='2018-07-01', end_date='2018-07-31'):
    """
    Load CESM output data
    
    Parameters:
    -----------
    data_dir : str
        Directory containing CESM output files
    case_name : str
        Case name (e.g., 'F2000_control')
    start_date, end_date : str
        Date range to load
        
    Returns:
    --------
    ds : xarray.Dataset
        Loaded dataset
    """
    
    # Find all cam.h0 files
    files = sorted(Path(data_dir).glob(f"{case_name}.cam.h0.*.nc"))
    
    if not files:
        print(f"No files found in {data_dir}")
        return None
    
    print(f"Found {len(files)} files")
    print(f"Loading data from {start_date} to {end_date}...")
    
    # Load with xarray
    ds = xr.open_mfdataset(files, combine='by_coords')
    
    # Select time range
    ds = ds.sel(time=slice(start_date, end_date))
    
    print(f"Loaded shape: {ds.dims}")
    print(f"Variables: {list(ds.data_vars)[:10]}...")
    
    return ds

def plot_fire_emissions(ds_control, ds_qfed, variable='SFbc_a4', day='2018-07-15'):
    """
    Plot fire emission comparison
    
    Parameters:
    -----------
    ds_control : xarray.Dataset
        Control simulation
    ds_qfed : xarray.Dataset  
        QFED simulation
    variable : str
        Variable to plot (e.g., 'SFbc_a4', 'AODPOM')
    day : str
        Date to plot
    """
    
    # Create output directory
    Path(OUTPUT_DIR).mkdir(parents=True, exist_ok=True)
    
    # Extract data for specific day
    data_control = ds_control[variable].sel(time=day, method='nearest')
    data_qfed = ds_qfed[variable].sel(time=day, method='nearest')
    
    # Calculate difference
    diff = data_qfed - data_control
    
    # Create figure with 3 panels
    fig = plt.figure(figsize=(18, 5))
    
    # Define projection
    proj = ccrs.PlateCarree()
    
    # Panel 1: Control
    ax1 = fig.add_subplot(131, projection=proj)
    data_control.plot(ax=ax1, transform=proj, cmap='YlOrRd', 
                     cbar_kwargs={'label': f'{variable} ({ds_control[variable].units})'})
    ax1.coastlines()
    ax1.add_feature(cfeature.BORDERS, linestyle=':')
    ax1.set_title(f'Control - {day}')
    ax1.gridlines(draw_labels=True)
    
    # Panel 2: QFED
    ax2 = fig.add_subplot(132, projection=proj)
    data_qfed.plot(ax=ax2, transform=proj, cmap='YlOrRd',
                   cbar_kwargs={'label': f'{variable} ({ds_qfed[variable].units})'})
    ax2.coastlines()
    ax2.add_feature(cfeature.BORDERS, linestyle=':')
    ax2.set_title(f'QFED - {day}')
    ax2.gridlines(draw_labels=True)
    
    # Panel 3: Difference
    ax3 = fig.add_subplot(133, projection=proj)
    diff.plot(ax=ax3, transform=proj, cmap='RdBu_r', center=0,
              cbar_kwargs={'label': f'Difference ({ds_qfed[variable].units})'})
    ax3.coastlines()
    ax3.add_feature(cfeature.BORDERS, linestyle=':')
    ax3.set_title(f'QFED - Control')
    ax3.gridlines(draw_labels=True)
    
    plt.tight_layout()
    
    # Save figure
    output_file = Path(OUTPUT_DIR) / f'{variable}_{day.replace("-", "")}.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"Saved figure: {output_file}")
    
    plt.close()

def calculate_regional_mean(ds, variable, region='china'):
    """
    Calculate regional mean
    
    Parameters:
    -----------
    ds : xarray.Dataset
        Dataset
    variable : str
        Variable name
    region : str
        Region name ('china', 'amazon', 'global')
        
    Returns:
    --------
    regional_mean : xarray.DataArray
        Time series of regional mean
    """
    
    # Define regions
    regions = {
        'china': {'lat': slice(18, 54), 'lon': slice(73, 135)},
        'amazon': {'lat': slice(-20, 10), 'lon': slice(-80, -45)},
        'global': {}
    }
    
    # Select region
    if region != 'global':
        data = ds[variable].sel(**regions[region])
    else:
        data = ds[variable]
    
    # Calculate weighted mean by latitude
    weights = np.cos(np.deg2rad(data.lat))
    weighted_data = data.weighted(weights)
    regional_mean = weighted_data.mean(dim=['lat', 'lon'])
    
    return regional_mean

def main():
    """Main analysis workflow"""
    
    print("="*70)
    print("CESM Fire Emission Analysis")
    print("="*70)
    
    # Load data
    print("\n1. Loading Control simulation...")
    ds_control = load_cesm_data(CONTROL_DIR, 'F2000_control')
    
    print("\n2. Loading QFED simulation...")
    ds_qfed = load_cesm_data(QFED_DIR, 'F2000_QFED_201807')
    
    if ds_control is None or ds_qfed is None:
        print("Error: Could not load data")
        return
    
    # Plot fire emissions
    print("\n3. Plotting fire emissions...")
    plot_fire_emissions(ds_control, ds_qfed, 
                       variable='SFbc_a4', 
                       day='2018-07-15')
    
    # Calculate regional means
    print("\n4. Calculating regional means...")
    bc_control = calculate_regional_mean(ds_control, 'bc_a4_SRF', region='china')
    bc_qfed = calculate_regional_mean(ds_qfed, 'bc_a4_SRF', region='china')
    
    print(f"Control mean BC: {bc_control.mean().values:.2e} kg/kg")
    print(f"QFED mean BC: {bc_qfed.mean().values:.2e} kg/kg")
    print(f"Increase: {((bc_qfed.mean() - bc_control.mean()) / bc_control.mean() * 100).values:.1f}%")
    
    print("\n" + "="*70)
    print("Analysis complete!")
    print(f"Figures saved to: {OUTPUT_DIR}")
    print("="*70)

if __name__ == "__main__":
    main()
