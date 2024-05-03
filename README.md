# GitHub Action: Setup QEMU-enabled Container

Set up a container that keeps running in the background and available to run following workflow steps in, integrated as closely to Github Actions as possible.

The main advantage over the built-in `container:` functionality is that QEMU-powered containers, that emulate other processor architectures, are available.

The container can be used by any following workflow step which sets the *shell* to `run-in-container.sh {0}`. `$GITHUB_OUTPUT` and `$GITHUB_ENV` are supported inside the container and propagate outside the container. The workspace folder is also mapped into the container so files can be accessed seamlessly.

## Minimal example (Alpine on ARM)

```yaml
runs-on: ubuntu-latest
steps:
    - uses: sandervocke/setup-qemu-container@v1
      with:
        container: alpine
        arch: arm
    - name: Print architecture from within container
      shell: run-in-container.sh {0}
      run: echo "Arch in container: $(uname -m)"
```

For more examples, see .github/workflows/test.yml for examples on how to use this step.
