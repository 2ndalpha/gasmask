# Gas Mask
[![Build Status](https://github.com/2ndalpha/gasmask/actions/workflows/push.yml/badge.svg)](https://github.com/2ndalpha/gasmask/actions/workflows/push.yml)

Gas Mask is a simple hosts file manager for macOS.
It allows editing of host files and switching between them.

## System requirements
Requires macOS 13 (Ventura) or later.

## Download
[Download latest version (0.8.6)](https://github.com/2ndalpha/gasmask/releases/download/0.8.6/gas_mask_0.8.6.zip)

## Installation
Drag the application from Downloads into the Applications folder. The first time you launch it, it will ask for your password, because it needs escalated privileges to modify your `/etc/hosts` file.

## How it works
Gas Mask monitors `/etc/hosts` system file and updates it with your activated hosts file.

Gas Mask stores your custom hosts files in `~/Library/Gas Mask` directory.

Application log can be found in `~/Library/Logs/Gas Mask.log`. It's worth having a look for errors in there when posting an issue.

## User Guide
Gas Mask usually operates in the background. It adds a menu bar icon, where you can access the main editor window and quickly switch between hosts files.

The main editor consists of three parts: Toolbar, a list of your hosts files on the left, and file editor on the right. Initially you will have a single file called `Original file` under `Local`, which is a copy of your original /etc/hosts file.

To add new files, click `Create(+)` button in the toolbar and select the type of file (Local, Remote or Combined).

To remove a file, select it and press the `Remove` button in toolbar.

To activate a file, select it and press `Activate` button in toolbar, or select it from the menu bar icon when the editor is hidden. Gas Mask will update the `/etc/hosts` file with the currently activated file. The active file is marked with a check in the editor list, and can also be displayed next to the Gas Mask menu bar icon (Preferences > Show Host File Name in Status Bar)

#### Local files
These are ordinary local files that you can edit.

#### Remote files
These are files that Gas Mask downloads and synchronizes from remote URLs. You can adjust how often they should update in Preferences, or force an update from the menu bar icon. You cannot edit these files, as they are overwritten by updates.

#### Combined files
This is where Gas Mask shines compared to other hosts managers for macOS. A combined file doesn't contain hosts entries, but a list of local and remote files.

## Where to find hosts files
A great source of curated hosts files can be found at https://github.com/StevenBlack/hosts

## Building Gas Mask
Gas Mask can be built with Xcode 15 or later.
