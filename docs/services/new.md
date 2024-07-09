# Adding New Services

To add a new, unsupported streaming service:

1. Create new configuration file(s) in the `services`/`transformers` directories.
   * Examples: [Twitch App](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/apps/twitch.conf) and [Twitch Transformer](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/transformers/twitch.conf)
2. Add any necessary new environment variables to the `Dockerfile` and `env/relay.env` files. Ensure secrets such as stream keys and usernames are initialized as empty strings.
   * Examples: [Dockerfile](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/Dockerfile#L6-L14) and [env/relay.env](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/env/relay.env#L4-L12)
3. Add the new service/transformer to the `app.conf` file and comment it out.
   * Example: [app.conf](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/app.conf#L19-L26)
4. Add a new shell script within the `scripts/preinit.d` directory to configure and enable the new service on startup. Scripts determine if a service should be enabled, check for errors, configure the service from environment variables, and finally enable the service in app.conf. Scripts are run sequentially in alphanumeric order. Ensure the script is executable.
   * Example: [90_configure_twitch.sh](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/scripts/pre-init.d/90_configure_twitch.sh)
