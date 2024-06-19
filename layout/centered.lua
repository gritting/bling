local awful = require("awful")
local math = math

local mylayout = {}
local capi =
{
    mouse = mouse,
    mousegrabber = mousegrabber,
}

mylayout.name = "centered"

function mylayout.mouse_resize_handler(_, _, _, _)
    local c = awful.client.getmaster()
    local area = c.screen.workarea
    local client_count = #c.screen.tiled_clients
    local master_area_width = area.width * c.screen.selected_tag.master_width_factor
    local slave_width = 0.5 * (area.width - master_area_width)

    if client_count > 2 then
        if  capi.mouse.coords().x > area.x + area.width/2 then
            capi.mouse.coords({x = area.x + slave_width + master_area_width, y = c.y + c.height/2})
        else
            capi.mouse.coords({x = area.x + slave_width, y = c.y + c.height/2})
        end
    elseif client_count == 2 then
        capi.mouse.coords({x = area.x + master_area_width, y = c.y + c.height/2})
    else
        capi.mouse.coords({x = c.x + c.width/2, y = c.y + c.height/2})
    end

    capi.mousegrabber.run(function (_mouse)
        if not c.valid then return false end
        local fact_x = c.screen.selected_tag.master_width_factor

        for _, v in ipairs(_mouse.buttons) do
            if v then
                if client_count > 2 then
                    if _mouse.x > area.x + area.width/2 then
                        fact_x = (((_mouse.x - area.x) / area.width)*1.333)-0.5
                    else
                        fact_x = ((( area.x + area.width - _mouse.x) / area.width)*1.333)-0.5
                    end
                elseif client_count == 2 then
                    fact_x = (_mouse.x - area.x) / area.width
                else
                    return false
                end
                c.screen.selected_tag.master_width_factor = math.min(math.max(fact_x, 0.30), 0.75)
                return true
            end
        end
        return false
    end, "sb_h_double_arrow")
end

function mylayout.arrange(p)
    local area = p.workarea
    local t = p.tag or screen[p.screen].selected_tag
    local nmaster = math.min(t.master_count, #p.clients)
    local nslaves = #p.clients - nmaster

    local master_area_width = area.width * t.master_width_factor
    if t.master_count == 0 then master_area_width = 0 end
    local slave_width = 0.5 * (area.width - master_area_width)
    local master_area_x = area.x + slave_width

    -- Special case: few slaves -> make masters take more space - unless requested otherwise!
    if nslaves < 2 and t.master_fill_policy ~= "master_width_factor" and
        t.centered_layout_master_fill_policy ~= "master_width_factor" then
        master_area_x = area.x

        if nslaves == 1 then
            slave_width = area.width - master_area_width
        else
            master_area_width = area.width
        end
    end


    -- iterate through masters
    for idx = 1, nmaster do
        local c = p.clients[idx]
        local g
        g = {
            x = master_area_x,
            y = area.y + (nmaster - idx) * (area.height / nmaster),
            width = master_area_width,
            height = area.height / nmaster,
        }
        p.geometries[c] = g
    end


    -- iterate through slaves
    local number_of_left_sided_slaves = math.floor(nslaves / 2)
    local number_of_right_sided_slaves = nslaves - number_of_left_sided_slaves
    local left_iterator = 0
    local right_iterator = 0

    for idx = 1, nslaves do
        local c = p.clients[idx + nmaster]
        local g
        if idx % 2 == 0 then
            g = {
                x = area.x,
                y = area.y
                    + left_iterator
                        * (area.height / number_of_left_sided_slaves),
                width = slave_width,
                height = area.height / number_of_left_sided_slaves,
            }
            left_iterator = left_iterator + 1
        else
            g = {
                x = master_area_x + master_area_width,
                y = area.y
                    + right_iterator
                        * (area.height / number_of_right_sided_slaves),
                width = slave_width,
                height = area.height / number_of_right_sided_slaves,
            }
            right_iterator = right_iterator + 1
        end
        p.geometries[c] = g
    end
end

return mylayout
