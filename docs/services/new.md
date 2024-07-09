# Adding New Services

To add a new, unsupported streaming service:

1. Create a new configuration file(s) in the `services`/`transformers` directories.
2. Add any necessary environment variables to the `Dockerfile` and `env/relay.env` files.
3. Add the service/transformer to the `app.conf` file and comment it out.
4. Add a script within the `scripts/preinit.d` directory to configure and enable the service. See an [existing script](../../build/scripts/pre-init.d/90_configure_twitch.sh) for examples.