# cfd/

Computational fluid dynamics simulation files for Autodesk CFD (also compatible with ANSYS Fluent, OpenFOAM, SimScale).

## Two studies

### 1. Forming simulation (`forming/`)

Predicts the dome shape produced during hydrostatic forming. Inputs: pool diameter, initial water depth, oil layer thickness, clay disc thickness and density, balloon stretch modulus, drain orifice diameter. Output: final dome geometry vs total water drained.

### 2. External aerodynamics (`external/`)

Steady-state flow around the finished trailer. Inputs: full STL geometry from `../cad/full_trailer.stl`, wind speeds 0–30 m/s, wind angles 0°–180°. Outputs: drag, lift, downforce, yaw moment, surface pressure map.

## Boundary conditions

- **Forming inlet:** static head from water column
- **Forming outlet:** drain orifice with controlled mass flow
- **External inlet:** uniform velocity profile, turbulence intensity 1%
- **External outlet:** zero gauge pressure
- **Walls:** no-slip on trailer surfaces, slip on far-field
- **Domain size:** 5× trailer length upstream, 10× downstream, 3× height above

## Status

CFD setup files will be added when the Autodesk CFD evaluation runs are complete. Current status: STL geometry exports tested, simulation setup pending.
