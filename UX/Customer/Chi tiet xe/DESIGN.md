# Design System Specification: Electric Kinetic

## 1. Overview & Creative North Star
**Creative North Star: "The Kinetic Sanctuary"**

This design system moves beyond the utility of a standard SaaS dashboard to create a high-end, editorial experience for the electric vehicle (EV) sector. The "Kinetic Sanctuary" concept balances the high-velocity energy of electric motorcycles with the serene, clinical precision of premium maintenance management. 

Instead of a rigid, box-heavy "template" look, we leverage **intentional asymmetry** and **tonal depth**. The interface should feel like a custom-engineered instrument—mechanical yet fluid. We achieve this by prioritizing negative space, employing sophisticated layering, and using typography as a structural element rather than just a medium for information.

---

## 2. Colors & Surface Philosophy
The palette is rooted in clean energy and technical trust, utilizing a sophisticated Material Design-inspired scale to manage hierarchy without visual clutter.

### Color Tokens
- **Primary (Clean Energy):** `#006E2F` (Primary) | `#22C55E` (Container)
- **Secondary (Technical Trust):** `#0058BE` (Secondary) | `#2170E4` (Container)
- **Background & Surfacing:** `#F7F9FB` (Background) | `#FFFFFF` (Surface Lowest)
- **Tonal Neutrals:** `#E6E8EA` (Container High) | `#3D4A3D` (On-Surface Variant)

### The "No-Line" Rule
**Borders are prohibited for sectioning.** To maintain a premium, editorial feel, boundaries must be defined solely through background shifts. A `surface-container-low` section sitting on a `surface` background provides all the definition a professional eye needs.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of frosted glass.
- **Base Level:** `surface` (#F7F9FB).
- **Secondary Content Areas:** `surface-container-low` (#F2F4F6).
- **Interactive Cards/Modals:** `surface-container-lowest` (#FFFFFF) to provide a soft, natural lift.

### The "Glass & Gradient" Rule
To inject "soul" into the tech-focused aesthetic, use **Glassmorphism** for floating elements (sidebars or floating action panels) using semi-transparent `surface` colors with a 20px backdrop-blur. For primary CTAs, use a subtle linear gradient: `primary` (#006E2F) to `primary_container` (#22C55E) at a 135° angle.

---

## 3. Typography: Editorial Authority
We utilize a dual-font strategy to balance character with readability.

### Typeface Selection
- **Display & Headlines:** *Manrope*. A modern, geometric sans-serif that feels engineered and premium.
- **Body & UI Labels:** *Inter*. The industry standard for high-legibility data density.

### Typography Scale
- **Display (L/M/S):** 3.5rem / 2.75rem / 2.25rem (Manrope). Use for high-level fleet statistics and hero numbers.
- **Headline (L/M/S):** 2rem / 1.75rem / 1.5rem (Manrope). Use for page titles and major section headers.
- **Title (L/M/S):** 1.375rem / 1.125rem / 1rem (Inter). Semi-bold. Use for card titles and navigation.
- **Body (L/M/S):** 1rem / 0.875rem / 0.75rem (Inter). Regular. The workhorse for all maintenance logs and descriptions.
- **Label (M/S):** 0.75rem / 0.6875rem (Inter). Medium/Bold. Used for status chips and technical metadata.

---

## 4. Elevation & Depth: Tonal Layering
We do not use structural lines. Hierarchy is achieved through the **Layering Principle**.

- **Ambient Shadows:** When a floating effect is required (e.g., a "Service Alert" modal), use an extra-diffused shadow: `box-shadow: 0 20px 40px rgba(25, 28, 30, 0.06);`. The shadow color is a tint of `on-surface`, never pure black.
- **The "Ghost Border" Fallback:** If accessibility requires a border, use the `outline-variant` token (#BCCBB9) at **15% opacity**. It should be felt, not seen.
- **Soft Corners:** Use the **md (0.75rem / 12px)** radius as the default for all containers to mirror the ergonomic curves of modern motorcycle design. Use **full (9999px)** for status indicators and pill buttons.

---

## 5. Components

### Buttons
- **Primary:** Gradient fill (Primary to Primary-Container), white text. 12px radius. 
- **Secondary:** `secondary-container` (#2170E4) with `on-secondary` text. 
- **Tertiary:** No fill, `primary` text. Focus state uses a `surface-container-high` ghost background.

### Cards & Lists
**Forbid divider lines.** Separate maintenance logs using the **Spacing Scale (8px/16px/24px)**. Use a subtle `surface-container-low` background on hover to indicate interactivity. For data tables, use alternating `surface` and `surface-container-low` rows instead of horizontal rules.

### Input Fields
Soft backgrounds (`surface-container-highest`) with no border. On focus, a 2px "Ghost Border" of `primary` at 40% opacity should expand smoothly. Labels use `label-md` in `on-surface-variant`.

### EV-Specific Components
- **Telemetry Gauges:** Use a "Glassmorphism" ring with a `primary` glow to represent battery health or motor RPM.
- **Status Pills:** High-contrast `primary-fixed` (#6BFF8F) for "Optimized" and `tertiary-fixed` (#FFDAD5) for "Critical Service."

---

## 6. Do's and Don'ts

### Do
- **Do** use whitespace as a separator. If you think you need a line, add 16px of padding instead.
- **Do** use `manrope` for any number larger than 24px to emphasize the "engineered" feel.
- **Do** nest a `surface-container-lowest` card inside a `surface-container-low` background for maximum depth.

### Don't
- **Don't** use 100% opaque borders. They break the fluid, premium aesthetic.
- **Don't** use pure black (#000000) for text or shadows. Use `on-surface` (#191C1E) for a softer, high-end finish.
- **Don't** crowd the dashboard. If a user is managing a fleet of 500 motorcycles, use "Editorial Filtering" to show only the most critical kinetic data.