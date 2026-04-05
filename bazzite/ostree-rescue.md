# OSTree Repository Rescue Guide

This guide documents the recovery process for a corrupted OSTree repository on Bazzite (Fedora-based), specifically resolving the error:
`error: Opening content object <hash>: Couldn't find file object '<hash>'`

## Symptoms
- `rpm-ostree upgrade` or `update` fails with "Couldn't find file object".
- Filesystem corruption (Btrfs) has previously occurred, leading to missing objects in the OSTree store.
- Standard `rpm-ostree cleanup` does not resolve the issue.

## Recovery Procedure

### 1. Identify and Mark Corrupted Commits
Run a full file system check on the OSTree repository. This will identify missing objects and mark the associated commits as "partial."
```bash
sudo ostree fsck --delete
```
*Note: This process is I/O intensive and may cause the UI to freeze temporarily.*

### 2. Clear Container Image Cache
Bazzite uses container-based deployments. If the corruption is within the container layers, you must force a fresh pull by deleting the local image and blob references.
```bash
# Delete all local container image and blob references
sudo ostree refs --delete $(ostree refs | grep "ostree/container")

# Prune the orphaned objects
sudo ostree prune --refs-only
```

### 3. Reset rpm-ostree Metadata
Clear the cached metadata to ensure the next pull fetches fresh information.
```bash
sudo rpm-ostree cleanup -bm
```

### 4. Force a Fresh Deployment (Rebase)
Instead of a simple upgrade, perform a `rebase` to the same image to force a complete reconciliation of the system files.
```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/ublue-os/bazzite-nvidia-open:stable
```

## Summary of Commands
```bash
sudo ostree fsck --delete
sudo ostree refs --delete $(ostree refs | grep "ostree/container")
sudo ostree prune --refs-only
sudo rpm-ostree cleanup -bm
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/ublue-os/bazzite-nvidia-open:stable
```
