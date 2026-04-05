# Intel SSD Firmware and Btrfs Corruption Incident

This report details a filesystem corruption issue on Bazzite (Btrfs) caused by a firmware incompatibility with an Intel SSD 660p series NVMe drive.

## Device Information
- **Model:** `INTEL SSDPEKNW020T8` (Intel SSD 660p Series, 2.0 TB)
- **Firmware Revision:** `005C` (Current)
- **Filesystem:** Btrfs on `/dev/nvme0n1p4` (Bazzite Root Partition)

## Incident Description
Frequent Btrfs corruption errors were observed, leading to read/write errors on critical system files within the OSTree store. The error logs indicated specific checksum failures (`BTRFS error (device nvme0n1p4): bdev /dev/nvme0n1p4 errs: corrupt 1`). These errors occurred despite the drive being reported as healthy by SMART data.

## Root Cause
Intel 660p and other similar SSD models are known to have issues with NVMe autonomous power state transitions (APST) on Linux. These power-saving transitions can lead to data loss or corruption during disk operations, especially with the frequent small I/O operations of Btrfs.

## Mitigation and Resolution
To stabilize the system and prevent further corruption, the following kernel parameters have been added to the boot configuration:

### Kernel Parameters
- **`nvme_core.default_ps_max_latency_us=0`**: Disables APST (Autonomous Power State Transitions) for all NVMe drives. This forces the SSD to stay in an active power state, preventing the problematic transitions.
- **`pcie_aspm=off`**: Disables Active State Power Management for the PCIe bus, further ensuring stability.

### Verification
After applying these parameters, verify the boot configuration:
```bash
cat /proc/cmdline
```
Confirm the presence of:
`nvme_core.default_ps_max_latency_us=0 pcie_aspm=off`

## Remediation for Existing Corruption
If the filesystem is already corrupted:
1.  **Repository Repair:** Use `ostree fsck --delete` to identify and remove corrupted system objects.
2.  **Filesystem Check:** If kernel logs continue to show `BTRFS error` on new writes, a `btrfs check --repair` from a Live USB environment may be required.
3.  **Fresh Deployment:** Force a fresh pull of the base image using `rpm-ostree rebase` to replace missing or corrupted system files.
