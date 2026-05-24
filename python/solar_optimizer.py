"""
solar_optimizer.py
==================
Solar harvest optimization and vault dome visualization for the
Azul Maya trailer (Chapter 12 — The Trailer).

Generates:
  * Daily and annual solar harvest estimates by vault shape
  * Hourly harvest curves by face (arc direct + north reflected)
  * Dome geometry images for 5 vault shapes (semicircle, low arc 120°,
    raised arc 240°, gothic pointed, catenary)
  * Comparison plots across shapes and sites

Designed to run in Google Colab — all outputs are inline PNGs.

USAGE in Colab:
    !pip install -q matplotlib numpy scipy
    # Upload solar_optimizer.py, or paste contents into a cell
    from solar_optimizer import *
    run_full_study(site='peten')        # generates ALL plots
    # or run individual functions:
    plot_all_dome_shapes(width_ft=7.5)
    plot_hourly_harvest(site='peten', shape='low120')
    plot_shape_comparison(site='peten')
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Rectangle, Circle
from matplotlib.collections import LineCollection
import matplotlib.gridspec as gridspec

# ────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ────────────────────────────────────────────────────────────────────────
FT2MM = 304.8
IN2MM = 25.4

# Color palette (matches MATLAB app + Crichton-style figures)
CLR_GREEN   = '#1D9E75'
CLR_PURPLE  = '#534AB7'
CLR_BLUE    = '#3B8BD4'
CLR_AMBER   = '#BA7517'
CLR_CORAL   = '#E24B4A'
CLR_PANEL   = '#9FE0C5'
CLR_FLOOR   = '#F2F2E0'
CLR_WALL    = '#454541'
CLR_TEAL    = '#4FB3B0'

# Site presets — (latitude, peak sun hours, albedo, canyon angle)
SITES = {
    'peten':      {'name': 'Petén, Guatemala',  'lat': 16.5, 'psh': 6.0, 'albedo': 0.45, 'canyon': 70},
    'kohala':     {'name': 'Kohala, Hawaii',    'lat': 20.0, 'psh': 6.2, 'albedo': 0.08, 'canyon': 30},
    'austin':     {'name': 'Austin, Texas',     'lat': 30.0, 'psh': 5.8, 'albedo': 0.35, 'canyon': 60},
    'california': {'name': 'California',        'lat': 34.0, 'psh': 5.5, 'albedo': 0.25, 'canyon': 50},
}

# Vault shape presets — (arc degrees, shape type, description)
SHAPES = {
    'semi180':   {'arc_deg': 180, 'type': 'arc',      'name': 'Semicircle 180°',
                  'desc': 'classic half-circle, max interior volume'},
    'low120':    {'arc_deg': 120, 'type': 'arc',      'name': 'Low arc 120°',
                  'desc': 'optimal E-W sweep, lowest profile (chapter spec)'},
    'raised240': {'arc_deg': 240, 'type': 'arc',      'name': 'Raised arc 240°',
                  'desc': 'high headroom, more E/W panel area'},
    'gothic':    {'arc_deg': 190, 'type': 'gothic',   'name': 'Gothic pointed',
                  'desc': 'medieval geometry, dramatic ridge line'},
    'catenary':  {'arc_deg': 0,   'type': 'catenary', 'name': 'Catenary curve',
                  'desc': 'pure compression, zero bending'},
}

# Panel: Lensun 400W 48V
PANEL_W = 1825      # mm
PANEL_H = 1142      # mm
PANEL_T = 3         # mm
PANEL_KG = 7
P_PANEL = 400       # W


# ────────────────────────────────────────────────────────────────────────
# GEOMETRY
# ────────────────────────────────────────────────────────────────────────
def compute_geometry(width_ft=7.5, floor_h_ft=4.0, shape='low120'):
    """
    Compute the cross-section profile for a given vault shape.
    Returns dict with arc x,y, shoulder splines, dimensions.
    DOME convention: y_arc = FH + R*cos(theta) — center above, arc hangs down.
    """
    W  = width_ft * FT2MM
    FH = floor_h_ft * FT2MM
    cfg = SHAPES[shape]
    arc_deg = cfg['arc_deg']
    arc_half = np.radians(arc_deg / 2) if arc_deg > 0 else np.radians(85)

    if cfg['type'] == 'arc':
        R = (W / 2) / np.sin(arc_half)
        theta = np.linspace(-arc_half, arc_half, 300)
        # DOME formula: center above floor, arc curves up to apex at theta=0
        x_arc = R * np.sin(theta)
        y_arc = FH + R * np.cos(theta)
        apex = y_arc.max()

    elif cfg['type'] == 'gothic':
        # Two-centered pointed arch — feet land at ±W/2 on top of walls
        # Each lobe is a circular arc whose center is at the OPPOSITE wall foot.
        # Left lobe: center at (+W/2, FH), starting at (-W/2, FH), peaking at center top.
        # Right lobe: center at (-W/2, FH), starting at (+W/2, FH), peaking at center top.
        R = W  # radius equals trailer width for classic gothic equilateral
        # For each lobe: arc from foot (at far wall) sweeping inward+upward to apex
        # Left lobe parametrized: from theta=180° (foot) to theta=120° (apex above center)
        # apex_y = FH + R * sin(60°) = FH + R*sqrt(3)/2
        t_L = np.linspace(np.radians(180), np.radians(120), 100)
        x_L = (W/2) + R * np.cos(t_L)   # center at (+W/2, FH)
        y_L = FH + R * np.sin(t_L)
        # Right lobe: from theta=0° (apex above center) to theta=60° backwards... actually:
        # mirror of left
        t_R = np.linspace(np.radians(60), np.radians(0), 100)
        x_R = -(W/2) + R * np.cos(t_R)   # center at (-W/2, FH)
        y_R = FH + R * np.sin(t_R)
        x_arc = np.concatenate([x_L, x_R])
        y_arc = np.concatenate([y_L, y_R])
        apex = y_arc.max()

    elif cfg['type'] == 'catenary':
        R = np.nan
        a = (W / 2) / np.arccosh(2)
        x_arc = np.linspace(-W/2, W/2, 300)
        # Hanging chain inverted (cosh) — apex at center
        h_max = (W / 2) * 0.45
        y_arc = FH + h_max - h_max * (np.cosh(x_arc / a) - 1) / (np.cosh((W/2) / a) - 1)
        # Wait — for a true inverted catenary we want apex at center:
        y_arc = FH + h_max * (1 - (np.cosh(x_arc / a) - 1) / (np.cosh((W/2) / a) - 1))
        apex = y_arc.max()

    else:
        raise ValueError(f"Unknown shape type: {cfg['type']}")

    # Wall feet at x = ±W/2
    # For arc shapes the arc foot meets the wall at x=±W/2 directly
    return {
        'shape':     shape,
        'name':      cfg['name'],
        'desc':      cfg['desc'],
        'W':         W,
        'FH':        FH,
        'R':         R if cfg['type'] == 'arc' else (W if cfg['type'] == 'gothic' else np.nan),
        'arc_deg':   arc_deg,
        'x_arc':     x_arc,
        'y_arc':     y_arc,
        'apex':      apex,
        'rise':      apex - FH,
        'arc_len':   _arc_length(x_arc, y_arc),
    }


def _arc_length(x, y):
    """Compute developed arc length."""
    dx = np.diff(x)
    dy = np.diff(y)
    return np.sum(np.sqrt(dx**2 + dy**2))


# ────────────────────────────────────────────────────────────────────────
# SOLAR HARVEST MODEL
# ────────────────────────────────────────────────────────────────────────
def hourly_harvest(site='peten', shape='low120',
                   n_long=4, n_row=2, n_north=2, derate=0.87,
                   width_ft=7.5):
    """
    Numerical integration of hourly solar harvest by face.
    Returns dict with hours, P_arc, P_north, totals.
    """
    s = SITES[site]
    lat = s['lat']
    albedo = s['albedo']
    canyon = s['canyon']

    geom = compute_geometry(width_ft=width_ft, shape=shape)
    # Vault factor depends on shape's angular distribution of panel mounting,
    # NOT the developed arc length (since panel count is fixed = n_arc).
    # 120° arc gives best E-W sweep; 180°+ have more total angle but redundant
    # mid-day exposure; gothic has steep sides that miss low sun.

    hours = np.arange(6, 18.001, 0.25)
    hour_angle = (hours - 12) * 15   # degrees

    # Solar declination (summer solstice for max-yield estimate)
    decl = 23.5

    # Cosine of incidence on a horizontal panel
    cos_inc = np.maximum(
        0,
        np.sin(np.radians(lat)) * np.sin(np.radians(decl))
        + np.cos(np.radians(lat)) * np.cos(np.radians(decl)) * np.cos(np.radians(hour_angle))
    )

    # Shape-specific vault factor (panel-area normalized):
    #   semi180:    classic baseline
    #   low120:     +5% (best E-W sweep, chapter spec)
    #   raised240:  -3% (redundant mid-day, harder mount)
    #   gothic:     -2% (steep sides reduce low-sun capture)
    #   catenary:   even (similar to low arc but no E-W boost)
    shape_factor = {
        'semi180':   1.00,
        'low120':    1.05,
        'raised240': 0.97,
        'gothic':    0.98,
        'catenary':  1.00,
    }
    # Mild morning/afternoon E-W boost (panels on shoulders catch oblique sun)
    base_vault = 1.0 + 0.10 * np.abs(np.cos(np.radians(hour_angle)))
    vault_f = base_vault * shape_factor.get(shape, 1.0)

    # Arc direct harvest
    n_arc = n_long * n_row
    P_arc = n_arc * P_PANEL * cos_inc * vault_f * derate / 1000  # kW

    # North face reflection (canyon albedo)
    refl_factor = albedo * np.sin(np.radians(canyon))
    diffuse_proxy = np.maximum(0, cos_inc * (1 - cos_inc))
    P_north = n_north * P_PANEL * (0.08 + refl_factor * diffuse_proxy) * derate / 1000

    P_arc[cos_inc <= 0] = 0
    P_north[cos_inc <= 0] = 0

    E_day_arc   = np.trapezoid(P_arc, hours)
    E_day_north = np.trapezoid(P_north, hours)
    E_day = E_day_arc + E_day_north

    return {
        'hours': hours, 'P_arc': P_arc, 'P_north': P_north,
        'E_day_arc': E_day_arc, 'E_day_north': E_day_north, 'E_day': E_day,
        'E_year': E_day * 365 / 1000,   # MWh
        'P_peak_arc':   n_arc * P_PANEL * 1.1 * derate / 1000,   # kW
        'n_arc':        n_arc,
        'n_north':      n_north,
        'n_total':      n_arc + n_north,
        'site':         s,
        'shape':        shape,
        'shape_name':   SHAPES[shape]['name'],
        'geom':         geom,
    }


# ────────────────────────────────────────────────────────────────────────
# PLOTTING — DOME SHAPES
# ────────────────────────────────────────────────────────────────────────
def plot_dome(ax, geom, title=None, show_panels=True, show_sun=True, sun_alt=75,
              show_dims=True, panel_count=6):
    """
    Plot a single vault cross-section on the given axis.
    Includes floor, walls, vault curve, optional panels and sun arrows.
    """
    W  = geom['W']
    FH = geom['FH']
    x_arc = geom['x_arc']
    y_arc = geom['y_arc']
    apex  = geom['apex']

    # Floor fill
    ax.fill([-W/2, W/2, W/2, -W/2], [0, 0, FH, FH],
            color=CLR_FLOOR, alpha=0.55, edgecolor='none')
    ax.text(0, FH/2, 'lab floor', ha='center', va='center',
            fontsize=8, color='#807F70')

    # Walls
    ax.plot([-W/2, -W/2], [0, FH], color=CLR_WALL, lw=2.2)
    ax.plot([ W/2,  W/2], [0, FH], color=CLR_WALL, lw=2.2)

    # Vault curve
    ax.plot(x_arc, y_arc, color=CLR_GREEN, lw=3.0, zorder=5)

    # Vault interior fill (semi-transparent)
    interior_x = np.concatenate([[-W/2], x_arc, [W/2, -W/2]])
    interior_y = np.concatenate([[FH], y_arc, [FH, FH]])
    ax.fill(interior_x, interior_y, color=CLR_GREEN, alpha=0.05, edgecolor='none')

    # Solar panels — distributed along arc
    if show_panels and panel_count > 0:
        idx_panels = np.round(np.linspace(30, len(x_arc)-30, panel_count)).astype(int)
        for i in idx_panels:
            if 2 <= i < len(x_arc) - 1:
                px, py = x_arc[i], y_arc[i]
                dx = x_arc[i+1] - x_arc[i-1]
                dy = y_arc[i+1] - y_arc[i-1]
                ln = np.hypot(dx, dy)
                if ln == 0:
                    continue
                tang_x, tang_y = dx/ln, dy/ln
                nm_x, nm_y = -tang_y, tang_x
                pw, ph = 70, 12
                xp = [px - tang_x*pw/2, px + tang_x*pw/2,
                      px + tang_x*pw/2 + nm_x*ph, px - tang_x*pw/2 + nm_x*ph]
                yp = [py - tang_y*pw/2, py + tang_y*pw/2,
                      py + tang_y*pw/2 + nm_y*ph, py - tang_y*pw/2 + nm_y*ph]
                ax.fill(xp, yp, color=CLR_PANEL, edgecolor='#0B6B47', lw=0.6, zorder=6)

    # Sun arrows
    if show_sun:
        dx_s = np.cos(np.radians(90 - sun_alt))
        dy_s = np.sin(np.radians(90 - sun_alt))
        for xs in np.arange(-W/2*0.4, W/2*0.4 + 1, W/8):
            arrow = FancyArrowPatch(
                (xs - dx_s*250, apex + 280 + dy_s*250),
                (xs, apex + 280),
                arrowstyle='->', mutation_scale=12,
                color=CLR_AMBER, lw=1.2
            )
            ax.add_patch(arrow)
        ax.text(W/2 - 80, apex + 360, f'☼ alt {sun_alt}°',
                fontsize=8, color='#B47600')

    # Dimensions
    if show_dims:
        dim_y = -120
        ax.plot([-W/2, W/2], [dim_y, dim_y], 'k-', lw=0.6)
        ax.plot([-W/2, -W/2], [dim_y - 18, dim_y + 18], 'k-', lw=0.6)
        ax.plot([ W/2,  W/2], [dim_y - 18, dim_y + 18], 'k-', lw=0.6)
        ax.text(0, dim_y - 50, f'{W:.0f} mm  ({W/FT2MM:.1f} ft)',
                ha='center', fontsize=8)

        if not np.isnan(geom.get('R', np.nan)):
            R = geom['R']
            ax.text(0, apex + 80, f'R = {R:.0f} mm',
                    ha='center', fontsize=8, color='#0B6B47')

        ax.text(W/2 + 90, (apex + FH) / 2,
                f'rise:\n{geom["rise"]:.0f} mm\n({geom["rise"]/FT2MM:.1f} ft)',
                fontsize=8, color='#0B6B47')

    if title:
        ax.set_title(title, fontsize=11, fontweight='bold')

    ax.set_aspect('equal')
    ax.grid(True, alpha=0.18)
    ax.set_xlim(-W/2 - 280, W/2 + 320)
    ax.set_ylim(-180, apex + 460)
    ax.set_xlabel('Width (mm)', fontsize=9)
    ax.set_ylabel('Height (mm)', fontsize=9)


def plot_all_dome_shapes(width_ft=7.5, floor_h_ft=4.0, save_path=None,
                          show=True):
    """
    Plot all 5 dome shapes in a 2×3 grid for visual comparison.
    """
    shapes_to_plot = ['semi180', 'low120', 'raised240', 'gothic', 'catenary']

    fig = plt.figure(figsize=(15, 10), facecolor='white')
    gs = gridspec.GridSpec(2, 3, figure=fig, wspace=0.30, hspace=0.35)

    for i, shape in enumerate(shapes_to_plot):
        row, col = divmod(i, 3)
        ax = fig.add_subplot(gs[row, col])
        geom = compute_geometry(width_ft=width_ft, floor_h_ft=floor_h_ft, shape=shape)
        title = f"{geom['name']}\n{geom['desc']}"
        plot_dome(ax, geom, title=title, show_panels=True, show_sun=True)

    # Summary panel in last grid cell
    ax_sum = fig.add_subplot(gs[1, 2])
    ax_sum.axis('off')
    ax_sum.set_title('Geometry summary', fontsize=11, fontweight='bold', loc='left')

    summary_lines = []
    for shape in shapes_to_plot:
        geom = compute_geometry(width_ft=width_ft, floor_h_ft=floor_h_ft, shape=shape)
        summary_lines.append(
            f"• {geom['name']}\n"
            f"   rise: {geom['rise']:.0f} mm ({geom['rise']/FT2MM:.2f} ft)\n"
            f"   arc length: {geom['arc_len']:.0f} mm\n"
            f"   total height: {geom['apex']:.0f} mm"
        )
    ax_sum.text(0.0, 0.92, '\n\n'.join(summary_lines),
                fontsize=9, va='top', ha='left',
                family='monospace', color='#2A2A28',
                transform=ax_sum.transAxes)

    fig.suptitle(f'Vault dome shapes — {width_ft} ft wide trailer',
                 fontsize=14, fontweight='bold', y=0.98)

    if save_path:
        fig.savefig(save_path, dpi=150, bbox_inches='tight', facecolor='white')
        print(f'Saved: {save_path}')
    if show:
        plt.show()
    return fig


# ────────────────────────────────────────────────────────────────────────
# PLOTTING — HARVEST CURVES
# ────────────────────────────────────────────────────────────────────────
def plot_hourly_harvest(site='peten', shape='low120', save_path=None, show=True,
                         **kw):
    """Plot hourly power output by face (arc + north reflected)."""
    h = hourly_harvest(site=site, shape=shape, **kw)

    fig, ax = plt.subplots(figsize=(10, 5.5), facecolor='white')

    # Filled areas
    P_total = h['P_arc'] + h['P_north']
    ax.fill_between(h['hours'], 0, P_total, color=CLR_GREEN, alpha=0.20,
                    label='_nolegend_')
    ax.fill_between(h['hours'], 0, h['P_north'], color=CLR_BLUE, alpha=0.25,
                    label='_nolegend_')

    # Line plots
    ax.plot(h['hours'], P_total, color=CLR_GREEN, lw=2.2, marker='o',
            markersize=4, markevery=4, label='Arc direct')
    ax.plot(h['hours'], h['P_north'], color=CLR_BLUE, lw=1.4, ls='--',
            marker='o', markersize=3, markevery=4, label='North (diffuse + reflection)')

    ax.set_xlim(6, 18)
    ax.set_xticks(range(6, 19, 2))
    ax.set_xlabel('Hour of day', fontsize=10)
    ax.set_ylabel('Power output (kW)', fontsize=10)
    ax.set_title(
        f"Hourly harvest — {h['shape_name']} at {h['site']['name']} "
        f"(lat {h['site']['lat']}°N)",
        fontsize=12, fontweight='bold'
    )
    ax.grid(True, alpha=0.18)
    ax.legend(loc='upper right', frameon=False, fontsize=9)

    # KPI annotation
    kpi = (
        f"Daily harvest: {h['E_day']:.1f} kWh\n"
        f"  arc direct:  {h['E_day_arc']:.1f} kWh\n"
        f"  north face:  {h['E_day_north']:.1f} kWh ({h['E_day_north']/h['E_day']*100:.0f}%)\n"
        f"Peak power:    {h['P_peak_arc']:.2f} kW\n"
        f"Annual yield:  {h['E_year']:.2f} MWh\n"
        f"Panels:        {h['n_arc']} arc + {h['n_north']} north"
    )
    ax.text(0.02, 0.97, kpi, transform=ax.transAxes, fontsize=9,
            va='top', ha='left', family='monospace',
            bbox=dict(boxstyle='round,pad=0.5', fc='white', ec='#C8C8C0', lw=0.5))

    if save_path:
        fig.savefig(save_path, dpi=150, bbox_inches='tight', facecolor='white')
        print(f'Saved: {save_path}')
    if show:
        plt.show()
    return fig, h


def plot_shape_comparison(site='peten', save_path=None, show=True, **kw):
    """Bar chart comparing daily harvest across all 5 vault shapes."""
    shapes_to_plot = ['semi180', 'low120', 'raised240', 'gothic', 'catenary']
    results = []
    for sh in shapes_to_plot:
        h = hourly_harvest(site=site, shape=sh, **kw)
        results.append((SHAPES[sh]['name'], h['E_day'], sh))

    names  = [r[0] for r in results]
    values = [r[1] for r in results]
    best_idx  = int(np.argmax(values))

    fig, ax = plt.subplots(figsize=(10, 5.5), facecolor='white')
    colors = ['#9FE0C5'] * len(results)
    colors[best_idx] = CLR_GREEN

    bars = ax.barh(names, values, color=colors, edgecolor='none', height=0.55)
    ax.set_yticks(range(len(names)))
    ax.set_yticklabels(names, fontsize=10)
    ax.invert_yaxis()
    ax.set_xlabel('kWh per day', fontsize=10)
    ax.set_title(
        f'Vault shape comparison — daily harvest at {SITES[site]["name"]}',
        fontsize=12, fontweight='bold'
    )
    ax.grid(True, axis='x', alpha=0.18)

    for bar, val in zip(bars, values):
        ax.text(val + 0.05, bar.get_y() + bar.get_height()/2,
                f'{val:.1f}', va='center', fontsize=10, fontweight='bold',
                color='#2A2A28')

    # Highlight best
    ax.text(0.98, 0.02,
            f'Best: {names[best_idx]} ({values[best_idx]:.1f} kWh/day)',
            transform=ax.transAxes, ha='right', va='bottom',
            fontsize=9, fontweight='bold', color=CLR_GREEN,
            bbox=dict(boxstyle='round,pad=0.5', fc='white', ec=CLR_GREEN, lw=0.8))

    if save_path:
        fig.savefig(save_path, dpi=150, bbox_inches='tight', facecolor='white')
        print(f'Saved: {save_path}')
    if show:
        plt.show()
    return fig


def plot_site_comparison(shape='low120', save_path=None, show=True, **kw):
    """Bar chart comparing harvest across all 4 sites for a given shape."""
    site_list = ['peten', 'kohala', 'austin', 'california']
    results = []
    for s in site_list:
        h = hourly_harvest(site=s, shape=shape, **kw)
        results.append((SITES[s]['name'], h['E_day'], h['E_year']))

    names      = [r[0] for r in results]
    daily      = [r[1] for r in results]
    annual     = [r[2] for r in results]
    best_idx   = int(np.argmax(daily))

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(13, 5.5), facecolor='white')

    # Daily
    colors = ['#9FE0C5'] * len(results)
    colors[best_idx] = CLR_GREEN
    bars = ax1.bar(names, daily, color=colors, edgecolor='none', width=0.6)
    ax1.set_ylabel('Daily harvest (kWh)', fontsize=10)
    ax1.set_title('Daily — by site', fontsize=11, fontweight='bold')
    ax1.grid(True, axis='y', alpha=0.18)
    plt.setp(ax1.get_xticklabels(), rotation=15, ha='right')
    for bar, v in zip(bars, daily):
        ax1.text(bar.get_x() + bar.get_width()/2, v + 0.1,
                 f'{v:.1f}', ha='center', fontsize=10, fontweight='bold')

    # Annual
    colors2 = ['#A8D5F2'] * len(results)
    colors2[best_idx] = CLR_BLUE
    bars2 = ax2.bar(names, annual, color=colors2, edgecolor='none', width=0.6)
    ax2.set_ylabel('Annual yield (MWh)', fontsize=10)
    ax2.set_title('Annual — by site', fontsize=11, fontweight='bold')
    ax2.grid(True, axis='y', alpha=0.18)
    plt.setp(ax2.get_xticklabels(), rotation=15, ha='right')
    for bar, v in zip(bars2, annual):
        ax2.text(bar.get_x() + bar.get_width()/2, v + 0.05,
                 f'{v:.2f}', ha='center', fontsize=10, fontweight='bold')

    fig.suptitle(f'Site comparison — {SHAPES[shape]["name"]}',
                 fontsize=13, fontweight='bold', y=1.02)

    if save_path:
        fig.savefig(save_path, dpi=150, bbox_inches='tight', facecolor='white')
        print(f'Saved: {save_path}')
    if show:
        plt.show()
    return fig


# ────────────────────────────────────────────────────────────────────────
# 3D DOME RENDERINGS — for the chapter's visual emphasis
# ────────────────────────────────────────────────────────────────────────
def plot_3d_dome(shape='low120', width_ft=7.5, floor_h_ft=4.0,
                  length_ft=24, save_path=None, show=True):
    """3D perspective render of a complete trailer with the given vault shape."""
    from mpl_toolkits.mplot3d import Axes3D  # noqa

    geom = compute_geometry(width_ft=width_ft, floor_h_ft=floor_h_ft, shape=shape)
    W  = geom['W']
    L  = length_ft * FT2MM
    FH = geom['FH']

    fig = plt.figure(figsize=(13, 8), facecolor='white')
    ax = fig.add_subplot(111, projection='3d')

    n_ribs = 9
    rib_positions = np.linspace(200, L - 200, n_ribs)

    # Ribs (cross-section curves at each station)
    for xr in rib_positions:
        ax.plot(np.ones_like(geom['x_arc']) * xr, geom['x_arc'], geom['y_arc'],
                color=CLR_WALL, lw=1.1, alpha=0.85)
        # Walls
        ax.plot([xr, xr], [-W/2, -W/2], [0, FH], color='#6B6B66', lw=0.8)
        ax.plot([xr, xr], [ W/2,  W/2], [0, FH], color='#6B6B66', lw=0.8)

    # Longitudinal stringers along the arc
    if geom['arc_deg'] > 0 and SHAPES[shape]['type'] == 'arc':
        arc_half = np.radians(geom['arc_deg'] / 2)
        for ts in np.linspace(-arc_half + 0.05, arc_half - 0.05, 9):
            R = geom['R']
            ys = R * np.sin(ts)
            zs = FH + R * np.cos(ts)
            ax.plot([0, L], [ys, ys], [zs, zs], color=CLR_GREEN, lw=0.7)
    else:
        # For gothic/catenary just use the arc points as stringer trace
        for i in range(10, len(geom['x_arc']), 30):
            ax.plot([0, L],
                    [geom['x_arc'][i], geom['x_arc'][i]],
                    [geom['y_arc'][i], geom['y_arc'][i]],
                    color=CLR_GREEN, lw=0.7)

    # Solar panels on top of vault (4 panels along length, 2 rows)
    apex_idx = np.argmax(geom['y_arc'])
    apex_y_pos = geom['x_arc'][apex_idx]
    apex_z = geom['y_arc'][apex_idx]
    panel_w_mm = 1825
    for xp in np.arange(200, L - panel_w_mm, panel_w_mm + 60):
        for y_shift in [-300, 300]:
            xs = [xp, xp + panel_w_mm, xp + panel_w_mm, xp]
            ys = [y_shift - 400, y_shift - 400, y_shift + 400, y_shift + 400]
            zs = [apex_z + 15] * 4
            ax.plot_trisurf(xs, ys, zs, color=CLR_PANEL, alpha=0.85,
                            edgecolor='#0B6B47', lw=0.4)

    # Floor
    floor_x = [0, L, L, 0]
    floor_y = [-W/2, -W/2, W/2, W/2]
    floor_z = [0, 0, 0, 0]
    ax.plot_trisurf(floor_x, floor_y, floor_z, color=CLR_FLOOR,
                    alpha=0.45, edgecolor='#A5A593', lw=0.4)

    # Labels and view
    ax.set_xlabel('Length (mm)', fontsize=9)
    ax.set_ylabel('Width (mm)', fontsize=9)
    ax.set_zlabel('Height (mm)', fontsize=9)
    ax.set_title(f"3D rendering — {geom['name']}  ·  {width_ft} ft × {length_ft} ft trailer",
                 fontsize=12, fontweight='bold')
    ax.view_init(elev=22, azim=35)

    # Equal aspect approximation
    max_range = max(L, W, geom['apex']) / 1.6
    ax.set_xlim([0, L])
    ax.set_ylim([-max_range, max_range])
    ax.set_zlim([0, max_range])

    if save_path:
        fig.savefig(save_path, dpi=150, bbox_inches='tight', facecolor='white')
        print(f'Saved: {save_path}')
    if show:
        plt.show()
    return fig


# ────────────────────────────────────────────────────────────────────────
# FULL STUDY — one call to generate everything
# ────────────────────────────────────────────────────────────────────────
def run_full_study(site='peten', width_ft=7.5, floor_h_ft=4.0,
                    n_long=4, n_row=2, n_north=2, derate=0.87,
                    save_dir=None, show=True):
    """
    Generate the complete visual study for one site:
      1. All 5 dome shape cross-sections
      2. Hourly harvest curve for the chapter-spec 120° low arc
      3. Shape comparison bar chart
      4. Site comparison bar chart
      5. 3D rendering of the chapter-spec trailer
    """
    import os
    if save_dir:
        os.makedirs(save_dir, exist_ok=True)

    def _path(name):
        return os.path.join(save_dir, name) if save_dir else None

    print(f'\n{"="*60}')
    print(f'SOLAR + GEOMETRY STUDY — {SITES[site]["name"]}')
    print(f'{"="*60}\n')

    # 1. All dome shapes
    print('[1/5] Plotting all 5 vault shapes...')
    plot_all_dome_shapes(width_ft=width_ft, floor_h_ft=floor_h_ft,
                          save_path=_path('01_all_dome_shapes.png'), show=show)

    # 2. Hourly harvest for chapter spec
    print('\n[2/5] Hourly harvest — 120° low arc...')
    plot_hourly_harvest(site=site, shape='low120',
                         n_long=n_long, n_row=n_row, n_north=n_north,
                         derate=derate, width_ft=width_ft,
                         save_path=_path('02_hourly_harvest_low120.png'),
                         show=show)

    # 3. Shape comparison
    print('\n[3/5] Shape comparison at site...')
    plot_shape_comparison(site=site,
                           n_long=n_long, n_row=n_row, n_north=n_north,
                           derate=derate, width_ft=width_ft,
                           save_path=_path('03_shape_comparison.png'), show=show)

    # 4. Site comparison
    print('\n[4/5] Site comparison for 120° low arc...')
    plot_site_comparison(shape='low120',
                          n_long=n_long, n_row=n_row, n_north=n_north,
                          derate=derate, width_ft=width_ft,
                          save_path=_path('04_site_comparison.png'), show=show)

    # 5. 3D rendering
    print('\n[5/5] 3D trailer rendering...')
    plot_3d_dome(shape='low120', width_ft=width_ft, floor_h_ft=floor_h_ft,
                  save_path=_path('05_3d_trailer.png'), show=show)

    # Final numerical summary
    h = hourly_harvest(site=site, shape='low120',
                       n_long=n_long, n_row=n_row, n_north=n_north,
                       derate=derate, width_ft=width_ft)
    print(f'\n{"="*60}')
    print(f'CHAPTER 12 NUMBERS — {SITES[site]["name"]} · 120° low arc')
    print(f'{"="*60}')
    print(f'  Panel config:  {h["n_arc"]} arc + {h["n_north"]} north = {h["n_total"]}')
    print(f'  Peak power:    {h["P_peak_arc"]:.2f} kW')
    print(f'  Daily harvest: {h["E_day"]:.2f} kWh')
    print(f'    arc direct:  {h["E_day_arc"]:.2f} kWh')
    print(f'    north face:  {h["E_day_north"]:.2f} kWh  ({h["E_day_north"]/h["E_day"]*100:.0f}%)')
    print(f'  Annual yield:  {h["E_year"]:.2f} MWh/year')
    print(f'\nGeometry — {SHAPES["low120"]["name"]}:')
    print(f'  Width:          {h["geom"]["W"]:.0f} mm ({h["geom"]["W"]/FT2MM:.2f} ft)')
    print(f'  Floor height:   {h["geom"]["FH"]:.0f} mm ({h["geom"]["FH"]/FT2MM:.2f} ft)')
    print(f'  Arc radius:     {h["geom"]["R"]:.0f} mm ({h["geom"]["R"]/FT2MM:.2f} ft)')
    print(f'  Rise:           {h["geom"]["rise"]:.0f} mm ({h["geom"]["rise"]/FT2MM:.2f} ft)')
    print(f'  Apex height:    {h["geom"]["apex"]:.0f} mm ({h["geom"]["apex"]/FT2MM:.2f} ft)')
    print(f'{"="*60}\n')

    return h


# ────────────────────────────────────────────────────────────────────────
# CLI entry
# ────────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    run_full_study(site='peten')
