#!/usr/bin/env python3
"""
run.py — top-level entry point for the azul-rocket solar optimizer.

Generates all reference plots for Chapter 12 and saves them to ./images/.
Run from the repo root:

    python run.py                  # default: Petén baseline
    python run.py --site kohala    # different site
    python run.py --site austin --width 8.0 --panels 6
    python run.py --all-sites      # generate for every site

For interactive exploration, use the notebook in notebooks/ or import
directly:

    from python.solar_optimizer import plot_all_dome_shapes
    plot_all_dome_shapes(width_ft=7.5)
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
    hourly_harvest, SITES, SHAPES,
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
    ap.add_argument('--width', type=float, default=7.5,
                    help='Trailer width in feet')
    ap.add_argument('--length', type=float, default=24,
                    help='Trailer length in feet')
    ap.add_argument('--floor', type=float, default=4.0,
                    help='Flat floor height in feet')
    ap.add_argument('--panels-long', type=int, default=4,
                    help='Panels along length')
    ap.add_argument('--panels-row', type=int, default=2,
                    help='Panel rows on arc')
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
    args = ap.parse_args()

    save_root = os.path.join(HERE, args.save_dir)
    os.makedirs(save_root, exist_ok=True)

    if args.no_show:
        import matplotlib
        matplotlib.use('Agg')

    if args.all_sites:
        for site in SITES.keys():
            site_dir = os.path.join(save_root, site)
            os.makedirs(site_dir, exist_ok=True)
            print(f'\n>>> Generating study for {SITES[site]["name"]}...')
            run_full_study(
                site=site,
                width_ft=args.width,
                floor_h_ft=args.floor,
                n_long=args.panels_long,
                n_row=args.panels_row,
                n_north=args.panels_north,
                derate=args.derate,
                save_dir=site_dir,
                show=not args.no_show,
            )
    else:
        run_full_study(
            site=args.site,
            width_ft=args.width,
            floor_h_ft=args.floor,
            n_long=args.panels_long,
            n_row=args.panels_row,
            n_north=args.panels_north,
            derate=args.derate,
            save_dir=save_root,
            show=not args.no_show,
        )


if __name__ == '__main__':
    main()
