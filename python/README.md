# python/

The solar harvest optimizer and dome shape generator.

## Files

- `solar_optimizer.py` — main module. Pure Python (numpy + matplotlib). No special install beyond `pip install -r ../requirements.txt`.

## Quick reference

```python
from solar_optimizer import run_full_study, plot_all_dome_shapes, hourly_harvest

# All 5 vault shapes
plot_all_dome_shapes(width_ft=7.5, floor_h_ft=4.0)

# Compute harvest for one config
h = hourly_harvest(site='peten', shape='low120',
                   n_long=4, n_row=2, n_north=2, derate=0.87)
print(h['E_day'], h['E_year'])

# Run everything and save plots
run_full_study(site='peten', save_dir='plots/')
```

## API

| Function | Returns |
|----------|---------|
| `compute_geometry(width_ft, floor_h_ft, shape)` | dict with `x_arc`, `y_arc`, `R`, `apex`, `rise`, `arc_len` |
| `hourly_harvest(site, shape, n_long, n_row, n_north, derate)` | dict with `P_arc`, `P_north`, `E_day`, `E_year` |
| `plot_dome(ax, geom, ...)` | matplotlib axis |
| `plot_all_dome_shapes(...)` | figure (2×3 grid) |
| `plot_hourly_harvest(site, shape, ...)` | (fig, harvest_dict) |
| `plot_shape_comparison(site, ...)` | figure (horizontal bar chart) |
| `plot_site_comparison(shape, ...)` | figure (daily + annual side by side) |
| `plot_3d_dome(shape, ...)` | matplotlib 3D figure |
| `run_full_study(site, save_dir, ...)` | dict (all results) |

## Sites and shapes

```python
SITES  = {'peten', 'kohala', 'austin', 'california'}
SHAPES = {'semi180', 'low120', 'raised240', 'gothic', 'catenary'}
```

Add your own to `SITES` dict at runtime:

```python
from solar_optimizer import SITES
SITES['atacama'] = {'name': 'Atacama, Chile', 'lat': -24.0,
                    'psh': 7.5, 'albedo': 0.55, 'canyon': 80}
```
