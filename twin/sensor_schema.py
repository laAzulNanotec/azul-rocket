"""
sensor_schema.py — Standard data format for the alchemist feedback loop.

Every trailer in the world that builds from this repo writes data in this
schema. One JSON-Lines file per day per trailer, committed to data/<site>/.

Schema is intentionally minimal and forward-compatible: unknown fields are
preserved, missing fields fall back to None.

Sensor stack covered:
  - Davis Vantage Pro2 + Solar Sensor    (weather + bulk irradiance)
  - Apogee SP-510 / Hukseflux SR05       (lab-grade pyranometer)
  - EKO MS-90 sun photometer             (multi-band spectral)
  - Allied Vision Mako + ND filter       (calibrated solar imaging)
  - MPPT charge controllers              (per-panel I/V)
  - Strain gauges on CF tube frame       (structural validation)
  - Thermocouples on clay/CF skin        (thermal validation)
"""

from dataclasses import dataclass, field, asdict
from typing import Optional, List, Dict
from datetime import datetime, timezone
import json


# ──────────────────────────────────────────────────────────────────────
# CORE RECORD — one per measurement timestamp
# ──────────────────────────────────────────────────────────────────────

@dataclass
class TrailerSample:
    """One sample of all sensor data at a single timestamp."""

    # Identification
    timestamp:      str            # ISO 8601 UTC
    trailer_id:     str            # e.g. "az-rocket-prototype-01"
    site_name:      str            # "austin-backyard", "peten-canyon-3"
    site_lat:       float
    site_lon:       float
    site_alt_m:     float

    # Weather station (Davis Vantage Pro2 or equivalent)
    air_temp_c:     Optional[float] = None
    humidity_pct:   Optional[float] = None
    pressure_hpa:   Optional[float] = None
    wind_speed_ms:  Optional[float] = None
    wind_dir_deg:   Optional[float] = None     # 0 = North, 90 = East
    rain_mm_hr:     Optional[float] = None
    uv_index:       Optional[float] = None

    # Bulk irradiance (Davis Solar Sensor OR Apogee/Hukseflux pyranometer)
    irradiance_global_w_m2:   Optional[float] = None
    irradiance_diffuse_w_m2:  Optional[float] = None   # if dual pyranometer
    irradiance_source:        Optional[str]   = None   # "davis"|"apogee"|"hukseflux"

    # Spectral irradiance (EKO MS-90 sun photometer, 8 bands)
    spectral_w_m2_nm: Optional[Dict[str, float]] = None
    # keys: "440nm", "500nm", "675nm", "870nm", etc.

    # Calibrated solar imaging (Allied Vision Mako + ND filter)
    sun_disk_brightness:  Optional[float] = None   # mean intensity of disk
    sun_disk_x_px:        Optional[float] = None   # centroid in image
    sun_disk_y_px:        Optional[float] = None
    sky_haze_index:       Optional[float] = None   # 0=clear, 1=heavy haze
    cloud_fraction:       Optional[float] = None   # 0-1, computed from image
    aerosol_optical_depth: Optional[float] = None  # AOD at 550nm, inferred

    # Per-panel electrical (one entry per panel)
    panels: List[Dict] = field(default_factory=list)
    # Each panel dict:
    #   {
    #     "panel_id":  "arc-1-1",          (row-col on arc, or "north-1")
    #     "vmp_v":     48.2,
    #     "imp_a":     8.4,
    #     "power_w":   405.2,
    #     "temp_c":    52.3,                (panel surface thermocouple)
    #     "tilt_deg":  35.0,                (effective tilt from horizontal)
    #     "azimuth_deg": 90.0,              (compass bearing)
    #   }

    # Fan-generators (one entry per fan)
    fans: List[Dict] = field(default_factory=list)
    # Each fan dict:
    #   {
    #     "fan_id":     "south-dome",
    #     "rpm":        420,
    #     "voltage_v":  24.8,
    #     "current_a":  2.1,
    #     "power_w":    52.1,
    #     "duty_pct":   85.0,
    #   }

    # Structural — strain gauges on CF tube frame (microstrain)
    strain_microstrain: Optional[Dict[str, float]] = None
    # keys: "rib-1-apex", "stringer-arc-2", "rib-7-foot-left", etc.

    # Thermal — thermocouples on clay+CF skin (°C)
    skin_temp_c: Optional[Dict[str, float]] = None
    # keys: "panel-1-exterior", "panel-1-interior", "dome-south-rim", etc.

    # Sealed clean room interior
    interior_temp_c:     Optional[float] = None
    interior_humid_pct:  Optional[float] = None
    interior_pressure_hpa: Optional[float] = None  # vs ambient — leak detection

    # Battery bus (Sol Arc 48V)
    bus_voltage_v:  Optional[float] = None
    bus_current_a:  Optional[float] = None         # +charge, -discharge
    bus_soc_pct:    Optional[float] = None

    # Free-form extras (forward compatibility)
    extras: Dict = field(default_factory=dict)

    # ──────────────────────────────────────────────────────────────────
    def to_json_line(self) -> str:
        """Serialize as one JSON line for JSONL files."""
        d = asdict(self)
        # Strip None values to keep files small and readable
        d = {k: v for k, v in d.items()
             if v is not None and v != [] and v != {}}
        return json.dumps(d, separators=(',', ':'))

    @classmethod
    def from_json_line(cls, line: str) -> "TrailerSample":
        d = json.loads(line)
        # Re-populate any missing dataclass fields with defaults
        valid_keys = {f.name for f in cls.__dataclass_fields__.values()}
        filtered = {k: v for k, v in d.items() if k in valid_keys}
        return cls(**filtered)


# ──────────────────────────────────────────────────────────────────────
# QUICK BUILDERS — convenience for common sensor combos
# ──────────────────────────────────────────────────────────────────────

def from_davis(weather_dict: dict, trailer_id: str, site: dict) -> TrailerSample:
    """Build a sample from Davis Vantage Pro2 telemetry."""
    return TrailerSample(
        timestamp     = datetime.now(timezone.utc).isoformat(),
        trailer_id    = trailer_id,
        site_name     = site['name'],
        site_lat      = site['lat'],
        site_lon      = site['lon'],
        site_alt_m    = site.get('alt_m', 0),
        air_temp_c    = weather_dict.get('temp_c'),
        humidity_pct  = weather_dict.get('humidity'),
        pressure_hpa  = weather_dict.get('pressure'),
        wind_speed_ms = weather_dict.get('wind_speed_ms'),
        wind_dir_deg  = weather_dict.get('wind_dir'),
        rain_mm_hr    = weather_dict.get('rain_rate'),
        uv_index      = weather_dict.get('uv'),
        irradiance_global_w_m2 = weather_dict.get('solar_w_m2'),
        irradiance_source = 'davis',
    )


def from_apogee(volts_mv: float, calibration: float = 13.1) -> dict:
    """Convert Apogee SP-510 raw output to W/m².
    Default calibration 13.1 mV per kW/m² — replace with your sensor's cert.
    """
    return {
        'irradiance_global_w_m2': volts_mv / calibration * 1000,
        'irradiance_source': 'apogee_sp510',
    }


def from_camera(image_analysis: dict) -> dict:
    """Inject the calibrated solar camera's image analysis output."""
    return {
        'sun_disk_brightness':    image_analysis.get('disk_intensity'),
        'sun_disk_x_px':          image_analysis.get('centroid_x'),
        'sun_disk_y_px':          image_analysis.get('centroid_y'),
        'sky_haze_index':         image_analysis.get('haze'),
        'cloud_fraction':         image_analysis.get('cloud_pct'),
        'aerosol_optical_depth':  image_analysis.get('aod_550'),
    }


# ──────────────────────────────────────────────────────────────────────
# FILE I/O — JSONL day files
# ──────────────────────────────────────────────────────────────────────

def append_sample(filepath: str, sample: TrailerSample):
    """Append one sample to a JSONL day file."""
    with open(filepath, 'a') as f:
        f.write(sample.to_json_line() + '\n')


def read_day(filepath: str) -> List[TrailerSample]:
    """Read all samples from a JSONL day file."""
    samples = []
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            samples.append(TrailerSample.from_json_line(line))
    return samples


def daily_filename(trailer_id: str, date: Optional[datetime] = None) -> str:
    """Standard filename: <trailer-id>_YYYY-MM-DD.jsonl"""
    if date is None:
        date = datetime.now(timezone.utc)
    return f"{trailer_id}_{date.strftime('%Y-%m-%d')}.jsonl"


# ──────────────────────────────────────────────────────────────────────
# DEMO — generate one sample, write it, read it back
# ──────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    import os
    sample = TrailerSample(
        timestamp     = datetime.now(timezone.utc).isoformat(),
        trailer_id    = 'az-rocket-prototype-01',
        site_name     = 'austin-backyard',
        site_lat      = 30.27,
        site_lon      = -97.74,
        site_alt_m    = 150.0,
        air_temp_c    = 32.5,
        humidity_pct  = 45.0,
        pressure_hpa  = 1014.2,
        wind_speed_ms = 3.2,
        wind_dir_deg  = 180.0,
        irradiance_global_w_m2  = 856.3,
        irradiance_source       = 'apogee_sp510',
        cloud_fraction          = 0.08,
        sky_haze_index          = 0.12,
        aerosol_optical_depth   = 0.15,
        panels = [
            {'panel_id': 'arc-1-1', 'vmp_v': 48.2, 'imp_a': 7.8,
             'power_w': 376.0, 'temp_c': 51.2, 'tilt_deg': 28.0,
             'azimuth_deg': 90.0},
            {'panel_id': 'arc-1-2', 'vmp_v': 48.1, 'imp_a': 7.6,
             'power_w': 365.6, 'temp_c': 52.8, 'tilt_deg': 28.0,
             'azimuth_deg': 270.0},
        ],
        fans = [
            {'fan_id': 'south-dome', 'rpm': 412, 'voltage_v': 23.8,
             'current_a': 1.9, 'power_w': 45.2, 'duty_pct': 80.0},
        ],
        strain_microstrain = {
            'rib-1-apex': 42.0,
            'stringer-arc-3': -18.5,
        },
        skin_temp_c = {
            'panel-1-exterior': 51.2,
            'panel-1-interior': 28.1,
            'dome-south-rim':   42.5,
        },
        interior_temp_c    = 24.8,
        interior_humid_pct = 35.0,
        bus_voltage_v      = 51.2,
        bus_current_a      = 14.5,
        bus_soc_pct        = 78.0,
    )

    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, 'data_samples', daily_filename('az-rocket-prototype-01'))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    append_sample(out, sample)

    # Round-trip test
    samples = read_day(out)
    print(f'Wrote and read back {len(samples)} samples → {out}')
    print(f'First sample: trailer {samples[0].trailer_id} at {samples[0].timestamp}')
    print(f'  Panels: {len(samples[0].panels)}, Power: {sum(p["power_w"] for p in samples[0].panels):.0f} W')
    print(f'  Bus: {samples[0].bus_voltage_v}V × {samples[0].bus_current_a}A = '
          f'{samples[0].bus_voltage_v * samples[0].bus_current_a:.0f} W net')
