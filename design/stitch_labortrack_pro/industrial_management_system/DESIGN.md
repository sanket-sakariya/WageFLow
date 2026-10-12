---
name: Industrial Management System
colors:
  surface: '#fbf8ff'
  surface-dim: '#dbd9e1'
  surface-bright: '#fbf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f2fb'
  surface-container: '#efecf5'
  surface-container-high: '#eae7ef'
  surface-container-highest: '#e4e1ea'
  on-surface: '#1b1b21'
  on-surface-variant: '#454652'
  inverse-surface: '#303036'
  inverse-on-surface: '#f2eff8'
  outline: '#767683'
  outline-variant: '#c6c5d4'
  surface-tint: '#4c56af'
  primary: '#000666'
  on-primary: '#ffffff'
  primary-container: '#1a237e'
  on-primary-container: '#8690ee'
  inverse-primary: '#bdc2ff'
  secondary: '#4c616c'
  on-secondary: '#ffffff'
  secondary-container: '#cfe6f2'
  on-secondary-container: '#526772'
  tertiary: '#380b00'
  on-tertiary: '#ffffff'
  tertiary-container: '#5c1800'
  on-tertiary-container: '#e17c5a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e0e0ff'
  primary-fixed-dim: '#bdc2ff'
  on-primary-fixed: '#000767'
  on-primary-fixed-variant: '#343d96'
  secondary-fixed: '#cfe6f2'
  secondary-fixed-dim: '#b4cad6'
  on-secondary-fixed: '#071e27'
  on-secondary-fixed-variant: '#354a53'
  tertiary-fixed: '#ffdbd0'
  tertiary-fixed-dim: '#ffb59d'
  on-tertiary-fixed: '#390c00'
  on-tertiary-fixed-variant: '#7b2e12'
  background: '#fbf8ff'
  on-background: '#1b1b21'
  surface-variant: '#e4e1ea'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 8px
  touch-target: 48px
  gutter: 16px
  margin-mobile: 16px
  margin-tablet: 24px
---

## Brand & Style

This design system is engineered for the rigors of industrial environments, prioritizing utility, reliability, and speed. The brand personality is authoritative and stoic, designed to feel like a high-precision tool rather than a consumer app. It serves a dual audience of site supervisors and field workers who require immediate data clarity in high-pressure, often outdoor or low-light, settings.

The visual style is **Corporate / Modern**, heavily influenced by Material Design 3. It utilizes a "Form-First" philosophy, where every interface element is optimized for rapid data entry and high-frequency touch interactions. By stripping away decorative flourishes in favor of structural integrity and tonal hierarchy, the design system ensures that the user's cognitive load is reserved for task management and operational accuracy.

## Colors

The color palette is anchored by **Deep Blue (#1A237E)**, used for primary navigation and high-importance actions to instill a sense of stability and professional oversight. The background utilizes **Light Grey (#F5F5F5)** to reduce glare and provide a neutral stage for data-heavy views.

Semantic colors are strictly regulated to provide instant status recognition:
- **Success (Green):** Indicates completed shifts, verified attendance, and positive balances.
- **Warning (Amber):** Specifically reserved for overtime alerts and pending approvals.
- **Alert (Red):** Used for 'Upad' (advance payments/deductions) and critical system errors.

Tonal variations of these colors should be used for background containers (e.g., a very light amber for an overtime row) to ensure the UI remains readable while maintaining a strong information hierarchy.

## Typography

This design system utilizes **Inter** for all typographic levels. Inter was chosen for its exceptional legibility in data-dense environments and its neutral, systematic character. 

The type scale is optimized for high-speed scanning. Headlines are bold and heavy to provide clear section anchoring. Labels and body text prioritize vertical rhythm to ensure that lists of worker names, timestamps, and currency values are easily distinguishable. For numerical data entry, tabular figures (monospace-width numbers) should be used where possible to ensure columns of figures align perfectly in data grids.

## Layout & Spacing

The layout follows a **fluid grid system** built on an **8px base unit**. This ensures consistent alignment across varying screen sizes, from mobile phones to ruggedized tablets. 

Key layout principles:
- **Touch-First Sizing:** All interactive elements (buttons, inputs, list items) must maintain a minimum height of 48px to accommodate use in field conditions.
- **Surface-Based Layout:** Content is organized into distinct cards or "surfaces" that span the width of the container, separated by 8px or 16px gutters.
- **Data Grids:** For offline-first worker management, grids should favor a "stacked" approach on narrow viewports, converting into horizontal rows only on tablet-sized screens or larger.

## Elevation & Depth

This design system uses **Tonal Layers** and **Ambient Shadows** to communicate hierarchy. In accordance with Material Design 3, elevation is primarily expressed through color shifts of the surface. 

- **Level 0 (Background):** #F5F5F5.
- **Level 1 (Cards/Inputs):** White (#FFFFFF) with a subtle, diffused shadow (4px blur, 10% opacity) to provide separation from the background.
- **Level 2 (Active States/Dialogs):** White with a more pronounced shadow and a 5% primary color tint overlay.

The use of "tonal elevation" ensures that even when the screen is viewed in direct sunlight, the physical separation of data modules remains clear through contrast rather than complex gradients.

## Shapes

The design system employs a **Soft (Level 1)** roundedness profile. This 4px corner radius (0.25rem) strikes a balance between the precision of an industrial tool and the approachability of a modern application. 

- **Components:** Buttons, text fields, and chips use a 4px radius.
- **Containers:** Large surface cards or modal sheets use a 8px (rounded-lg) radius to create a soft container for data-heavy content.
- **Icons:** Icons should be framed within square or slightly rounded enclosures to maintain the systematic, grid-like feel of the interface.

## Components

### Buttons & Actions
Buttons are high-contrast. **Primary Actions** use the Deep Blue background with white text. **Secondary Actions** use an outlined style with a 1px border. All buttons must maintain the 48px minimum height.

### Input Fields
Following the "Form-First" philosophy, inputs feature a solid background color (#EEEEEE) with a prominent bottom border that thickens when focused. Labels always remain visible (floating or top-aligned) to provide context during data entry.

### Chips & Status Indicators
Chips are used for attendance status and work types. They use a filled tonal background of the semantic color (e.g., light green background for a "Present" chip) with dark text to maximize legibility.

### List Items
Worker lists are the core of the app. Each list item is a high-density surface featuring a left-aligned icon (person), a primary title (worker name), and right-aligned metadata (clock-in time or payment status).

### Specialized Components
- **The Upad Card:** A specific red-tinted card for advance payments to ensure they are never overlooked.
- **Real-time Feedback Toasts:** Large, bottom-aligned notifications that confirm data has been saved locally—critical for the offline-first experience.
- **Icon Set:** Use a consistent line-weight icon set for Calendar, Person, Currency, and Clock to allow for "glanceable" navigation without reading text.