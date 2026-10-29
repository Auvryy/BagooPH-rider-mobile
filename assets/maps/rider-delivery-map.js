(function () {
  'use strict';
  var sample = window.riderDeliverySample;
  var stop = window.riderSavedStop;
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
  if (stop) {
    var label = document.createElement('span'); label.textContent = stop.label;
    L.circleMarker(points[0], {radius: 9, color: '#FFFFFF', weight: 3, fillColor: '#E00D42', fillOpacity: 1}).addTo(map).bindTooltip(label);
  } else {
    L.polyline(points, {color: '#FFFFFF', weight: 8, smoothFactor: 0, lineCap: 'round', lineJoin: 'round', interactive: false}).addTo(map);
    L.polyline(points, {color: '#E00D42', weight: 5, smoothFactor: 0, lineCap: 'round', lineJoin: 'round', interactive: false}).addTo(map);
    L.circleMarker(points[0], {radius: 9, color: '#FFFFFF', weight: 3, fillColor: '#18181B', fillOpacity: 1}).addTo(map).bindTooltip(sample.riderLabel);
    L.circleMarker(points[points.length - 1], {radius: 9, color: '#FFFFFF', weight: 3, fillColor: '#E00D42', fillOpacity: 1}).addTo(map).bindTooltip(sample.deliveryLabel);
  }
  function fit() {
    if (stop) map.setView(points[0], 16, {animate: false});
    else map.fitBounds(points, {padding: [48, 64], maxZoom: 16, animate: false});
  }
  var zoom = L.control.zoom({position: 'bottomright'}).addTo(map);
  var controls = L.control({position: 'bottomright'});
  controls.onAdd = function () {
    var host = L.DomUtil.create('div', 'leaflet-bar');
    var button = L.DomUtil.create('button', 'fit-route', host);
    button.type = 'button'; button.textContent = '↗';
    var fitLabel = stop ? 'Recenter current stop' : 'Show sample route';
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
