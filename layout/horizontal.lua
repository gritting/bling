local math = math
local client = require("awful.client")
local mylayout = {}
local capi =
{
    mouse = mouse,
    mousegrabber = mousegrabber,
}

mylayout.name = "horizontal"

function mylayout.mouse_resize_handler(c, _, x, y)
    local fixed_y = c.maximized_vertical
    if not c or fixed_y then return false end

    local fact_y = c.screen.selected_tag.master_width_factor
    local area = c.screen.workarea
    capi.mouse.coords({x = area.x + area.width/2, y = area.y + (area.height*fact_y)})
    capi.mousegrabber.run(function (_mouse)
        for _, v in ipairs(_mouse.buttons) do
            if v then
                local geom = client.getmaster():geometry()
                fact_y = math.min(math.max((_mouse.y - geom.y) / area.height, 0.10), 0.85)
                c.screen.selected_tag.master_width_factor = fact_y
                return true
            end
        end
        return false
    end, "sb_v_double_arrow")
end

function mylayout.arrange(p)
    local area = p.workarea
    local t = p.tag or screen[p.screen].selected_tag
    local mwfact = t.master_width_factor
    local nmaster = math.min(t.master_count, #p.clients)
    local nslaves = #p.clients - nmaster

    local master_area_height = area.height * mwfact
    local slave_area_height = area.height - master_area_height

    -- Special case: no slaves
    if nslaves == 0 then
        master_area_height = area.height
        slave_area_height = 0
    end

    -- Special case: no masters
    if nmaster == 0 then
        master_area_height = 0
        slave_area_height = area.height
    end

    -- iterate through masters
    for idx = 1, nmaster do
        local c = p.clients[idx]
        local g = {
            x = area.x + (idx - 1) * (area.width / nmaster),
            y = area.y,
            width = area.width / nmaster,
            height = master_area_height,
        }
        p.geometries[c] = g
    end

    -- iterate through slaves
    for idx = 1, nslaves do
        local c = p.clients[idx + nmaster]
        local g = {
            x = area.x,
            y = area.y
                + master_area_height
                + (idx - 1) * (slave_area_height / nslaves),
            width = area.width,
            height = slave_area_height / nslaves,
        }
        p.geometries[c] = g
    end
end

return mylayout
