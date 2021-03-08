-- parse system env MULTI_SERVERS as json format
-- generate nginx server config
--[[
## the env MULTI_SERVERS eg:
{
    "SERVERS": [
        {
            "AGENT_PORT": "10081",
            "SERVER_NAME": "www.web1.com",
            "EXTENSION_CONFIG": "",
            "RBAC_SERVER_URL": "http://wolf-server:10080",
            "LOACTIONS": [
                {
                    "PATH": "/",
                    "BACKEND_UPSTREAM": "http://myapp1:8000",
                    "RBAC_APP_ID": "App-web1",
                    "UNAUTH_DIRECT": "true"
                },
                {
                    "PATH": "/abc",
                    "BACKEND_UPSTREAM": "http://myapp2:8000",
                    "RBAC_APP_ID": "App-web2",
                    "UNAUTH_DIRECT": "true"
                }
            ]
        },
        {
            "AGENT_PORT": "10082",
            "SERVER_NAME": "www.web2.com",
            "EXTENSION_CONFIG": "",
            "RBAC_SERVER_URL": "http://wolf-server:10080",
            "LOACTIONS": [
                {
                    "PATH": "/",
                    "BACKEND_UPSTREAM": "http://myapp3:8000",
                    "RBAC_APP_ID": "App-web3",
                    "UNAUTH_DIRECT": "true"
                },
                {
                    "PATH": "/api",
                    "BACKEND_UPSTREAM": "http://myapp4:8000",
                    "RBAC_APP_ID": "App-web4",
                    "UNAUTH_DIRECT": "true"
                }
            ]
        }
    ]
}
--]]

json = require "cjson"

local function isNotEmpty(s)
    return s ~= nil and s ~= '' and s ~= '\n' and s ~= '\t'
end

local function getValue(...)
    local arg={...}
    print("getValue---",unpack(arg))
    for i,v in pairs(arg) do
        print(i,v)
        if(isNotEmpty(v))
        then
            return v
        end
    end
    return ""
end

-- 结合模板conf/server-location-norbac-tmpl.conf和conf/server-location-tmpl.conf ，使用变量替换生成 nginx的location内容
-- 当RBAC_APP_ID不设置或设置为NotSet，则默认生成放行的策略。
local function genLocationContent(PATH,BACKEND_UPSTREAM,RBAC_APP_ID,UNAUTH_DIRECT)
    print("genLocationContent...",PATH,BACKEND_UPSTREAM,RBAC_APP_ID,UNAUTH_DIRECT)
    if(RBAC_APP_ID=="NotSet") then
        local file1=io.input("conf/server-location-norbac-tmpl.conf")
    else
        local file1=io.input("conf/server-location-tmpl.conf")
    end

    local locationContent=io.read("*a")
    locationContent=string.gsub(locationContent, "{PATH}", PATH)
    locationContent=string.gsub(locationContent, "{BACKEND_UPSTREAM}", BACKEND_UPSTREAM)
    locationContent=string.gsub(locationContent, "{RBAC_APP_ID}", RBAC_APP_ID)
    locationContent=string.gsub(locationContent, "{UNAUTH_DIRECT}", UNAUTH_DIRECT)
    return locationContent
end

-- 结合模板conf/server-tmpl.conf ，使用变量替换生成 nginx的server内容
local function genServerContent(AGENT_PORT,SERVER_NAME,EXTENSION_CONFIG,RBAC_SERVER_URL,LOCATION_CONFIG)
    print("genServerContent...",AGENT_PORT,SERVER_NAME,EXTENSION_CONFIG,RBAC_SERVER_URL)
    local file1=io.input("conf/server-tmpl.conf")
    local serverContent=io.read("*a")
    serverContent=string.gsub(serverContent, "{AGENT_PORT}", AGENT_PORT)
    serverContent=string.gsub(serverContent, "{SERVER_NAME}", SERVER_NAME)
    serverContent=string.gsub(serverContent, "{EXTENSION_CONFIG}", EXTENSION_CONFIG)
    serverContent=string.gsub(serverContent, "{RBAC_SERVER_URL}", RBAC_SERVER_URL)
    serverContent=string.gsub(serverContent, "{LOCATION_CONFIG}", LOCATION_CONFIG)
    return serverContent
end

-- 通过环境变量 MULTI_SERVERS的json内容，循环生成多个SERVER配置文件
-- 每个server配置文件的localtion通过json总得LOACTIONS配置替换生成
multiServersJson=getValue(os.getenv("MULTI_SERVERS"),"{\"SERVERS\": [{}]}")

print("MULTI_SERVERS is -->[" .. multiServersJson .. "]",os.getenv("MULTI_SERVERS"))

multiServers=json.decode(multiServersJson)

serverPos=1
while( true )
do
    locationContents=""
    server=multiServers["SERVERS"][serverPos]
    if (server ~= nil)
    then
        AGENT_PORT=getValue(server["AGENT_PORT"],os.getenv("AGENT_PORT"),"10082")
        SERVER_NAME=getValue(server["SERVER_NAME"],os.getenv("SERVER_NAME"),"localhost")
        EXTENSION_CONFIG=getValue(server["EXTENSION_CONFIG"],os.getenv("EXTENSION_CONFIG"),"#EXTENSION_CONFIG")
        RBAC_SERVER_URL=getValue(server["RBAC_SERVER_URL"],os.getenv("RBAC_SERVER_URL"),"http://127.0.0.1:10080")

        LOACTIONS=server["LOACTIONS"]
        if(LOACTIONS==nil or LOACTIONS[1]==nil)
        then
            -- with default location
            PATH="/"
            BACKEND_UPSTREAM=getValue(os.getenv("BACKEND_UPSTREAM"),"http://127.0.0.1:10080")
            RBAC_APP_ID=getValue(os.getenv("RBAC_APP_ID"),"NotSet")
            UNAUTH_DIRECT=getValue(os.getenv("UNAUTH_DIRECT"),"false")
            locationContent = genLocationContent(PATH,BACKEND_UPSTREAM,RBAC_APP_ID,UNAUTH_DIRECT)
            locationContents = locationContents .. locationContent
        else
            locationPos=1
            while(true)
            do
                LOACTION=LOACTIONS[locationPos]
                if(LOACTION ~= nil)
                then
                    PATH=getValue(LOACTION["PATH"],"/")
                    BACKEND_UPSTREAM=getValue(LOACTION["BACKEND_UPSTREAM"],os.getenv("BACKEND_UPSTREAM"),"http://127.0.0.1:10080")
                    RBAC_APP_ID=getValue(LOACTION["RBAC_APP_ID"],os.getenv("RBAC_APP_ID"),"NotSet")
                    UNAUTH_DIRECT=getValue(LOACTION["UNAUTH_DIRECT"],os.getenv("UNAUTH_DIRECT"),"false")
                    locationContent = genLocationContent(PATH,BACKEND_UPSTREAM,RBAC_APP_ID,UNAUTH_DIRECT)
                    locationContents = locationContents .. locationContent
                    locationPos=locationPos+1
                else
                    break
                end
            end
        end

        LOCATION_CONFIG=getValue(locationContents,"#LOCATION_CONFIG")
        serverContent=genServerContent(AGENT_PORT,SERVER_NAME,EXTENSION_CONFIG,RBAC_SERVER_URL,LOCATION_CONFIG)

        configFile="/etc/nginx/conf.d/app-server-" .. tostring(serverPos) .. ".conf"
        local serverFile=io.output(configFile)
        io.write(serverContent)
        io.flush()
        io.close()
        print("save config file to:",configFile)
        serverPos=serverPos+1
    else
        break
    end
end
