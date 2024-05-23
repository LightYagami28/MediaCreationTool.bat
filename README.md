# Universal MediaCreationTool Wrapper Script

![Language](https://img.shields.io/badge/Language-Batch-blue)

## Overview

This script isn't just a wrapper for the Universal MediaCreationTool; it also provides ingenious support for business editions and serves as a powerful, yet simple, deployment automation tool for Windows 10/11.

![Preview](preview.png)

*If previous versions didn't work for you, this latest version should resolve those issues.*

## Presets

### 1. **Auto Upgrade**
Automatically upgrades the system using the detected media.
- Keeps files and apps even when OS and target edition don't match.
- Switches detected edition by adding `EditionID` to the script name.
- Troubleshoots upgrade failures by adding `no_update` to the script name.
- Defaults to Windows 11; specify the version for Windows 10: `auto 21H2 MediaCreationTool.bat`.

### 2. **Auto ISO**
Creates an ISO with the detected media in the current folder or `C:\ESD` if run from a zip.
- Override detected media by adding edition name/language/arch to the script name.
- Example: `21H1 Education en-US x86 iso MediaCreationTool.bat`.

### 3. **Auto USB**
Creates a bootable USB with the detected media on a specified USB target.
- For data safety, you must manually select the USB drive in the GUI.

### 4. **Select**
Allows user to pick Edition, Language, and Arch (x86, x64, both) for a specified target.
- Implicit choice includes setup override files (disable by adding `def` to the script name).

### 5. **MCT Defaults**
Runs unassisted, creating media without modifying the script.
- No added files, the script passes `products.xml` to MCT and quits without touching the media.

### Media Modification Details
Presets 1-4 modify created media as follows:
- Writes `auto.cmd` for automatic upgrade with edition switch and TPM skip.
- Writes `$ISO$` folder content (if it exists) at the media root.
  - Previously used `$OEM$` content must now be placed in `$ISO$\sources\$OEM$\`.
- Writes `sources\PID.txt` to preselect edition at media boot or within Windows (if configured).
- Writes `sources\EI.cfg` to prevent product key prompt on Windows 11 consumer media (Windows 11 only).
- Writes `AutoUnattend.xml` in `boot.wim` to enable local accounts on Windows 11 Home (Windows 11 only).
- Patches `winsetup.dll` in `boot.wim` to remove Windows 11 setup checks when booting from media (Windows 11 only).
- Disable modifications by adding `def` to the script name for default, untouched MCT media.

## Simple Deployment

**auto.cmd** is used for the **Auto Upgrade** preset via GUI.
- Can run unattended by renaming the script to `auto MediaCreationTool.bat`.
- Facilitates upgrading while keeping files and apps even if the OS edition does not match the media.
- Allows upgrades from Ultimate, PosReady, Embedded, LTSC, or Enterprise Eval editions.

The generated script is added to the created media for reuse. It:
- Detects available editions in `install.esd`, selects a suitable index, and sets `EditionID` in the registry to match.
- Can force another edition while keeping files and apps.
- On Windows 11, attempts to skip setup checks (can be disabled).
- Sets recommended setup options for minimal issues during upgrades.

### Examples

- Current OS: Enterprise LTSC 2019 using business media to upgrade:
  - **auto.cmd** selects Enterprise index and adjusts `EditionID` to Enterprise in the registry (backed up as `EditionID_undo`).
- Switching edition (e.g., `ProfessionalWorkstation MediaCreationTool.bat`):
  - **auto.cmd** selects Professional index and sets `EditionID` to ProfessionalWorkstation.
- Upgrading from Windows 7 Ultimate or PosReady using consumer media:
  - **auto.cmd** selects Professional index and sets `EditionID` to Professional or Enterprise, respectively.
- For upgrading multiple PCs with different versions and editions to the latest Windows 10 version using Pro:
  - Rename the script to: `auto 21H2 Pro MediaCreationTool.bat`.
- Add a VL/MAK/retail product key similarly for handling licensing differences.
- The script also includes any `$ISO$` folder content for branding, configuration, tweaks, etc.

## Changelog

_No need to right-click Run as Admin, the script will ask itself. Directly saving the raw files no longer breaks line endings._

- 2018.10.10: Reinstated 1809 [RS5], using native XML patching for `products.xml`; fixed syntax bug with `exit/b`.
- 2018.10.12: Added data loss warning for RS5.
- 2018.11.13: RS5 officially back; greatly improved choices dialog.
- 2019.05.22: 1903 [19H1].
- 2019.07.11: 1903 __release_svc_refresh__; enabled DynamicUpdate by default.
- 2019.09.29: Updated 19H1 build 18362.356; RS5 build 17763.379; added LATEST MCT choice.
- 2019.11.16: 19H2 18363.418 as default choice.
- 2020.02.29: 19H2 18363.592.
- 2020.05.28: 2004 19041.264 first release.
- 2020.10.29: 20H2 and anniversary script refactoring to support all MCT versions from 1507 to 20H2.
- 2020.10.30: Hotfix UTF-8, enterprise on 1909+.
- 2020.11.01: Fix remove unsupported options in older versions code breaking when path has spaces.
- 2020.11.14: Generate latest links for 1909, 2004; all XML editing now in one go.
- 2020.11.15: One-time clear of cached MCT; fixed compatibility with Windows 7 Powershell 2.0.
- 2020.11.17: Parse first command line parameter as version, example: `MediaCreationTool.bat 1909`.
- 2020.12.01: Fix reported issues with 1703; no other changes.
- 2020.12.11: 20H2 19042.631; fixed 1703 decryption bug on dual x86 + x64.
- 2021.03.20: Pre-release 21H1; optional auto upgrade or create media presets importing `$OEM$` folder and key as `PID.txt`.
- 2021.05.23: 21H1 release; enhanced script name args parsing, upgrade from embedded.
- 2021.06.06: Create ISO directly; enhanced dialogs; args from script name or command line.
- 2021.08.04: Refactoring complete.
- 2021.09.03: 21H2, both 10 and 11 [unreleased].
- 2021.09.25: Windows 11.
- 2021.09.30: Fix Auto Setup preset not launching automatically.
- 2021.10.04: Fix for long-standing tr localization quirks.
- 2021.10.05: 11 22000.194 Release; using 21H1 MCT.
- 2021.10.09: Refactoring around Windows 11 MCT.
- 2021.10.20: Create generic ISO if no edition arg; use Downloads folder.
- 2021.10.23: 11 22000.258; more intuitive presets; 11 setup override via `AutoUnattend.xml`.
- 2021.11.03: Multiple download methods; improved automation.
- 2021.11.09: Skip Windows 11 upgrade checks with `setup.exe`.
- 2021.11.15: 11 22000.318; write output to script folder; style improvements.
- 2021.11.16: 10 19044.1288 - official release of 10 21H2.
- 2021.12.07: Skip Windows 11 upgrade checks only via `auto.cmd`.
- 2021.12.15: Fix regression with 1507-1709.
- 2021.12.22: Improved `auto.cmd` handling.
- 2022.03.16: Prevent launch errors when run from non-canonical paths.
- 2022.03.18: Fix regression with Auto Upgrade.
- 2022.03.20: Stable; all issues ironed out.

## Discussion

Join the discussion on [MDL](https://forums.mydigitallife.net/threads/universal-mediacreationtool-wrapper-script-create-windows-11-media-with-automatic-bypass.84168/).