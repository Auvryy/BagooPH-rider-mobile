#!/usr/bin/env python3
"""Derive the bundled display outline from the pinned public ADM0 source.

Use Shapely 2.1.2 in a development environment, then pass the downloaded full
GeoJSON as the sole argument. The Flutter app does not depend on Python/Shapely.
The source SHA is checked before any generated file is written.
"""

import hashlib
import json
import sys
from pathlib import Path

from shapely.geometry import mapping, shape

SOURCE_SHA = "7c3a7a39dacb5fb0c14d150061306fa5839455fbf93231854af3c6d74a1fa24f"
SOURCE_URL = (
    "https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/"
    "PHL/ADM0/geoBoundaries-PHL-ADM0.geojson"
)
TOLERANCE = 0.0005


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Pass the pinned full Philippines GeoJSON file.")
    source = Path(sys.argv[1]).read_bytes()
    if hashlib.sha256(source).hexdigest() != SOURCE_SHA:
        raise SystemExit("Source fingerprint differs; review its data/license first.")
    features = json.loads(source)["features"]
    if len(features) != 1:
        raise SystemExit("Expected one national ADM0 feature.")
    original = shape(features[0]["geometry"])
    derived = original.simplify(TOLERANCE, preserve_topology=True)
    if (
        original.geom_type != "MultiPolygon"
        or derived.geom_type != "MultiPolygon"
        or len(original.geoms) != 2852
        or len(derived.geoms) != len(original.geoms)
        or not derived.is_valid
        or sum(len(p.interiors) for p in derived.geoms)
        != sum(len(p.interiors) for p in original.geoms)
    ):
        raise SystemExit("Island/topology preservation did not pass.")
    geometry = mapping(derived)
    # Keep source precision: rounding could erase the smallest islands.
    polygons = geometry["coordinates"]
    root = Path(__file__).resolve().parents[1]
    folder = root / "assets/maps"
    folder.mkdir(parents=True, exist_ok=True)
    # One polygon per line keeps the generated asset reviewable.
    output = '{"type":"MultiPolygon","coordinates":[\n' + ",\n".join(
        json.dumps(p, separators=(",", ":")) for p in polygons
    ) + "\n]}\n"
    (folder / "philippines-display.geojson").write_text(output)
    counts = {
        "source": SOURCE_URL,
        "sourceSha256": SOURCE_SHA,
        "sourceYear": "2020",
        "boundaryId": "PHL-ADM0-24100683",
        "sourceAttribution": "OCHA Philippines / NAMRIA, via geoBoundaries",
        "licenses": [
            "https://creativecommons.org/licenses/by/3.0/igo/",
            "https://creativecommons.org/licenses/by/4.0/",
        ],
        "changes": "Topology-preserving simplification; all source islands retained.",
        "toleranceDegrees": TOLERANCE,
        "sourcePolygons": len(original.geoms),
        "polygons": len(polygons),
        "vertices": sum(len(r) for p in polygons for r in p),
        "bounds": list(derived.bounds),
        "assetBytes": len(output.encode()),
        "assetSha256": hashlib.sha256(output.encode()).hexdigest(),
    }
    (folder / "philippines-display-source.json").write_text(
        json.dumps(counts, indent=2) + "\n"
    )
    print(json.dumps(counts, indent=2))


if __name__ == "__main__":
    main()
