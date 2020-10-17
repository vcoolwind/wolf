
local _M = {}

function _M.unauthorized(url,username,reason)
    ngx.log(ngx.INFO, "unauthorized url:", ngx.var.uri)

    ngx.status = 200;
    ngx.header["Content-Type"] = "application/json; charset=utf-8";
    ngx.say(string.format([[ {"ok": false, "username":"%s","reason": "%s"} ]] ,username, reason))
end

return _M