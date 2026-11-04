# Peter's F-Droid Repo

Add to Droid-ify or another F-Droid client:

- Address: `https://peter-singh.github.io/peters-fdroid-repo/fdroid/repo`
- Fingerprint: `636FDFDF44CB23F5396C173A25625C92E73D1DA1AF3FB654B2B85C4BF6A78097`

Or scan this QR code:

<img src="fdroid/repo/index.png" alt="QR code to add Peter's F-Droid Repo" width="250">

## Apps

- NissanConnect (unofficial): not affiliated with or endorsed by Nissan.
- VOD: Android TV and phone player for Xtream-style servers. Bring your own server.
- Scran: shopping lists and meal planning, for an account on list.prd.scot.

## Publishing

`.github/workflows/publish.yml` runs `scripts/sync.sh`, publishing each app's latest GitHub release. Each app's release workflow triggers it when a merge bumps the version. To run it by hand:

```
gh workflow run publish.yml -R peter-singh/peters-fdroid-repo
```

The repo signing key and config are secrets in the `fdroid-publish` environment, which only `main` can use. `FDROID_APPS_TOKEN` there has read access to the app repos' releases; when it expires, the workflow fails until it's replaced.

Keep `fdroid/keystore.p12` on the Mac: secrets can't be read back, and losing the key means every client has to add the repo again. `scripts/sync.sh` also runs there as a fallback.
