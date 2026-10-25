import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
const runtime=readFileSync(new URL('../assets/maps/rider-delivery-map.js',import.meta.url),'utf8');
const sample=JSON.parse(readFileSync(new URL('../assets/maps/rider-delivery-sample.json',import.meta.url),'utf8'));
function run(){
 const h={lines:[],pins:[],events:[],handlers:{},removed:0,disconnected:0,attribution:null};
 const map={attributionControl:{setPrefix(){}},fitBounds(points,options){h.fit={points,options}},invalidateSize(){},remove(){h.removed++}};
 const node=()=>({setAttribute(){},addEventListener(type,cb){h.attribution=cb}});
 const L={map:(id,options)=>{h.options=options;return map},tileLayer:(url,options)=>{h.url=url;h.tiles=options;return {addTo(){return this},on(type,cb){h.handlers[type]=cb;return this}}},
  polyline:(points,options)=>{h.lines.push({points,options});return{addTo(){return this}}},
  circleMarker:(point,options)=>{const pin={point,options};h.pins.push(pin);return{addTo(){return this},bindTooltip(label){pin.label=label;return this}}},
  control:()=>({addTo(){this.onAdd?.();return this}}),
  DomUtil:{create:node},DomEvent:{disableClickPropagation(){},on(){}}};
 L.control.zoom=()=>({addTo(){return this}});
 const window={riderDeliverySample:sample,BagooMap:{postMessage:value=>h.events.push(JSON.parse(value))},addEventListener(type,cb){h.hide=cb}};
 vm.runInNewContext(runtime,{L,window,document:{querySelectorAll:()=>[node(),node()],querySelector:node,getElementById:node},ResizeObserver:class{observe(){}disconnect(){h.disconnected++}},fetch(){throw Error('Unexpected API request')},navigator:{get geolocation(){throw Error('Unexpected GPS access')}}});
 return h;
}
test('the Leaflet runtime draws one labelled sample line with two endpoints and no provider request',()=>{
 const h=run();assert.equal(h.url,'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
 assert.equal(h.lines.length,2);assert.deepEqual(h.lines[1].points,sample.coordinates);
 assert.equal(h.lines[1].options.color,'#E00D42');assert.equal(h.lines[1].options.dashArray,undefined);assert.equal(h.lines[1].options.smoothFactor,0);
 assert.deepEqual(h.pins.map(p=>p.label),[sample.riderLabel,sample.deliveryLabel]);
 assert.equal(h.options.preferCanvas,true);assert.equal(h.options.scrollWheelZoom,false);
 assert.equal(h.options.dragging,true);assert.equal(h.options.touchZoom,true);assert.equal(h.options.inertia,true);
 assert.deepEqual(h.fit.points,sample.coordinates);assert.ok(h.events.some(e=>e.type==='ready'));
});
test('tile errors are bounded, attribution is deliberate, and hiding releases the map',()=>{
 const h=run();h.handlers.tileerror();h.handlers.tileerror();
 assert.equal(h.events.filter(e=>e.type==='tiles-unavailable').length,1);
 let prevented=false;h.attribution({preventDefault(){prevented=true}});assert.equal(prevented,true);
 assert.equal(h.events.at(-1).type,'attribution');h.hide();assert.equal(h.removed,1);assert.equal(h.disconnected,1);
});
