# Setup-Container

Set up a container that keeps running in the background and available to run following workflow steps in, integrated as closely to Github Actions as possible.

The main advantage over the built-in *container:* functionality is that QEMU-powered containers, that emulate other processor architectures, are available.

The container can be used by any following workflow step which sets the *shell* to `run-in-container.sh {0}`. `$GITHUB_OUTPUT` and `$GITHUB_ENV` are supported inside the container and propagate outside the container. The workspace folder is also mapped into the container so files can be accessed seamlessly.

For now, see .github/workflows/test.yml for examples on how to use this step.
