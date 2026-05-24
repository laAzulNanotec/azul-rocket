# cad/

CAD geometry exports.

## What goes here

This folder is populated by running `matlab/export_parabolic_endcap.m`. It generates:

- `parabolic_endcap.stl` — STL mesh for the venturi end dome
- `parabolic_endcap_pts.csv` — point cloud for loft surface in Inventor
- `parabolic_endcap_ribs.csv` — rib cross-sections for Inventor guide curves
- `parabolic_profile.dxf` — 2D profile for Inventor sketch (revolve or sweep)
- `full_trailer.stl` — complete closed body for CFD import
- `trailer_xsec_profile.csv` — cross-section spline points (from trailer_geometry.m)

## Why not check in the binaries?

STL and DXF files regenerate from the MATLAB scripts in seconds. Keeping them out of git keeps the repo small and prevents merge conflicts on binary files. If you want the pre-generated baseline files, check the GitHub Releases page.
