# Rider design visual assets

These are original editable documentation illustrations with synthetic values.
They are not screenshots of a running app or proof of device usability.
The October 9 illustrations are historical proposals. The October 15 delivery
redesign supersedes their styling. Current tokens and runtime render-review
instructions live in [the redesign plan](../../plans/rider-ui-redesign/README.md).
[Current runtime captures](../../plans/rider-ui-redesign/RENDER_REVIEW.md) show
the implemented design using synthetic data.

- [storyboard.png](storyboard.png) shows eight full compositions.
- [storyboard.svg](storyboard.svg) is its editable vector source.
- P01, P05, P06, P08, P11, P12, P22 and P25 each have an individual SVG.
- [adaptive-layouts.png](adaptive-layouts.png) and its SVG show three layout
  compositions; they are sketches, not literal scaled device dimensions.
- [action-placement.png](action-placement.png) and its SVG show inset-aware
  symmetric action placement to test with both hands.

The storyboard can be regenerated using the included drawing tool. The SVG uses generic sans-serif type; the portable PNG renderer loads the
bundled fallback font explicitly. Current native screenshot review loads bundled Plus Jakarta Sans and Material icons.
The font used for documentation rendering is not a newly bundled app dependency.
Editable SVG text can fall back to a local font when that family is unavailable;
the PNG is the portable visual reference.

Rasterize the other edited SVG sketches using a standard SVG renderer with the
same licensed font. Camera/photo thumbnails and map streets in these drawings
are intentionally illustrative. Actual proof, map data, attribution and states
need the accepted implementation.
