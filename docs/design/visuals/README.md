# Rider design visual assets

These are original editable documentation illustrations with synthetic values.
They are not screenshots of a running app or proof of device usability.

- [storyboard.png](storyboard.png) shows eight full compositions.
- [storyboard.svg](storyboard.svg) is its editable vector source.
- P01, P05, P06, P08, P11, P12, P22 and P25 each have an individual SVG.
- [adaptive-layouts.png](adaptive-layouts.png) and its SVG show three layout
  compositions; they are sketches, not literal scaled device dimensions.
- [action-placement.png](action-placement.png) and its SVG show inset-aware
  symmetric action placement to test with both hands.

The storyboard can be regenerated using the included drawing tool. For accurate
PNG type, pass a local licensed Plus Jakarta Sans font to its font-file option.
The font used for documentation rendering is not a newly bundled app dependency.
Editable SVG text can fall back to a local font when that family is unavailable;
the PNG is the portable visual reference.

Rasterize the other edited SVG sketches using a standard SVG renderer with the
same licensed font. Camera/photo thumbnails and map streets in these drawings
are intentionally illustrative. Actual proof, map data, attribution and states
need the accepted implementation.
