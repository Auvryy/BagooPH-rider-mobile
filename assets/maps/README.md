# Philippines display outline

`philippines-display.geojson` is a modified national ADM0 outline, not a legal
boundary or a Bagoo service-eligibility rule. Task coordinates and authorization
remain server-owned. The asset retains every source island and is used only to
mask neighbouring basemap artwork.

Source: **OCHA Philippines / National Mapping and Resource Information Authority
(NAMRIA), 2020**, provided by **geoBoundaries**, boundary `PHL-ADM0-24100683`.
The upstream national source is distributed under
[CC BY 3.0 IGO](https://creativecommons.org/licenses/by/3.0/igo/);
geoBoundaries provides its database under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
These licenses allow redistribution/adaptation with credit, license links and
an indication of changes. No endorsement is implied.

- [Source dataset](https://data.humdata.org/dataset/philippines-administrative-levels-0-to-3)
- [Pinned full GeoJSON](https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/PHL/ADM0/geoBoundaries-PHL-ADM0.geojson)
- [Provider attribution](https://www.geoboundaries.org/index.html#usage)
- [Exact source/asset fingerprints and derivation](philippines-display-source.json)

Changes: topology-preserving simplification at 0.0005 degrees, with original
coordinate precision and all 2,852 source polygons retained. The source's
pre-simplified file is not used because it omits islands. The geometry remains a
display approximation, especially near coastlines; it does not reject a task.

Regenerate from the pinned full source with Shapely 2.1.2 in a development Python
environment and [the derivation tool](../../tool/build_philippines_map.py).
The app has no Python dependency. Map credits expose the attribution, source,
licenses and modification notice beside the map's provider credits.
