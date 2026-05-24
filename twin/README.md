# twin/ — Alchemist Feedback Loop (work in progress)

The digital twin module. Closes the loop between the analytical solar/wind model and real sensor data from a deployed trailer.

> **Status: scaffold + sensor schema only.** The neural surrogate and Bayesian optimizer are next.

## What's here

| File | Status | Purpose |
|------|--------|---------|
| `sensor_schema.py` | **done, tested** | Standard JSON-Lines format for all field measurements. One sample per timestamp; one daily file per trailer. Includes builders for Davis Vantage Pro2, Apogee SP-510, and Allied Vision Mako camera. |
| `data_samples/` | demo | One example JSONL line written by the schema's `__main__` self-test. |
| `digital_twin.py` | **TODO** | Physics-informed neural network. Seeded by `solar_optimizer.py` at hour 0, retrained against sensor data as it accumulates. |
| `optimizer.py` | **TODO** | Bayesian optimization loop. Proposes parameter changes (drain rate, spoiler angle, fan duty cycle) and learns which actually improve real-world yield. |
| `camera_processor.py` | **TODO** | Image analysis pipeline for the calibrated solar camera. Extracts sun disk brightness, centroid, cloud fraction, aerosol optical depth. |

## Sensor stack supported

The schema covers three tiers of field instrumentation:

**Essential (~$1,450):**
- Davis Vantage Pro2 + Solar Sensor — weather + bulk irradiance
- Apogee SP-510 thermopile pyranometer — lab-grade ground truth

**Premium (~$3,650):**
- Above + Allied Vision Mako G-319C with solar ND filter on a gimbal — your calibrated spectral imager

**Lab-grade Petén deployment (~$7,100):**
- Above + Hukseflux SR05 dual pyranometer (ISO 9060 Class A)
- EKO MS-90 sun photometer (8-band spectral)

Plus per-panel MPPT telemetry, strain gauges on the CF tube frame, thermocouples on the clay+CF skin, fan-generator power, sealed clean room T/RH/ΔP, and the Sol Arc 48V bus state.

## Quick test

```bash
python twin/sensor_schema.py
# Writes one demo sample to twin/data_samples/<trailer>_<date>.jsonl
# Reads it back and prints the panel power and bus state.
```

## The closed loop (planned)

```
  Hour 0:  Twin = solar_optimizer.py exactly.
           Predicts 26.6 kWh/day at Petén.

  Day 1:   Sensors stream every second. Real harvest = 24.8 kWh.
           Twin residual: -1.8 kWh. Camera shows 18% cloud cover.

  Day 7:   Twin has 600,000 samples. Retrains its neural surrogate.
           Residuals reveal where first-principles model is blind.

  Day 30:  Twin learns: 'real albedo at this canyon = 0.52, not 0.45.'
           Optimizer suggests: tilt north panels +3°. Applied. +6% yield.

  Day 90:  Twin BEATS the analytical model — knows this specific canyon,
           these specific panels, this specific dust schedule.
```

## Next steps

1. Wire `camera_processor.py` to read GigE Vision frames and emit the schema's `sun_disk_*`, `sky_haze_index`, `cloud_fraction`, `aerosol_optical_depth` fields.
2. Build `digital_twin.py` as a PyTorch model with two heads: physics prior (frozen, = `solar_optimizer.py`) and learned correction (trained on residuals).
3. Build `optimizer.py` as `scikit-optimize` Bayesian loop over the parameter space exposed by `solar_optimizer.py`.
4. Add a `data/` folder at repo root for committed field data; one subdirectory per site.

PRs welcome on any of the above — see the issue tracker for the current task list.
