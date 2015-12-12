local log = ngx.log
local exit = ngx.exit
local null = ngx.null
local ERR = ngx.ERR
local INFO = ngx.INFO
local DEBUG = ngx.DEBUG
local HTTP_INTERNAL_SERVER_ERROR = ngx.HTTP_INTERNAL_SERVER_ERROR


-- Setup TLS related.
local ssl = require "ngx.ssl"
local server_name = ssl.server_name()
local addr, addrtyp, err = ssl.raw_server_addr()
local byte = string.byte
local key, cert
local redis_host = "127.0.0.1"
local redis_port = "6379"
local redis_auth = ""		-- keep empty to skip authentication

-- Local cache related
local cert_cache = ngx.shared.cert_cache
local cert_cache_duration = 1800 -- 30 minutes

ssl.clear_certs()

-- Check for SNI request - if we don't have the server name, attempt to use the IP address instead.
if server_name == nil then
    log(INFO, "SNI Not present - performing IP lookup")

    -- Set server name as IP address.
    server_name = string.format("%d.%d.%d.%d", byte(addr, 1), byte(addr, 2), byte(addr, 3), byte(addr, 4))
    log(INFO, "IP Address: ", server_name)
end

-- Check cache for certficate
key  = cert_cache:get(server_name .. "_k")
cert = cert_cache:get(server_name .. "_c")

if key ~= nil and cert ~= nil then
    log(DEBUG, "Cert cache HIT for: ", server_name)
else
    -- load redis stuff and connect
        -- Setup Redis connection
        local redis = require "resty.redis"
        local red = redis:new()

        local ok, err = red:connect(redis_host, redis_port)
        if not ok then
            log(ERR, "REDIS: Failed to connect to redis: ", err)
            return exit(HTTP_INTERNAL_SERVER_ERROR)
        end

        -- Authenticate
	if redis_auth ~= "" then
	        local res, err = red:auth(redis_auth)		-- see /etc/redis/redis.conf for details about authentication
        	    if not res then
                	ngx.say("failed to authenticate: ", err)
	                return	
	        end
	end


    log(DEBUG, "Cert cache MISS for: ", server_name)

    -- If the cert isn't in the cache, attept to retrieve from Redis
    -- local domain, err = red:hmget("domain:" .. server_name, "key", "cert")
    local certserial, err = red:get("domain:" .. server_name)

    if certserial == null then
        log(ERR, "failed to retreive certificate serial for domain: ", server_name, " Err: ", err)
        return
    end

    local domain, err = red:hmget(certserial, "key", "cert")

    if domain[1] == null then
        log(ERR, "failed to retreive certificates for domain: ", server_name, " Err: ", err)
        return
    end

    key = domain[1]
    cert = domain[2]

    -- If we've retrieved the cert and key, attempt to cache
    if key ~= nil and cert ~= nil then

        -- Add key and cert to the cache
        local success, err, forcible = cert_cache:set(server_name .. "_k", key, cert_cache_duration)
        log(DEBUG, "Caching Result: ", success, " Err: ",  err)

        success, err, forcible = cert_cache:set(server_name .. "_c", cert, cert_cache_duration)
        log(DEBUG, "Caching Result: ", success, " Err: ",  err)

        log(DEBUG, "Cert and key retrieved and cached for: ", server_name)

    else
        log(ERR, "Failed to retrieve " .. (key and "" or "key ") .. (cert and "" or "cert "), "for ", server_name)
        return
    end
end

-- Set cert
local ok, err = ssl.set_der_cert(cert)
if not ok then
    log(ERR, "failed to set DER cert: ", err)
    return
end

-- Set key
local ok, err = ssl.set_der_priv_key(key)
if not ok then
    log(ERR, "failed to set DER key: ", err)
    return
end

