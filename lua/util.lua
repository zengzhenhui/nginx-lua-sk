local cjson = require "cjson.safe"

local Util = {}

local function explode(_str, seperator)
    local pos, arr = 0, {}
    for st, sp in function() return string.find(_str, seperator, pos, true) end do
        table.insert(arr, string.sub(_str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(_str, pos))
    return arr
end

local function table_nums( t )
    local count = 0
    for k, v in pairs( t ) do
        count = count + 1
    end
    return count
end

-- 提取请求参数
function Util.log()
    local post_args = {}
    local content_type = ngx.req.get_headers()["content-type"]
    if content_type and string.sub(content_type, 1, 20) == "multipart/form-data;" then
        local body_data = ngx.req.get_body_data()
        local boundary = "--" .. string.sub(content_type, 31)
        local body_data_table = explode(tostring(body_data), boundary)
        local first_string = table.remove(body_data_table, 1)
        local last_string = table.remove(body_data_table)
        for i, v in ipairs(body_data_table) do
            local start_pos, end_pos, capture, capture2 = string.find(v, 'Content%-Disposition: form%-data; name="(.+)"; filename="(.*)"')
            if not start_pos then --普通参数
            local t = explode(v, "\r\n\r\n")
            local temp_param_name = string.sub(t[1], 41, -2)
            local temp_param_value = string.sub(t[2], 1, -3)
            post_args[temp_param_name] = temp_param_value
            else --文件类型的参数，capture是参数名称，capture2是文件名
            --文件内容就不要了
            end
        end
    else
        post_args = ngx.req.get_post_args()
    end
    if table_nums(post_args) > 0 then
      ngx.var.req_body = cjson.encode(post_args)
    end
end

-- 提取上游服务响应内容
function Util.body_filter()
    local response_body = ngx.arg[1]
    if string.sub(response_body, -1) == "\n" then
        response_body = string.sub(response_body, 1, -2)
    end
    ngx.ctx.buffered = (ngx.ctx.buffered or "") .. response_body
    if ngx.arg[2] and cjson.decode(ngx.ctx.buffered) then
        ngx.var.response_body = ngx.ctx.buffered
    end
end

return Util
