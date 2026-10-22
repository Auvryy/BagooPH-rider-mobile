#!/usr/bin/env python3
"""Cache public sample artwork for opt-in Home renders; never print client keys."""

import argparse
import json
import pathlib
import re
import time
import urllib.error
import urllib.parse
import urllib.request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default=".env.geoapify.json")
    parser.add_argument("--needed", default="build/map-refinement/tiles-needed.txt")
    parser.add_argument("--output", default="build/map-refinement/artwork")
    args = parser.parse_args()
    try:
        key = json.loads(pathlib.Path(args.config).read_text()).get(
            "GEOAPIFY_API_KEY", ""
        ).strip()
    except (OSError, ValueError, AttributeError):
        raise SystemExit("Read a valid private Geoapify configuration first.") from None
    if not key:
        raise SystemExit("The private Geoapify configuration has no map key.")
    needed = pathlib.Path(args.needed)
    if not needed.is_file():
        raise SystemExit("Run the opt-in map renders first to collect tile requests.")
    pattern = re.compile(
        r"(dark-matter|dark-matter-dark-grey|osm-bright-smooth)/"
        r"(\d{1,2})-(\d+)-(\d+)(@2x)?\.png"
    )
    paths = []
    for name in sorted(set(needed.read_text().splitlines())):
        match = pattern.fullmatch(name)
        if not match:
            raise SystemExit("The requested artwork list has an unsupported tile.")
        style, zoom, x, y, density = match.groups()
        if not 0 <= int(zoom) <= 19 or not all(
            0 <= int(value) < 2 ** int(zoom) for value in (x, y)
        ):
            raise SystemExit("The requested artwork list has invalid coordinates.")
        paths.append((name, f"/v1/tile/{style}/{zoom}/{x}/{y}{density or ''}.png"))
    output = pathlib.Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    count = 0
    last = 0

    def get(host, path, query):
        nonlocal last, count
        time.sleep(max(0, 0.28 - (time.monotonic() - last)))
        last = time.monotonic()
        url = "https://" + host + path + "?" + urllib.parse.urlencode(
            {**query, "apiKey": key}
        )
        request = urllib.request.Request(
            url, headers={"User-Agent": "BagooPH-Rider-map-review"}
        )
        try:
            with urllib.request.urlopen(request, timeout=25) as response:
                data = response.read()
        except urllib.error.HTTPError as error:
            raise SystemExit(
                f"Geoapify returned HTTP {error.code}; requests stopped. "
                "Check the provider account before retrying."
            ) from None
        except (OSError, ValueError):
            raise SystemExit("The map connection failed; requests stopped.") from None
        count += 1
        return data

    # Public, fixed sample coordinates, never an account's position or parcel.
    route = output / "sample-route.json"
    if not route.exists():
        data = get(
            "api.geoapify.com",
            "/v1/routing",
            {"waypoints": "14.6,121|14.606,121.008", "mode": "motorcycle", "format": "geojson"},
        )
        try:
            valid = json.loads(data).get("type") == "FeatureCollection"
        except (ValueError, AttributeError):
            valid = False
        if not valid:
            raise SystemExit("Geoapify returned no sample route; requests stopped.")
        route.write_bytes(data)
    for name, path in paths:
        file = output / name
        if file.exists():
            continue
        data = get("maps.geoapify.com", path, {})
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise SystemExit("Geoapify returned invalid artwork; requests stopped.")
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_bytes(data)
    print(json.dumps({"provider_requests": count, "cached_tiles": len(paths)}))


if __name__ == "__main__":
    main()
