# Setup-Virtual-Container

(wip)

The plan is to combine setup-alpine with podman to be able to run entire Github Actions workflows on containers running through QEMU user-space emulation.
This would allow e.g. arm builds on x86 Linux runners, without having to rewrite every command in the entire Actions workflow pipeline.

The only requisite would be to use a custom shell for "run:" blocks.
