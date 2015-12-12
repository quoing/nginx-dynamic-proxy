# nginx-dynamic-proxy
Nginx dynamic proxy configuration

Content:
  * nginx/sites-available/reverse-proxy - example openresty configuration
  * nginx/lua/dynamic-route.lua - dynamic routing based on redis entries
   * based on http://bit.ly/1M9GO79
   * Usage:
   ```
     > redis-cli
     > set route:domain.tld 127.0.0.1:1234
     ```
   
   to direct domain.tld to host localhost port 1234
  * nginx/lua/tls-redis.lua - dynamic SSL certificates loading from redis database
   * based on http://bit.ly/1NpeXSv
  * scripts/redis-ssl-keys - load LetsEncypt live certificated to redis database
  * deb/openresty_1.9.3.1-quoing1_amd64.deb - Compiled openresty DEB package for debian/jessie (be sure to review build options, no warranty regarding this build, use at you own risk!)
