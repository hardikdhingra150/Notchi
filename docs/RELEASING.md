# Releasing Notchi

Releases are built by `.github/workflows/release.yml` when you push a tag:

```bash
git tag v0.5.0-beta.2 && git push origin v0.5.0-beta.2   # beta
git tag v0.5.0 && git push origin v0.5.0                 # release
```

It builds a universal `Notchi.app`, packs it as a `.dmg` and a `.zip`, adds the CLI, writes `SHA256SUMS.txt`,
and publishes a GitHub Release. Everything below is free.

## One-time setup (maintainer only)

```bash
./scripts/release-setup.sh
```

It creates two things on your Mac and stores them as GitHub Actions secrets:

- **A Sparkle update key.** Every update is signed with it, and the app refuses updates
  whose signature doesn't match. The private key is in your login keychain (account
  `notchi`); the public key goes into the app.
- **A self-signed certificate** (`Notchi Self-Signed`). Every release then has the same
  signature, so macOS keeps the Accessibility permission people granted across updates.

Both are also saved in `~/Library/Application Support/Notchi/ReleaseSigning`.
**Back that folder up.** If the update key is lost, people on older versions can never be
auto-updated again and have to download a new build by hand.

| Where | Name | What |
|---|---|---|
| Variable | `NOTCHI_ED_PUBLIC_KEY` | Update key, public half |
| Secret | `SPARKLE_ED_PRIVATE_KEY` | Update key, private half |
| Secret | `NOTCHI_CERT_P12` | The certificate, base64 |
| Secret | `NOTCHI_CERT_PASSWORD` | Its password |
| Secret | `NOTCHI_SIGN_ID` | `Notchi Self-Signed` |

Without the update key the app still works, it just won't offer updates. Without the
certificate, builds are signed ad hoc and people have to grant permissions again after
each update. 0.5.0-beta.1 was built without either, so people on it need to download the
next version by hand once.

## Betas and the update feed

The app reads `releases/latest/download/appcast.xml`. GitHub's "latest" skips
pre-releases, so betas are published as normal releases for now; otherwise people already
on a beta would never be offered the next one.

## How users install
Download `Notchi-<version>.dmg`, open it, drag Notchi to Applications, open it, then
**System Settings → Privacy & Security → Open Anyway** (once). The steps are also in a
text file inside the disk image and in the website's install section.

The release also has `Notchi-<version>.zip`. That one is for the updater: the update
feed points at it and its signature is in `appcast.xml`. `scripts/dmg.sh` builds the
disk image from `dist/Notchi.app`.

## A note on hardened runtime

`scripts/bundle.sh` signs **without** hardened runtime by default. Hardened runtime
turns on library validation, which only loads frameworks signed by the same Apple
Team ID. Ad hoc and self-signed builds have no Team ID, so the embedded
`Sparkle.framework` would be refused and the app would not launch. If you ever sign
with a paid Developer ID (for notarization), set `NOTCHI_HARDENED=1`.
