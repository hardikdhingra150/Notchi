# Releasing Notchi

Releases are built by `.github/workflows/release.yml` when you push a tag:

```bash
git tag v0.1.0-beta.1 && git push origin v0.1.0-beta.1   # pre-release
git tag v0.1.0 && git push origin v0.1.0                 # release
```

It builds a universal `Notchi.app`, zips it with the CLI, writes `SHA256SUMS.txt`,
and publishes a GitHub Release. Everything below is free.

## One-time setup (maintainer only)

### 1. Free self-signed certificate (keeps permissions across updates)
1. Keychain Access → Certificate Assistant → **Create a Certificate…**
2. Name: `Notchi Self-Signed`, Identity Type: **Self Signed Root**, Certificate Type: **Code Signing**.
3. Export it from the **login** keychain as `notchi.p12` with a password.
4. Repo → Settings → Secrets and variables → Actions → **Secrets**:
   - `NOTCHI_CERT_P12`: output of `base64 -i notchi.p12 | pbcopy`
   - `NOTCHI_CERT_PASSWORD`: the export password
   - `NOTCHI_SIGN_ID`: `Notchi Self-Signed`

Without these, builds are signed ad hoc and users have to re-grant permissions after each update.

### 2. Sparkle update key (signs every update)
1. Download Sparkle 2.10.0 from its GitHub releases and run `./bin/generate_keys`.
   It saves the private key in your login keychain and prints the public key.
2. Repo → Settings → Secrets and variables → Actions:
   - **Variable** `NOTCHI_ED_PUBLIC_KEY`: the printed public key
   - **Secret** `SPARKLE_ED_PRIVATE_KEY`: output of `./bin/generate_keys -x private.key && cat private.key` (delete the file after)

Without these the app still works, it just won't offer updates.

## How users install
Download `Notchi-<version>.zip`, move Notchi.app to Applications, open it, then
**System Settings → Privacy & Security → Open Anyway** (once). See the website's install section.

## A note on hardened runtime

`scripts/bundle.sh` signs **without** hardened runtime by default. Hardened runtime
turns on library validation, which only loads frameworks signed by the same Apple
Team ID. Ad hoc and self-signed builds have no Team ID, so the embedded
`Sparkle.framework` would be refused and the app would not launch. If you ever sign
with a paid Developer ID (for notarization), set `NOTCHI_HARDENED=1`.
