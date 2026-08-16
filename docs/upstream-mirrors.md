# DeepSeek Harness upstream mirrors

Last verified: 2026-08-16

This integration treats the DeepSeek GitHub repository as the authoritative source. Mirrors are useful for browsing or cloning when GitHub connectivity is limited, but they are not release authorities.

## Authoritative upstream

Repository:

```text
https://github.com/deepseek-ai/deepseek-harness
```

Clone URL:

```bash
git clone https://github.com/deepseek-ai/deepseek-harness.git
```

The upstream default branch is `master`. GitHub reports no configured `mirror_url`, so DeepSeek does not currently declare another repository as an official mirror.

## Confirmed third-party mirrors

### GitCode

Browser:

```text
https://gitcode.com/gh_mirrors/de/deepseek-harness
```

Clone:

```bash
git clone https://gitcode.com/gh_mirrors/de/deepseek-harness.git
```

The shorter path below currently redirects to the `gh_mirrors` repository:

```text
https://gitcode.com/deepseek-ai/deepseek-harness
```

### AtomGit

Browser:

```text
https://atomgit.com/gh_mirrors/de/deepseek-harness
```

Clone:

```bash
git clone https://atomgit.com/gh_mirrors/de/deepseek-harness.git
```

The shorter path below currently redirects to the `gh_mirrors` repository:

```text
https://atomgit.com/deepseek-ai/deepseek-harness
```

GitCode and AtomGit returned the same repository page and refs during verification. They appear to use related mirror infrastructure and should not be treated as two independent backups.

## Verification result

At the time shown above, `refs/heads/master` resolved to the same commit on all three endpoints:

```text
47f943859bef60e4160492346772ded9b24f765a
```

Verify synchronization before using a mirror for a build:

```bash
for remote in \
  https://github.com/deepseek-ai/deepseek-harness.git \
  https://gitcode.com/gh_mirrors/de/deepseek-harness.git \
  https://atomgit.com/gh_mirrors/de/deepseek-harness.git
do
  printf '%s\n' "$remote"
  git ls-remote "$remote" refs/heads/master
done
```

For reproducible builds, clone from any reachable endpoint and then check out an approved commit explicitly:

```bash
git clone https://gitcode.com/gh_mirrors/de/deepseek-harness.git
cd deepseek-harness
git checkout --detach 47f943859bef60e4160492346772ded9b24f765a
```

Do not build directly from a moving `master` branch without recording the resulting commit.

## Platforms without a confirmed repository

The following same-name repository paths returned 404 through their public APIs during verification:

- Gitee: `gitee.com/deepseek-ai/deepseek-harness`
- GitLab: `gitlab.com/deepseek-ai/deepseek-harness`
- Codeberg: `codeberg.org/deepseek-ai/deepseek-harness`

Gitee hosts a `deepseek-ai` namespace with mirrors of some DeepSeek repositories, but no DeepSeek Harness repository was found there at verification time.

## Download proxies are not mirrors

Services such as GitHub release proxies, archive accelerators, and generic clone proxies may relay GitHub content without maintaining a browsable repository or independent Git history. Their availability and integrity guarantees vary. This repository does not list an unverified proxy as an upstream mirror.

## Supply-chain policy

When preparing an OpenHouse or WuxianPi release:

1. Resolve the approved commit from the authoritative GitHub repository when possible.
2. Record the full 40-character commit SHA.
3. Verify that a mirror returns the same commit before cloning from it.
4. Check out the commit in detached mode instead of tracking `master`.
5. Build artifacts once and publish their checksums with the integration release.
6. Do not trust mirror tags or releases without comparing them to the authoritative source.

Mirror availability can change without notice. Re-run the checks in this document when changing the upstream version.
