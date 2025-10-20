# Dreamcast Disc Image ID Changer
A utility for easily modifying a Dreamcast disc image's product ID.

## Current Version
Dreamcast Disc Image ID Changer is currently at version [1.0](xxxx).

## Changelog
- **Version 1.0 (2025-10-20)**
  * Initial release.

## Supported Disc Image Formats
The following disc image formats are currently supported by Dreamcast Disc Image ID Changer.
- TOSEC-format GDI
- Redump-format CUE/BIN
- CDI

## Usage
Dreamcast Disc Image ID Changer is easy to use.

In Windows' File Explorer, drag a disc image (e.g., `.gdi`, `.cue`, or `.cdi`) onto `dc_id_changer.exe`.

Once the program launches, the user will be presented with the disc's current product ID, along with an option to enter a new one.

Alternatively, it can be launched from a PowerShell Terminal or Command Prompt with the full path to the disc image as the first input argument. See example below.

`dc_id_changer.exe C:\full\path\to\disc.cdi`

Linux/UNIX users may leverage the base Perl program included in the release package rather than the pseudo-compiled executable.

![alt text](https://github.com/DerekPascarella/Dreamcast-Disc-Image-ID-Changer/blob/main/images/screenshot.png?raw=true)
