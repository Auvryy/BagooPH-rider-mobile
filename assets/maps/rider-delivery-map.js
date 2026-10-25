(function () {
  'use strict';
  var sample = window.riderDeliverySample;
  var points = sample.coordinates;
  var map = L.map('map', {
    preferCanvas: true, zoomControl: false, scrollWheelZoom: false,
    zoomAnimation: false, fadeAnimation: false, markerZoomAnimation: false,
    inertia: false, keyboard: true
  });
  var tiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19, keepBuffer: 1,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap contributors</a>'
  }).addTo(map);
  map.attributionControl.setPrefix(false);
  L.polyline(points, {color: '#FFFFFF', weight: 7, interactive: false}).addTo(map);
  L.polyline(points, {color: '#E00D42', weight: 4, dashArray: '6 6', interactive: false}).addTo(map);
  L.circleMarker(points[0], {radius: 9, color: '#FFFFFF', weight: 3, fillColor: '#18181B', fillOpacity: 1}).addTo(map).bindTooltip(sample.riderLabel);
  L.circleMarker(points[points.length - 1], {radius: 9, color: '#FFFFFF', weight: 3, fillColor: '#E00D42', fillOpacity: 1}).addTo(map).bindTooltip(sample.deliveryLabel);
  function fit() { map.fitBounds(points, {padding: [48, 64], maxZoom: 16, animate: false}); }
  var zoom = L.control.zoom({position: 'bottomright'}).addTo(map);
  var controls = L.control({position: 'bottomright'});
  controls.onAdd = function () {
    var host = L.DomUtil.create('div', 'leaflet-bar');
    var button = L.DomUtil.create('button', 'fit-route', host);
    button.type = 'button'; button.textContent = '↗';
    button.setAttribute('aria-label', 'Show sample route'); button.title = 'Show sample route';
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
