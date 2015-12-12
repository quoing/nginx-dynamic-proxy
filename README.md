# nginx-dynamic-proxy
Nginx dynamic proxy configuration

Content:
  * nginx/sites-available/reverse-proxy - example openresty configuration
  * nginx/lua/dynamic-route.lua - dynamic routing based on redis entries
   * based on http://bit.ly/1M9GO79
  * nginx/lua/tls-redis.lua - dynamic SSL certificates loading from redis database
   * based on http://bit.ly/1NpeXSv
  * scripts/redis-ssl-keys - load LetsEncypt live certificated to redis database
