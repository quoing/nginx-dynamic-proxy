# nginx-dynamic-proxy
Nginx dynamic proxy configuration

Content:
  * nginx/sites-available/reverse-proxy - example openresty configuration
  * nginx/lua/dynamic-route.lua - dynamic routing based on redis entries
  * nginx/lua/tls-redis.lua - dynamic SSL certificates loading from redis database
  * scripts/redis-ssl-keys - load LetsEncypt live certificated to redis database
