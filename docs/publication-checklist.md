# Publication checklist

## Blocking

- [x] Confirm Guard ERP authorship and redistribution rights.
- [x] Add the MIT License for original repository content and document external dependencies separately.
- [x] Scan staged content for private keys, common token formats, personal paths, non-loopback IP addresses, and email addresses.
- [x] Review the staged diff from the first commit, not only the working tree.

## Verification

- [x] Run `./scripts/check-local.sh`.
- [x] Run the fixture test suite: 8 passed, 0 failed.
- [x] Confirm every public result row against the private evidence archive.
- [ ] Pin container image and model digests for a frozen release.
- [x] Create the public remote only after all blocking items pass.

## Optional

- [ ] Add trademark attribution for named models and agent products.
