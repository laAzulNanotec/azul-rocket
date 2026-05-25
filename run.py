#!/usr/bin/env python3
"""
run.py — top-level entry point for the azul-rocket solar optimizer.

Generates all reference plots for Chapter 12 and saves them to ./images/.
Run from the repo root:

    python run.py                                       # Petén baseline, default 180W 24V panels
    python run.py --site kohala                         # different site
    python run.py --panel lensun_400_48                 # use the old 400W 48V panels
    python run.py --panel lensun_100_12                 # maximum coverage with 100W 12V
    python run.py --compare-panels                      # print catalog table only
    python run.py --all-sites --no-show                 # batch every site

The model treats panels as flat for the harvest calculation. The actual
3D placement (panel tilt on the arc, edge clearances, conduit routing,
CFD-coupled shading) is done in Autodesk Inventor. This module gives you
the headline kWh number; Inventor gives you the buildable layout.

For interactive exploration, use the notebook in notebooks/ or import
directly:

    from python.solar_optimizer import plot_all_dome_shapes, panel_layout
    plot_all_dome_shapes(width_ft=7.5)
    print(panel_layout('lensun_180_24'))
"""

import argparse
import os
import sys

# Make python/ importable
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, 'python'))

from solar_optimizer import (   # noqa: E402
    run_full_study, plot_all_dome_shapes, plot_hourly_harvest,
    plot_shape_comparison, plot_site_comparison, plot_3d_dome,
    hourly_harvest, panel_layout, compare_panels,
    SITES, SHAPES, PANELS, DEFAULT_PANEL,
)


def main():
    ap = argparse.ArgumentParser(
        description='Generate Chapter 12 reference plots',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    ap.add_argument('--site', default='peten',
                    choices=list(SITES.keys()),
                    help='Canyon site for solar harvest calculation')
    ap.add_argument('--shape', default='low120',
                    choices=list(SHAPES.keys()),
                    help='Vault shape')
    ap.add_argument('--panel', default=DEFAULT_PANEL,
                    choices=list(PANELS.keys()),
                    help='Solar panel model (auto-fits layout on roof)')
    ap.add_argument('--width', type=float, default=7.5,
                    help='Trailer width in feet')
    ap.add_argument('--length', type=float, default=24,
                    help='Trailer length in feet')
    ap.add_argument('--floor', type=float, default=4.0,
                    help='Flat floor height in feet')
    ap.add_argument('--panels-north', type=int, default=2,
                    help='North-face panels')
    ap.add_argument('--derate', type=float, default=0.87,
                    help='System derating factor')
    ap.add_argument('--save-dir', default='images',
                    help='Output directory for PNG files')
    ap.add_argument('--no-show', action='store_true',
                    help='Save plots to disk without opening a viewer')
    ap.add_argument('--all-sites', action='store_true',
                    help='Generate full study for every site')
    ap.add_argument('--compare-panels', action='store_true',
                    help='Print panel-vs-panel coverage table and exit')
    args = ap.parse_args()

    save_root = os.path.join(HERE, args.save_dir)
    os.makedirs(save_root, exist_ok=True)

    if args.no_show:
        import matplotlib
        matplotlib.use('Agg')

    # Panel comparison mode — just print the table
    if args.compare_panels:
        print(f'\nPanel coverage comparison '
              f'(width={args.width} ft, length={args.length} ft, shape={args.shape}):')
        compare_panels(width_ft=args.width, length_ft=args.length,
                       shape=args.shape)
        return

    common_kw = dict(
        width_ft=args.width,
        length_ft=args.length,
        floor_h_ft=args.floor,
        panel=args.panel,
        n_north=args.panels_north,
        derate=args.derate,
        show=not args.no_show,
    )

    if args.all_sites:
        for site in SITES.keys():
            site_dir = os.path.join(save_root, site)
            os.makedirs(site_dir, exist_ok=True)
            print(f'\n>>> Generating study for {SITES[site]["name"]}...')
            run_full_study(site=site, save_dir=site_dir, **common_kw)
    else:
        run_full_study(site=args.site, save_dir=save_root, **common_kw)


if __name__ == '__main__':
    main()
