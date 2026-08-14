# Termux compatibility analysis

DeepSeek Harness is treated as an Ubuntu/proot workload in this integration. The service-manager daemon still runs natively in Termux and owns the lifecycle of the guest process.

## Why Ubuntu/proot is required

Termux is Linux userspace on Android, but it is not a conventional GNU/Linux distribution. Native Termux programs use Android's Bionic C library and `/system/bin/linker64`. DeepSeek Harness installs multiple native modules distributed for GNU/Linux ARM64 and linked against glibc.

Observed runtime dependencies include:

- `node-pty`
- `@rolldown/binding-linux-arm64-gnu`
- `@oxc-parser/binding-linux-arm64-gnu`
- `@oxc-resolver/binding-linux-arm64-gnu`
- `@oxlint/binding-linux-arm64-gnu`
- `@rollup/rollup-linux-arm64-gnu`
- `lightningcss-linux-arm64-gnu`
- `@img/sharp-linux-arm64`
- `node-addon-require-builtin-linux-arm64-gnu`

Their ELF dependencies include GNU names such as `libc.so.6`, `libstdc++.so.6`, `libgcc_s.so.1`, and `ld-linux-aarch64.so.1`. Termux provides Bionic `libc.so`, LLVM `libc++_shared.so`, and the Android linker instead. Renaming libraries or changing `LD_LIBRARY_PATH` does not make these ABIs compatible.

## Sandbox limitations on Android

The local dsh sandbox selects `bwrap` and then Landlock on Linux.

- Android normally does not expose unprivileged user namespaces required by `bwrap`.
- The Android seccomp policy can reject Landlock syscalls with `SIGSYS` even when the kernel version is otherwise recent enough.
- dsh intentionally fails closed when no confinement backend is usable.

A native Termux port would therefore need a deliberate Android sandbox policy, not only rebuilt native modules.

## What a native Termux port would require

A proper port is possible in principle, but it is a separate engineering project:

1. Build every required Node native addon against Bionic.
2. Add Android package selection instead of resolving `linux-arm64-gnu` artifacts.
3. Build and test `node-pty` with Termux clang, Bionic `pty.h`, and `libutil`.
4. Replace or port `sharp`/libvips for Android.
5. Add an Android-aware sandbox backend or an explicit, clearly surfaced no-sandbox mode.
6. Replace GNU/Linux-only development binaries used by the build pipeline.
7. Add Android/Termux CI and test process-tree, PTY, signals, filesystem permissions, and shutdown behavior.

Using Ubuntu/proot preserves the upstream glibc runtime and limits this repository to integration rather than maintaining a downstream platform port.

## Performance and security trade-offs

proot adds syscall and path-translation overhead. It is appropriate for a local web service and agent workload, but process-heavy operations will be slower than native execution. The service binds only to `127.0.0.1`; remote exposure should be handled by a separately authenticated proxy rather than changing the dsh bind address.
