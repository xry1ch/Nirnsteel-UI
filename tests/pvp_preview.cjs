// Geometry/motion QA without an ESO client. Samples the actual Lua module using
// the regression harness and paints its native polygons; this is NOT an ESO
// renderer (font metrics, antialiasing and border feathering can differ).
// node tests/pvp_preview.cjs <output-directory> [node_modules-directory]
const fs = require('node:fs');
const path = require('node:path');
const {createRequire} = require('node:module');
const deps = process.argv[3] ? createRequire(path.resolve(process.argv[3], '../package.json')) : require;
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = deps('fengari');
const output = path.resolve(process.argv[2] || 'tests/pvp-preview');
const test = fs.readFileSync('tests/pvp_regression.lua', 'utf8');
const marker = 'local root = PvP:GetRoot()';
if (!test.includes(marker)) throw new Error('Regression harness boundary changed');
let harness = test.slice(0, test.indexOf(marker));
harness = harness.replace('local function NewControl(parent)', 'local captureControls = {}\nlocal function NewControl(parent)');
harness = harness.replace('    return control', '    control.id = #captureControls + 1\n    captureControls[control.id] = control\n    return control');
const capture = `
local function JSON(value)
    if type(value) == "number" then return string.format("%.4f", value) end
    if type(value) == "boolean" then return tostring(value) end
    if type(value) == "string" then return '"' .. value:gsub('\\\\', '\\\\\\\\'):gsub('"', '\\\\"'):gsub('\\n', '\\\\n') .. '"' end
    if type(value) ~= "table" then return "null" end
    if next(value) == nil then return "[]" end
    local result = {}
    if #value > 0 then
        for _, item in ipairs(value) do result[#result + 1] = JSON(item) end
        return "[" .. table.concat(result, ",") .. "]"
    end
    for key, item in pairs(value) do result[#result + 1] = JSON(key) .. ":" .. JSON(item) end
    return "{" .. table.concat(result, ",") .. "}"
end
local root = PvP:GetRoot()
local scene = {}
for _, c in ipairs(captureControls) do
    scene[#scene + 1] = {
        id = c.id, parent = c.parent and c.parent.id or 0, w = c.width, h = c.height,
        x = c.anchor and c.anchor[4] or 0, y = c.anchor and c.anchor[5] or 0,
        origin = c.transformOrigin or {0.5, 0.5}, points = c.points or false,
        border = c.borderThickness and c.borderThickness[1] or 0,
        level = c.drawLevel or 0, layer = c.drawLayer or 2, font = c.font or false,
    }
end
Capture(JSON({root = root.id, scene = scene}))
local previous = {}
local function Frame(time)
    local changes = {}
    for _, c in ipairs(captureControls) do
        local o = c.transformOffset or {0, 0}
        local state = {c.alpha, c.hidden, c.scale, c.transformScale or 1,
            c.transformScaleX or 1, c.rotation or 0, o[1], o[2],
            c.centerColor or false, c.borderColor or false, c.color or false, c.text or false}
        local encoded = JSON(state)
        if previous[c.id] ~= encoded then
            changes[#changes + 1] = {c.id, state}
            previous[c.id] = encoded
        end
    end
    Capture(JSON({time = time, changes = changes}))
end
for _, count in ipairs({1, 4, 8}) do
    PvP:ResetState(true)
    nowMS = 10000
    previous = {}
    Capture(JSON({clip = "x" .. count, duration = 960}))
    PvP:ShowCelebration(count, true)
    for elapsed = 0, 960, 16 do
        nowMS = 10000 + elapsed
        PvP:UpdateAnimation()
        Frame(elapsed)
    end
end
PvP:ResetState(true)
nowMS = 20000
previous = {}
Capture(JSON({clip = "chain", duration = 4048}))
PvP:DebugChain()
for elapsed = 0, 4048, 16 do
    Advance(elapsed == 0 and 0 or 16)
    Frame(elapsed)
end
`;
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const records = [];
lua.lua_pushjsfunction(L, state => { records.push(JSON.parse(to_jsstring(lua.lua_tostring(state, 1)))); return 0; });
lua.lua_setglobal(L, to_luastring('Capture'));
if (lauxlib.luaL_dostring(L, to_luastring(harness + capture)) !== lua.LUA_OK) {
    throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
}
const data = {...records.shift(), clips: {}};
let clip;
for (const record of records) {
    if (record.clip) clip = data.clips[record.clip] = {duration: record.duration, frames: []};
    else clip.frames.push(record);
}
const html = `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>PvP · native Lua animation study</title><style>
*{box-sizing:border-box}body{margin:0;background:#0c1115;color:#dce2e6;font:14px system-ui}main{max-width:1080px;margin:48px auto;padding:0 24px}header{display:flex;justify-content:space-between;align-items:end}h1{font-size:28px;letter-spacing:-1px;font-weight:550;margin:8px 0}small{color:#91a1aa;letter-spacing:2px;text-transform:uppercase;font-size:10px}p{color:#98a8b1;line-height:1.6}canvas{display:block;width:100%;height:430px;margin-top:24px;border:1px solid #263139;border-radius:10px;background:#121c20}nav{display:flex;gap:8px;align-items:center;flex-wrap:wrap;margin-top:18px}button,select{background:#1a252d;border:1px solid #34424b;border-radius:6px;color:#dce2e6;padding:9px 15px;cursor:pointer}button.active{background:#d6e7ec;color:#10191d;border-color:#d6e7ec}label{color:#9cadb7;margin-left:auto}input{accent-color:#b7dae9}#scrub{width:100%;margin:22px 0 8px}footer{display:flex;justify-content:space-between;font-size:12px;color:#7e919d}.note{max-width:760px;font-size:12px}
</style><main><header><div><small>Nirnsteel UI / PvP</small><h1>One kill. One card.</h1></div><small>Steel / ice / fire</small></header>
<canvas id="view" aria-label="Actual Lua kill celebration animation"></canvas>
<nav><button data-clip="x1">×1</button><button data-clip="x4">×4</button><button data-clip="x8">×8</button><button data-clip="chain" class="active">8-kill chain</button><button id="play">Pause</button><select id="speed" aria-label="Playback speed"><option value="1">1× speed</option><option value="0.25">0.25× slow motion</option></select><label>Zoom <select id="zoom"><option value="1">100%</option><option value="2" selected>200%</option><option value="3">300%</option></select></label></nav>
<input id="scrub" type="range" min="0" max="4048" value="0" step="16" aria-label="Animation time"><footer><span id="time">0 ms</span><span>420 × 150 logical HUD</span></footer>
<p class="note">Geometry and keyframes sampled from modules/pvp.lua. This is a silent diagnostic renderer, not footage from ESO: font metrics, polygon borders, and antialiasing still need an in-game check.</p></main><script>
const DATA = ${JSON.stringify(data)};
const canvas=document.querySelector('#view'),ctx=canvas.getContext('2d'),scrub=document.querySelector('#scrub');
let selected='chain',elapsed=0,playing=true,last=performance.now(),speed=1,zoom=2;
function mul(a,b){return[a[0]*b[0]+a[2]*b[1],a[1]*b[0]+a[3]*b[1],a[0]*b[2]+a[2]*b[3],a[1]*b[2]+a[3]*b[3],a[0]*b[4]+a[2]*b[5]+a[4],a[1]*b[4]+a[3]*b[5]+a[5]]}
function rgba(c){return c?'rgba('+c.slice(0,3).map(v=>Math.round(v*255)).join(',')+','+(c[3]??1)+')':'transparent'}
function paint(at){
const states={};for(const frame of DATA.clips[selected].frames){if(frame.time>at)break;for(const [id,s] of frame.changes)states[id]=s}
const dpr=devicePixelRatio||1,w=canvas.clientWidth,h=canvas.clientHeight;if(canvas.width!==w*dpr||canvas.height!==h*dpr){canvas.width=w*dpr;canvas.height=h*dpr}
ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,w,h);
let bg=ctx.createLinearGradient(0,0,w,h);bg.addColorStop(0,'#253236');bg.addColorStop(.5,'#162125');bg.addColorStop(1,'#35372d');ctx.fillStyle=bg;ctx.fillRect(0,0,w,h);
// Quiet terrain-like values only; no mock HUD graphics behind the badge.
ctx.fillStyle='#0a14152d';ctx.beginPath();ctx.moveTo(0,h);ctx.lineTo(0,h*.55);ctx.lineTo(w*.28,h*.48);ctx.lineTo(w*.6,h*.68);ctx.lineTo(w,h*.42);ctx.lineTo(w,h);ctx.fill();
const world={};
function transform(n){if(world[n.id])return world[n.id];const s=states[n.id];if(!s)return null;
let parent=n.id===DATA.root?{m:[1,0,0,1,0,0],a:1}:transform(DATA.scene[n.parent-1]);if(!parent)return null;
let x=n.id===DATA.root?0:n.x,y=n.id===DATA.root?0:n.y;
const px=(n.origin[0]-.5)*n.w,py=(n.origin[1]-.5)*n.h,scale=s[2]*s[3],sx=scale*s[4],sy=scale,c=Math.cos(s[5]),si=Math.sin(s[5]);
let local=[c*sx,si*sx,-si*sy,c*sy,x+s[6]+px-c*sx*px+si*sy*py,y+s[7]+py-si*sx*px-c*sy*py];
return world[n.id]={m:mul(parent.m,local),a:parent.a*s[0]*(s[1]?0:1)};
}
const descendants=DATA.scene.filter(n=>{let p=n;while(p){if(p.id===DATA.root)return true;p=DATA.scene[p.parent-1]}return false}).sort((a,b)=>a.layer-b.layer||a.level-b.level||a.id-b.id);
for(const n of descendants){const s=states[n.id],tr=transform(n);if(!s||!tr||tr.a<.001||(!n.points&&!s[11]))continue;
ctx.setTransform(dpr*zoom,0,0,dpr*zoom,w*dpr/2,h*dpr/2);ctx.transform(...tr.m);ctx.globalAlpha=Math.min(1,tr.a);
if(n.points){ctx.beginPath();n.points.forEach((p,i)=>ctx[i?'lineTo':'moveTo']((p[0]-.5)*n.w,(p[1]-.5)*n.h));ctx.closePath();ctx.fillStyle=rgba(s[8]);ctx.fill();if(n.border&&s[9]){ctx.save();ctx.clip();ctx.strokeStyle=rgba(s[9]);ctx.lineWidth=n.border*2;ctx.stroke();ctx.restore()}}
else if(s[11]){ctx.font='700 21px Arial';ctx.textAlign='center';ctx.textBaseline='middle';ctx.shadowColor='#000b';ctx.shadowBlur=2;ctx.fillStyle=rgba(s[10]);ctx.fillText(s[11],0,1);ctx.shadowBlur=0}
}ctx.globalAlpha=1;scrub.value=at;document.querySelector('#time').textContent=Math.round(at)+' ms';
}
window.setFrame=(name,time)=>{selected=name;elapsed=time;playing=false;scrub.max=DATA.clips[name].duration;document.querySelector('#play').textContent='Replay';paint(time)};
document.querySelectorAll('[data-clip]').forEach(b=>b.onclick=()=>{selected=b.dataset.clip;elapsed=0;playing=true;scrub.max=DATA.clips[selected].duration;document.querySelectorAll('[data-clip]').forEach(x=>x.classList.toggle('active',x===b));document.querySelector('#play').textContent='Pause'});
document.querySelector('#play').onclick=()=>{playing=!playing;if(playing&&elapsed>=DATA.clips[selected].duration)elapsed=0;document.querySelector('#play').textContent=playing?'Pause':'Replay'};
document.querySelector('#speed').onchange=e=>speed=+e.target.value;document.querySelector('#zoom').onchange=e=>{zoom=+e.target.value;paint(elapsed)};
scrub.oninput=e=>{playing=false;elapsed=+e.target.value;paint(elapsed);document.querySelector('#play').textContent='Replay'};
function tick(now){if(playing){elapsed+=(now-last)*speed;if(elapsed>DATA.clips[selected].duration+700)elapsed=0}last=now;paint(Math.min(elapsed,DATA.clips[selected].duration));requestAnimationFrame(tick)}requestAnimationFrame(tick);
</script></html>`;
fs.mkdirSync(output, {recursive: true});
fs.writeFileSync(path.join(output, 'pvp-medallion-preview.html'), html);
console.log(`Sampled ${data.scene.length} Lua controls into ${path.join(output, 'pvp-medallion-preview.html')}`);
