(function () {
  'use strict';
  var sample = window.riderDeliverySample;
  var stop = window.riderSavedStop;
  var standby = window.riderStandby === true;
  if (stop && (!Number.isFinite(stop.latitude) || !Number.isFinite(stop.longitude) ||
      Math.abs(stop.latitude) > 85 || Math.abs(stop.longitude) > 180 || typeof stop.label !== 'string')) {
    message('tiles-unavailable'); return;
  }
  var points = stop ? [[stop.latitude, stop.longitude]] : sample.coordinates;
  var map = L.map('map', {
    preferCanvas: true, zoomControl: false, scrollWheelZoom: false,
    zoomAnimation: false, fadeAnimation: false, markerZoomAnimation: false,
    dragging: true, touchZoom: true,
    inertia: !(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches),
    inertiaMaxSpeed: 1500, keyboard: true
  });
  var tiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19, keepBuffer: 1,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap contributors</a>'
  }).addTo(map);
  map.attributionControl.setPrefix(false);
  var routeLayers = [];
  window.setRiderRoadRoute = function (lines) {
    routeLayers.forEach(function (layer) { layer.remove(); });
    routeLayers = [];
    if (!stop || lines === null || standby) return;
    var count = 0;
    if (!Array.isArray(lines) || lines.length === 0 || lines.length > 100 || !lines.every(function (line) {
      return Array.isArray(line) && line.length >= 2 && line.every(function (point) {
        return ++count <= 10000 && Array.isArray(point) && point.length === 2 && Number.isFinite(point[0]) && Number.isFinite(point[1]) && Math.abs(point[0]) <= 85 && Math.abs(point[1]) <= 180;
      });
    })) return;
    lines.forEach(function (line) {
      routeLayers.push(L.polyline(line, {color: '#FFFFFF', weight: 8, interactive: false}).addTo(map));
      routeLayers.push(L.polyline(line, {color: '#E00D42', weight: 5, interactive: false}).addTo(map));
    });
    routeLayers.push(L.circleMarker(lines[0][0], {radius: 8, color: '#FFFFFF', weight: 3, fillColor: '#18181B', fillOpacity: 1}).addTo(map).bindTooltip('Route start'));
    map.fitBounds(lines.reduce(function (all, line) { return all.concat(line); }, []), {padding: [48, 64], maxZoom: 16, animate: false});
  };
  if (standby) {
    // When in standby / no active orders: clean map showing only where the rider is at
    L.circleMarker(points[0], {radius: 9, color: '#FFFFFF', weight: 3, fillColor: '#18181B', fillOpacity: 1}).addTo(map).bindTooltip('Your location');
  } else if (stop) {
    var label = document.createElement('span'); label.textContent = stop.label;
    L.circleMarker(points[0], {radius: 9, color: '#FFFFFF', weight: 3, fillColor: '#E00D42', fillOpacity: 1}).addTo(map).bindTooltip(label);
  } else {
    L.polyline(sample.coordinates, {color: '#FFFFFF', weight: 8, smoothFactor: 0, lineCap: 'round', lineJoin: 'round', interactive: false}).addTo(map);
    L.polyline(sample.coordinates, {color: '#E00D42', weight: 5, smoothFactor: 0, lineCap: 'round', lineJoin: 'round', interactive: false}).addTo(map);
    L.circleMarker(points[0], {radius: 9, color: '#FFFFFF', weight: 3, fillColor: '#18181B', fillOpacity: 1}).addTo(map).bindTooltip(sample.riderLabel);
    L.circleMarker(points[points.length - 1], {radius: 9, color: '#FFFFFF', weight: 3, fillColor: '#E00D42', fillOpacity: 1}).addTo(map).bindTooltip(sample.deliveryLabel);
  }
  function fit() {
    if (!standby && !stop && points.length > 1) {
      map.fitBounds(points, {padding: [48, 64], maxZoom: 16, animate: false});
    } else {
      map.setView(points[0], 16, {animate: false});
    }
  }
  var zoom = L.control.zoom({position: 'bottomright'}).addTo(map);
  var controls = L.control({position: 'bottomright'});
  controls.onAdd = function () {
    var host = L.DomUtil.create('div', 'leaflet-bar');
    var button = L.DomUtil.create('button', 'fit-route', host);
    button.type = 'button'; button.textContent = '↗';
    var fitLabel = stop ? 'Recenter current stop' : 'Recenter your location';
    button.setAttribute('aria-label', fitLabel); button.title = fitLabel;
    L.DomEvent.disableClickPropagation(host);
    L.DomEvent.on(button, 'click', fit);
    return host;
  };
  controls.addTo(map);
  document.querySelectorAll('.leaflet-control-zoom a').forEach(function (button) { button.setAttribute('role', 'button'); });
  function message(type) { if (window.BagooMap) window.BagooMap.postMessage(JSON.stringify({type: type})); }
  var failures = 0;
  tiles.on('tileerror', function () { if (++failures === 1) message('tiles-unavailable'); });
  tiles.on('load', function () { if (!failures) message('tiles-ready'); });
  document.querySelector('.leaflet-control-attribution').addEventListener('click', function (event) {
    event.preventDefault(); message('attribution');
  });
  var observer = new ResizeObserver(function () { map.invalidateSize({pan: false}); });
  observer.observe(document.getElementById('map'));
  window.addEventListener('pagehide', function () { observer.disconnect(); map.remove(); }, {once: true});
  fit();
  message('ready');
})();
