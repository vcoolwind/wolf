
local _M = {}

function _M.unauthorized(url,username,reason)
    ngx.log(ngx.INFO, "unauthorized url:", ngx.var.uri)

    ngx.status = 200;
    ngx.header["Content-Type"] = "application/json; charset=utf-8";
    ngx.say(string.format([[ {"respCode": "40001","respMsg": "您没有操作的权限","bizCode": null,"bizMsg": null,"respData": null,"url": "%s","username": "%s","reason": "%s"} ]], url, username, reason))
    ngx.flush(true)
    ngx.exit(ngx.HTTP_OK)
end

return _M

