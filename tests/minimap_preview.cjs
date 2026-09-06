// Capture geometry from the real Lua module. This is a diagnostic SVG renderer,
// not an ESO screenshot; sample terrain and font metrics differ from the client.
// node tests/minimap_preview.cjs <output-dir> <fengari-node_modules> <sharp-node_modules> [texture-manifest.json]
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const output = path.resolve(process.argv[2]);
const deps = createRequire(path.resolve(process.argv[3], '../package.json'));
const sharp = createRequire(path.resolve(process.argv[4], '../package.json'))('sharp');
const textures = process.argv[5] ? JSON.parse(fs.readFileSync(process.argv[5], 'utf8')) : {};
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = deps('fengari');
const snapshots = [];
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
lua.lua_pushjsfunction(L, state => { snapshots.push(JSON.parse(to_jsstring(lua.lua_tostring(state, 1)))); return 0; });
lua.lua_setglobal(L, to_luastring('Capture'));
const capture = `
local H = dofile("tests/minimap_harness.lua")
local M, S = H.module, H.settings
local function JSON(value)
    if type(value) == "string" then return string.format("%q", value) end
    if type(value) == "boolean" or type(value) == "number" then return tostring(value) end
    if type(value) ~= "table" then return "null" end
    local result = {}
    if #value > 0 then for _, item in ipairs(value) do result[#result + 1] = JSON(item) end; return "[" .. table.concat(result, ",") .. "]" end
    for key, item in pairs(value) do result[#result + 1] = JSON(key) .. ":" .. JSON(item) end
    return "{" .. table.concat(result, ",") .. "}"
end
for _, shape in ipairs({"circle", "rectangle"}) do
    for _, orientation in ipairs({"north", "rotating"}) do
        S:SetMinimapValue("shape", shape); S:SetMinimapValue("orientation", orientation)
        M:Preview()
        M:UpdateTransform(0.5, 0.5, 0.68, 1)
        M.angle = orientation == "north" and 0 or 0.68
        H.heading = 0.68
        H.now = 0.68 / (math.pi * 2) * 16000
        M:Render(1)
        M.title:SetText("STONEFALLS")
        H:Mouse(0, 0); M:UpdateInteraction()
        local scene = {}
        for _, c in ipairs(H.controls) do
            if c ~= GuiRoot and not c:IsControlHidden() then
                local alpha, parent = c.alpha, c.parent
                while parent do alpha = alpha * parent.alpha; parent = parent.parent end
                scene[#scene + 1] = {
                    id = c.id, kind = c.kind, left = c:GetLeft() - M.root:GetLeft(), top = c:GetTop() - M.root:GetTop(),
                    w = c:GetWidth(), h = c:GetHeight(), alpha = alpha, rotation = c.rotation,
                    textureRotation = c.textureRotation or 0, textureOrigin = c.textureOrigin,
                    points = c.points, smoothing = c.smoothing, fill = c.fillColor,
                    border = c.border, borderColor = c.borderColor, color = c.color,
                    text = c.text, font = c.font, texture = c.texture, level = c.level or 0, tier = c.tier, layer = c.layer,
                    circleClip = c.circleClip and { c.circleClip[1] - M.root:GetLeft(), c.circleClip[2] - M.root:GetTop(), c.circleClip[3] },
                    rectClip = c.rectClip and { c.rectClip[1] - M.root:GetLeft(), c.rectClip[2] - M.root:GetTop(),
                        c.rectClip[3] - M.root:GetLeft(), c.rectClip[4] - M.root:GetTop() },
                }
            end
        end
        Capture(JSON({ shape = shape, orientation = orientation, width = M.width, height = M.height,
            rootWidth = M.root:GetWidth(), rootHeight = M.root:GetHeight(), scene = scene }))
    end
end
`;
if (lauxlib.luaL_dostring(L, to_luastring(capture)) !== lua.LUA_OK) throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
fs.mkdirSync(output, { recursive: true });
const escape = s => String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;' }[c]));
const rgb = c => c ? `rgb(${c.slice(0, 3).map(v => Math.round(v * 255)).join(',')})` : 'none';
const opacity = c => c && c.length > 3 ? c[3] : 1;
const terrain = `<rect width="1024" height="1024" fill="#3a4649"/>
<path d="M70 0H1024V1024H120Q240 880 190 750T310 550Q100 460 245 300T70 0" fill="#6e7560"/>
<path d="M260 0Q570 150 470 310T610 540Q740 720 560 1024" fill="none" stroke="#414d50" stroke-width="58"/>
<path d="M390 0Q320 270 480 400T760 500Q850 700 790 1024M180 690Q410 550 510 520T960 380" fill="none" stroke="#aaa186" stroke-width="9"/>
<path d="M500 0Q470 190 710 225T860 370M300 650Q460 810 380 1024" fill="none" stroke="#bab196" stroke-width="4"/>
${Array.from({ length: 85 }, (_, i) => { const x = 170 + (i * 131) % 800, y = (i * 97) % 1000; return `<ellipse cx="${x}" cy="${y}" rx="${12 + i % 16}" ry="${6 + i % 12}" fill="${i % 2 ? '#596651' : '#858574'}" opacity=".65"/>`; }).join('')}
<g fill="#b2af95" stroke="#515951" stroke-width="2"><path d="M560 440h28v18h-28zM596 454h20v31h-20zM555 488h36v22h-36zM600 504h31v22h-31zM525 464h18v22h-18z"/></g>`;
function imageUri(svg) { return 'data:image/svg+xml;base64,' + Buffer.from(svg).toString('base64'); }
function textureUri(name) {
    const native = textures[name.toLowerCase()];
    if (native) return native;
    const tile = /map-\d+-(\d+)\.dds/.exec(name);
    if (tile) {
        const i = Number(tile[1]) - 1;
        return imageUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="${i % 2 * 512} ${Math.floor(i / 2) * 512} 512 512">${terrain}</svg>`);
    }
    const icon = /quest/.test(name) ? '<path d="M12 1l8 7-8 15L4 8z"/>' : '<circle cx="12" cy="12" r="7"/>';
    return imageUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><g fill="#f3f0d6" stroke="#293236" stroke-width="1">${icon}</g></svg>`);
}
function render(snapshot, idx) {
    const parts = [];
    const tiers = { DT_LOW: 0, DT_MEDIUM: 1, DT_HIGH: 2 };
    const layers = { DL_BACKGROUND: 0, DL_CONTROLS: 1, DL_OVERLAY: 2, DL_TEXT: 3 };
    for (const c of snapshot.scene.sort((a, b) => (tiers[a.tier] ?? 1) - (tiers[b.tier] ?? 1)
        || (layers[a.layer] ?? 1) - (layers[b.layer] ?? 1) || a.level - b.level || a.id - b.id)) {
        const cx = c.left + c.w / 2, cy = c.top + c.h / 2;
        if (c.rotation) throw new Error('Control transforms require native clip-space verification');
        let body = '';
        if (c.kind === 'CT_POLYGON' && Array.isArray(c.points) && c.points.length) {
            if (c.smoothing && c.points.length <= 4) {
                throw new Error('Native smoothing reshapes sparse polygons; a straight SVG polygon cannot validate this contour');
            }
            const points = c.points.map(p => `${c.left + p[0] * c.w},${c.top + p[1] * c.h}`).join(' ');
            body = `<polygon points="${points}" fill="${rgb(c.fill)}" fill-opacity="${opacity(c.fill)}" stroke="${c.border ? rgb(c.borderColor) : 'none'}" stroke-opacity="${opacity(c.borderColor)}" stroke-width="${c.border || 0}"/>`;
        } else if (c.kind === 'CT_TEXTURE' && c.texture) {
            const pivotX = c.left + (c.textureOrigin?.[0] ?? 0.5) * c.w;
            const pivotY = c.top + (c.textureOrigin?.[1] ?? 0.5) * c.h;
            body = `<image x="${c.left}" y="${c.top}" width="${c.w}" height="${c.h}" href="${textureUri(c.texture)}" transform="rotate(${-c.textureRotation * 180 / Math.PI},${pivotX},${pivotY})"/>`;
        } else if (c.kind === 'CT_LABEL' && c.text) {
            const size = Number((c.font || '').split('|')[1]) || 14;
            body = `<text x="${cx}" y="${cy}" fill="${rgb(c.color)}" font-family="Arial" font-weight="600" font-size="${size}" text-anchor="middle" dominant-baseline="central">${escape(c.text)}</text>`;
        }
        if (body) {
            // Capture the actual per-control mask, rather than substituting an
            // ideal frame-shaped clip that hides stale/misplaced coordinates.
            const clipId = `clip${idx}-${c.id}`;
            let clip = '';
            if (c.circleClip) {
                const [x, y, radius] = c.circleClip;
                clip = `<circle cx="${x}" cy="${y}" r="${radius}"/>`;
            } else if (c.rectClip) {
                const [left, top, right, bottom] = c.rectClip;
                clip = `<rect x="${left}" y="${top}" width="${right - left}" height="${bottom - top}"/>`;
            }
            if (clip) parts.push(`<defs><clipPath id="${clipId}" clipPathUnits="userSpaceOnUse">${clip}</clipPath></defs>`);
            parts.push(`<g opacity="${c.alpha}" ${clip ? `clip-path="url(#${clipId})"` : ''}>${body}</g>`);
        }
    }
    return parts.join('');
}
const columns = 2, panelW = 450, panelH = 430;
const panels = snapshots.map((s, i) => {
    const x = 30 + i % columns * panelW, y = 120 + Math.floor(i / columns) * panelH;
    return `<g transform="translate(${x},${y})"><text x="${panelW / 2}" y="0" text-anchor="middle" fill="#a6b7c1" font-size="13" letter-spacing="2">${s.shape.toUpperCase()} · ${s.orientation === 'north' ? 'NORTH UP' : 'ROTATING'}</text><g transform="translate(${(panelW - s.rootWidth) / 2},22)">${render(s, i)}</g></g>`;
}).join('');
const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="1030" viewBox="0 0 960 1030"><rect width="960" height="1030" fill="#0f171d"/><text x="480" y="48" fill="#e0e7e8" font-family="Arial" font-size="24" text-anchor="middle" letter-spacing="4">NIRNSTEEL / MINIMAP</text><text x="480" y="78" fill="#869ba7" font-family="Arial" font-size="13" text-anchor="middle">Steel frame · silver edging · gold north marker</text>${panels}<text x="480" y="995" fill="#7b909d" font-family="Arial" font-size="12" text-anchor="middle">Diagnostic capture of Lua controls · sample terrain · ESO fonts and clipping require client verification</text></svg>`;
fs.writeFileSync(path.join(output, 'minimap-preview.svg'), svg);
fs.writeFileSync(path.join(output, 'minimap-scenes.json'), JSON.stringify(snapshots, null, 2));
sharp(Buffer.from(svg)).png().toFile(path.join(output, 'minimap-preview.png')).then(() => console.log(path.join(output, 'minimap-preview.png'))).catch(e => { console.error(e); process.exitCode = 1; });
