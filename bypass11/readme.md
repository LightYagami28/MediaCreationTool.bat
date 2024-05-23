# Windows 11 Upgrade Guide

## Get Windows 11 on Unsupported PC

### Step 1: Automatic Bypass of Setup Requirements

Use the [Skip_TPM_Check_on_Dynamic_Update.cmd](Skip_TPM_Check_on_Dynamic_Update.cmd) script to automatically bypass setup requirements. This script is a set-it-and-forget-it solution, featuring built-in undo functionality. Version 7 introduces a more reliable /Product Server trick, while version 9 is rebased on cmd due to defender transgression and skips already patched media (0b).

### Step 2: Subscribe to Desired Channel

Utilize the [OfflineInsiderEnroll](https://github.com/abbodi1406/offlineinsiderenroll) tool to subscribe to the channel you want. For Windows 10, use BETA for Windows 11 22000.x builds (release) and DEV for Windows 11 225xx.x builds (experimental).

### Step 3: Check for Updates

Check for updates via Settings - Windows Update and select Upgrade to Windows 11.

## Get Windows 11 via MediaCreationTool.bat

The [MediaCreationTool.bat](../MediaCreationTool.bat) creates Windows 11 media that will automatically skip clean install checks. The Auto Upgrade preset or launching `auto.cmd` from the created media will automatically skip upgrade checks. Running `setup.exe` from the created media is not guaranteed to bypass setup checks (it should for now). To avoid adding a bypass to the media, use the MCT Defaults preset or rename the script as `def MediaCreationTool.bat`.

Regarding the bypass method, clean installation is still handled via `winsetup.dll` patching in `boot.wim`, while upgrade is now handled via `auto.cmd` with the /Product Server trick.

## Adding Bypass to Existing Windows 11 Media

Already have Windows 11 ISO, USB, or extracted files and want to add a bypass? Use the [Quick_11_iso_esd_wim_TPM_toggle.bat](Quick_11_iso_esd_wim_TPM_toggle.bat) script from the comfort of the right-click - SendTo menu. This script switches installation type to Server, skipping install checks, or back to Client if run again on the same file, restoring hash. It works directly on any downloaded Windows 11 ISO or extracted ESD and WIM, eliminating the need for ISO/DISM mounting.

## Offline Local Account on Windows 11 Home/Pro

The [MediaCreationTool.bat](../MediaCreationTool.bat) creates media that re-enables the "I don't have internet" OOBE choice (OOBE\BypassNRO). It does so via `AutoUnattend.xml`, inserted into `boot.wim` to not cause `setup.exe` issues under Windows. It can be conveniently placed at the root of Windows 11 media, along with `auto.cmd` to use for upgrades. This should work with any Windows 11 Release (22000.x) or Dev (22xxx.x) media, and it hides unsupported PC nags as a bonus.

## Managing and Troubleshooting Windows Update

To manage and troubleshoot Windows Update on any Windows version and edition, use the following scripts:
- [windows_update_refresh.bat](https://pastebin.com/XQsgjt9p): to clear pending updates, including sneaky feature upgrades.
- [windows_drivers_update_toggle.bat](https://pastebin.com/cK8y4YEX): to block driver updates even on Home editions.
- [windows_feature_update_toggle.bat](https://pastebin.com/EcLB14hg): to block feature upgrades on Windows versions from 1507 to 21H2, even on Home editions.
