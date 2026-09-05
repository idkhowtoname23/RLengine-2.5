**What was added in RLengine 2.5 and how it differs from 2.0**

**Major Additions in RLengine 2.5**

* **Precomputed Matrix System:** Camera rotations are now calculated using a single 3D transformation matrix per frame instead of running individual trigonometric calculations (`sin`/`cos`) for every single point, drastically reducing CPU load.
* **Color Lookup Table (Color LUT):** Particle color and depth gradient calculations are handled via a pre-rendered 256-entry array for instant $O(1)$ palette mapping.
* **Expanded Force Field Modes:** Added four distinct interactive physics behaviors (`1: Attractor`, `2: Vortex`, `3: Repeller`, and `4: Wave Turbulence`) accessible in real time via numeric hotkeys.
* **Preset Color Palettes:** Integrated four dynamic color themes (`Cyberpunk`, `Inferno`, `Matrix`, `Electric Blue`) assigned to `F1-F4` keys, with color intensity tied directly to particle velocity.
* **Increased Particle Capacity:** Expanded the maximum particle limit from 2,000,000 to 3,000,000 entities while maintaining zero-allocation RAM performance (~1.14 MB Lua memory footprint).

---

**Main Differences Between RLengine 2.5 and RLengine 2.0**

| Feature / Specification | RLengine 2.0 | RLengine 2.5 (Extreme FX & Perf) |
| --- | --- | --- |
| **Max Particle Limit** | 2,000,000 | 3,000,000 |
| **Transform Math** | Individual trigonometric rotation per particle | Global precalculated 3D transformation matrix per frame |
| **Color Processing** | Dynamic RGB interpolation calculated every frame | Zero-overhead lookup table (`colorLUT`) mapping |
| **Physics Mechanics** | Single centralized gravitational attraction point | 4 interactive force modes (Attractor, Vortex, Repeller, Turbulence) |
| **Visual Customization** | Fixed single-color depth fog gradient | 4 hotkey-switchable color palettes with velocity-based indexing |
