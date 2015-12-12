local route_cache = ngx.shared.route_cache
local route_cache_duration = 1800 -- 30 minutes

local log = ngx.log
local exit = ngx.exit
local null = ngx.null
local ERR = ngx.ERR
local INFO = ngx.INFO
local DEBUG = ngx.DEBUG
local HTTP_INTERNAL_SERVER_ERROR = ngx.HTTP_INTERNAL_SERVER_ERROR
local HTTP_NOT_FOUND = ngx.HTTP_NOT_FOUND
local redis_host = "127.0.0.1"
local redis_port = "6379"
local redis_auth = ""         -- keep empty to skip authentication

-- try cached route first
local routesource = 0

local route = route_cache:get(ngx.var.http_host)
if route == nil then
        -- Setup Redis connection
        local redis = require "resty.redis"
        local red = redis:new()

        local ok, err = red:connect(redis_host, redis_port)
        if not ok then
            log(ERR, "REDIS: Failed to connect to redis: ", err)
            return exit(HTTP_INTERNAL_SERVER_ERROR)
        end
        -- Authenticate redis
	if redis_auth ~= "" then
		local res, err = red:auth(redis_auth)
		if not res then
			log(ERR, "failed to authenticate: ", err)
			return exit(HTTP_INTERNAL_SERVER_ERROR)
		end
	end
        -- fetch route from redis
        route = red:get("route:" .. ngx.var.http_host)
        if route ~= null then
                routesource = 2         -- source is redis
        else
                route = nil
        end
else
        routesource = 1         -- source is cache
end

-- route not in cache and not in redis, try to set default else error
if route == nil then
        if ngx.var.upstream ~= "" then
                routesource = 3         --source is default
        else
                exit(HTTP_NOT_FOUND)
        end
end
-- log(ERR, "myDEBUG: ", route, "rs: ", routesource)
-- save to cache
if routesource > 1 then
        local success, err, forcible = route_cache:set(ngx.var.http_host, route, route_cache_duration)
        log(DEBUG, "Caching Result: ", success, " Err: ",  err)
end
-- set upstream variable
if routesource < 3 then
        ngx.var.upstream = tostring(route)
end

