# Setup-Container

(work in progress)

Setup-container is a Github Actions step that starts a container using Podman and makes it available for the rest of the workflow run.
The container can be used by specifying a custom *shell* argument in workflow steps.
The advantage over GHA's built-in *container* support is that a processor architecture can also be specified and QEMU emulation will be used by Podman to emulate said architecture, making compilation/testing for/on different architectures possible in x86 Linux runners.

The downside is that the integration with GHA is limited to shell steps only, meaning many external composite actions will not work. Also, to combine an in-container build with different builds in e.g. a matrix strategy setup, a shell wrapper script is needed to choose between the native shell and the podman redirection shell on the fly.

For now, see .github/workflows/test.yml for examples on how to use this step.
