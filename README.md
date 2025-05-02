# GitHub Action: Setup QEMU-enabled Container

Set up a container that keeps running in the background and available to run following workflow steps in, integrated as closely to Github Actions as possible.

The main advantage over the built-in `container:` functionality is that QEMU-powered containers, that emulate other processor architectures, are available.

Another advantage is that it is possible to mix host steps and container steps throughout your build. A simple example: you can run a "free disk space" action or command on the host before starting the container. AFAIK it is not possible to free host disk space in a regular containerized Actions runner.

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

## Matrix jobs

Combining this Action with https://github.com/SanderVocke/setup-shell-wrapper makes it possible to run matrix jobs where some jobs run within containers and some don't.

```yaml
jobs:
  test:
    strategy:
      matrix:
        job:
           - container: false
             arch: false
           - container: alpine
             arch: arm
    runs-on: ubuntu-latest
    steps:
    - name: Start container
      if: ${{ matrix.job.container }}
      uses: sandervocke/setup-qemu-container@v1
      with:
        container: ${{ matrix.job.container }}
        arch: ${{ matrix.job.arch }}
        initial_delay: 30s

    - name: Setup Shell Wrapper
      uses: sandervocke/setup-shell-wrapper@v1

    - name: Use regular shell   # Only triggered for non-container jobs
      if: ${{ ! matrix.job.container }}
      shell: bash
      run: echo "WRAP_SHELL=bash" >> $GITHUB_ENV

    - name: Use container shell   # Only triggered for container jobs
      if: ${{ matrix.job.container }}
      shell: bash
      run: echo "WRAP_SHELL=run-in-container.sh" >> $GITHUB_ENV

    - name: Print architecture and OS
      shell: wrap-shell {0}
      run: |
        echo "Architecture: $(uname -m)"
        cat /etc/os-release
```

For more examples, see .github/workflows/test.yml for examples on how to use this step.
