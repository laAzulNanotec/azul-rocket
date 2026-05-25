# azul-rocket v.21

**Open-source design tools for a self-sufficient precision laboratory trailer.**

A barrel-vault mobile laboratory with solar harvest optimization, hydrostatically-formed clay+CF skin panels, and external wind generation. Designed for off-grid operation in canyon sites at low latitudes.

This is the companion code repository for *Chapter 12 — The Trailer* of the Sol Arc / Azul Maya technical reference.

!\[Five vault dome shapes](images/01\_all\_dome\_shapes.png)

\---

## What's here

|Path|Contents|
|-|-|
|`run.py`|**Top-level CLI** — generate every reference plot with one command|
|`python/`|`solar\_optimizer.py` — solar harvest model, vault geometry, 2D and 3D rendering|
|`matlab/`|`trailer\_geometry.m` (geometry script), `TrailerVaultApp2.m` (interactive GUI), `export\_parabolic\_endcap.m` (STL/DXF export for CAD/CFD)|
|`notebooks/`|Ready-to-run Google Colab notebook (clones the whole repo)|
|`images/`|Generated reference figures (Petén baseline, refreshed by `run.py`)|
|`cad/`|STL and DXF exports (populated by running the MATLAB export script)|
|`cfd/`|Autodesk CFD setup files (forming and external aerodynamics simulations)|
|`docs/`|Chapter 12 prose, design notes, build journal|

\---

## Quick start — solar optimizer (Python)

### Option A: Google Colab (zero install)

Open [`notebooks/solar\_optimizer\_chapter12.ipynb`](notebooks/solar_optimizer_chapter12.ipynb) in Colab:

[!\[Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/laAzulNanotec/azul-rocket/blob/main/notebooks/solar_optimizer_chapter12.ipynb)

The notebook clones this whole repo into Colab and runs everything from inside it — including the command-line entry point. No manual upload needed.

### Option B: Local Python

```bash
git clone https://github.com/laAzulNanotec/azul-rocket.git
cd azul-rocket
pip install -r requirements.txt

# Generate all 5 reference plots for the Petén baseline:
python run.py

# Or any site / vault / size:
python run.py --site kohala --shape semi180 --width 8.0
python run.py --site austin --panels-long 6 --panels-row 3

# Generate the full study for every site at once:
python run.py --all-sites --no-show
```

All output PNGs land in `images/` (or `images/<site>/` with `--all-sites`).

### Option C: Import as a Python module

```python
import sys; sys.path.insert(0, 'python')
from solar\_optimizer import run\_full\_study, plot\_all\_dome\_shapes

plot\_all\_dome\_shapes(width\_ft=7.5, floor\_h\_ft=4.0)
h = run\_full\_study(site='peten', save\_dir='plots/')
print(f"Annual yield: {h\['E\_year']:.2f} MWh")
```

\---

## Quick start — MATLAB tools

```matlab
% Static geometry + 3 figures + CSV export for CAD
cd matlab
trailer\_geometry

% Interactive GUI (App Designer, no toolboxes required, R2019b+)
TrailerVaultApp2

% Export STL + DXF for Inventor / Fusion / CFD import
export\_parabolic\_endcap
```

The interactive app gives you sliders for latitude, peak sun hours, albedo, canyon angle, trailer dimensions, panel configuration, and derating — with live cross-section, hourly harvest, and shape comparison plots.

\---

## The design

**Geometry:** 120° low-arc barrel vault, ∅90" cross-section, 290" length, 74" vertical walls with 45° impedance corners on the end frames. Semi-monocoque construction: 13 transverse ribs at 24" pitch + 13 longitudinal stringers (7 arc + 6 wall), all 2¼" × 2¼" carbon fiber square tube. Total: 104 standard 8-foot CF tubes.

**Skin:** 1.5mm clay shell + 0.75mm CF/epoxy laminate = 2.25mm composite wall. CTE-matched at 3.1 ppm/°C against the 2.0 ppm/°C CF tube frame — 3.4× safety factor against thermal cracking at 40°C daily swing.

**Forming process:** above-ground pool ($0 salvage) + pond liner ($40) + mineral oil layer ($24) + latex weather balloon membrane + spray-applied local clay + 3-layer CF wet layup. Water self-levels the mold surface; oil seals the clay; balloon eliminates membrane tearing; draining the pool parametrically controls dome curvature. Total tooling cost: under $200 per dome.

**Solar:** 4× Lensun 400W 48V flexible panels on the arc + 2× north-facing panels for canyon albedo reflection. Direct connection to 48V Sol Arc bus, one MPPT per panel, no series strings. At Petén baseline: \~10 MWh/year.

**Wind:** 2× 24" ducted axial fans on the exterior of the closed parabolic end domes. The long cylindrical trailer body channels wind from any direction around its surface, accelerating local flow at the dome centers. Cooling effect on solar panels recovers \~14% of thermal derating losses.

**Active aerodynamics:** deployable apex spoiler manages downforce at highway towing speeds (1,600 lbf at 60 mph reduced to safe hitch loads via servo-controlled flow separation).

\---

## Reference output

After running `python run.py` you get five publication-ready figures:

1. **All vault shapes** — cross-sections comparing semicircle, low arc 120°, raised 240°, gothic pointed, and catenary
2. **Hourly harvest curve** — power by face throughout the day
3. **Shape comparison** — daily kWh at the chosen site
4. **Site comparison** — Petén, Kohala, Austin, California for the same vault
5. **3D trailer rendering** — full perspective with ribs, stringers, panels

Sample numbers at Petén (16.5°N, 0.45 albedo, 120° low arc, 16 × Lensun 180W 24V in 8 series pairs):

|Metric|Value|
|-|-|
|Peak power|2.76 kW|
|Daily harvest|23.4 kWh|
|Annual yield|8.5 MWh|
|Roof coverage|63%|
|Best vault shape|Low arc 120°|

> The model computes harvest with panels treated as flat. \*\*The actual 3D placement\*\* — panel tilt on the arc, edge clearances, conduit routing, CFD-coupled shading — is done in Autodesk Inventor. This module gives you the headline kWh number; Inventor gives you the buildable layout.

## Panel selection

The harvest model now includes a panel catalog with realistic dimensions and computes how many actually fit on the 7.5 × 24 ft roof:

```bash
python run.py --compare-panels      # see all options
```

|Panel|Fits|Peak|Daily kWh|Topology|
|-|-|-|-|-|
|**Lensun 180W 24V** *(default)*|16|2.88 kW|23.4|8 series pairs → 48V bus|
|Lensun 150W 12V|20|3.00 kW|24.4|5 series quads → 48V bus|
|Lensun 100W 12V|28|2.80 kW|22.5|7 series quads → 48V bus|
|Lensun 400W 48V *(original)*|6|2.40 kW|20.2|direct to 48V bus, parallel|

The **24V series-pair topology** is the sweet spot: smaller panels fit more densely on the curved arc, conform better to the surface, and tolerate partial shade — while two panels in series produce 48V at the same current as one 48V panel, so the Sol Arc bus and MPPT topology are unchanged.

Try a different panel:

```bash
python run.py --panel lensun\_150\_12
python run.py --panel lensun\_400\_48 --site austin
```

\---

## Build your own

This design is parametric. Every input is exposed as a slider or function argument:

* **Site:** `peten` · `kohala` · `austin` · `california` or custom (lat, PSH, albedo, canyon angle)
* **Vault shape:** `semi180` · `low120` · `raised240` · `gothic` · `catenary`
* **Dimensions:** `width\_ft`, `length\_ft`, `floor\_h\_ft`
* **Panels:** `n\_long` (along length), `n\_row` (rows on arc), `n\_north` (canyon-reflection)
* **Derating:** `derate` (typical 0.85–0.92)

Change anything, re-run, and the plots regenerate. Use the MATLAB GUI for interactive exploration during the design phase; use the Python CLI for batch studies and chapter figures.

\---

## Background

The trailer is named for *Maya Blue* (Azul Maya) — the indigo-and-sepiolite pigment formulated by Maya artisans around 800 AD at Chichén Itzá. The same nano-channel clay mineral that locked indigo molecules into place a thousand years ago forms the structural skin of this trailer. We have substituted carbon fiber for the indigo binder, and ball valves for ritual fire, but the geometry of the channels and the patience of forming on water are the same.

This is the alchemists' method, brought into the present.

\---

## Status

This repository accompanies a research and writing project. The trailer is being prototyped in a backyard in northwest Austin in 2026. The first end-dome will be formed using the water/oil/clay/CF process described in the chapter, instrumented for thermal cycling, and characterized over 30 days before the full trailer build proceeds.

**Contributions welcome.** If you build your own variant — different vault angle, different site latitude, different fan configuration — please open an issue or PR with your numbers and plots. The point of the open repo is to spread the alchemy.

\---

## License

MIT — see [LICENSE](LICENSE).

## Citation

If you use these tools in published work, please cite:

> Chapter 12 — The Trailer, in \*Sol Arc / Azul Maya: A Unified Architecture for Precision, Power, and Silence\*. Available at https://github.com/laAzulNanotec/azul-rocket

