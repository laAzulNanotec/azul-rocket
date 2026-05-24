# matlab/

MATLAB tools for trailer geometry, interactive design, and CAD export.

**Requirements:** MATLAB R2019b or later. No toolboxes required.

## Files

| File | Purpose |
|------|---------|
| `trailer_geometry.m` | Standalone script — generates 2D cross-section, side profile, 3D perspective, and exports CSV of profile points for CAD import. Run section-by-section with Ctrl+Enter. |
| `TrailerVaultApp2.m` | Interactive App Designer GUI. All parameters as sliders. Live updates of cross-section, hourly harvest, and shape comparison. |
| `export_parabolic_endcap.m` | Generates STL, point-cloud CSV, rib CSV, and DXF for Autodesk Inventor / Fusion 360 / CFD import. |

## Quick start

```matlab
cd matlab
trailer_geometry        % 3 figures + CSV export
TrailerVaultApp2        % interactive GUI
export_parabolic_endcap % STL/DXF for CAD/CFD
```

## What `trailer_geometry` produces

- Cross-section drawing with 120° arc, walls, shoulder splines, panel placement, sun arrows
- Side profile showing barrel vault + parabolic south end
- 3D perspective with CF ribs and longitudinal stringers
- Console output: arc radius, solar harvest estimate (Petén baseline), structural specs
- `trailer_xsec_profile.csv` — spline points for SolidWorks/Fusion 360 import

## What `TrailerVaultApp2` shows

Three live axes:

1. **Cross-section** — vault shape responds to width / floor / vault preset
2. **Hourly harvest by face** — kW by face across 6h–18h
3. **Shape comparison** — daily kWh for all 5 vault geometries

Plus a KPI strip (total panels, peak kW, daily harvest, north bonus, annual yield) and footer with running summary text.

## CAD/CFD export

`export_parabolic_endcap` generates five files:

- `parabolic_endcap.stl` — STL mesh for Inventor / Fusion 360 / CFD
- `parabolic_endcap_pts.csv` — point cloud for loft surface
- `parabolic_endcap_ribs.csv` — guide curves for Inventor loft
- `parabolic_profile.dxf` — 2D profile for Inventor sketch (revolve or sweep)
- `full_trailer.stl` — complete closed body for CFD airflow modeling

## Notes

- Older MATLAB versions (pre-R2019b) may lack `uiaxes` or `registerApp` and the GUI will fail. Use the standalone scripts in that case.
- On Windows, the file name must match the classdef name exactly (case-sensitive): `TrailerVaultApp2.m` runs as `>> TrailerVaultApp2`.
- For non-Unicode-safe MATLAB versions, search-and-replace `°` → `deg` and `☀` → `SUN` in the scripts.
