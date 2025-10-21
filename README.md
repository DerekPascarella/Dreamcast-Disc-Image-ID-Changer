# Dreamcast Disc Image ID Changer
A utility for easily modifying a Dreamcast disc image's product ID.

Patching a disc image's product ID is particularly useful for indie/homebrew games that share generic IDs and thus cause overlap issues with things like automatic virtual VMU solutions. Note that there are a number of [retail games that share product IDs](https://github.com/mrneo240/openmenu/blob/a43013ca36e9b89719b91de1b61ae96ffa5f348c/backend/gd_list.c#L289) as well.

## Current Version
Dreamcast Disc Image ID Changer is currently at version [1.1](https://github.com/DerekPascarella/Dreamcast-Disc-Image-ID-Changer/releases/download/1.1/Dreamcast.Disc.Image.ID.Changer.v1.1.zip).

## Changelog
- **Version 1.1 (2025-10-21)**
  * Fixed status message output.
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

Once the program launches, the user will be presented with the disc's current product ID, along with an option to enter a new one. The new product ID will be automatically uppercased and truncated at 10 characters, and then used to patch the provided disc image.

Alternatively, it can be launched from a PowerShell Terminal or Command Prompt with the full path to the disc image as the first input argument. See example below.

`dc_id_changer.exe C:\full\path\to\disc.cdi`

Linux/UNIX users may leverage the [base Perl program](https://github.com/DerekPascarella/Dreamcast-Disc-Image-ID-Changer/blob/main/dc_id_changer.pl) rather than the pseudo-compiled executable included in the release package.

![alt text](https://github.com/DerekPascarella/Dreamcast-Disc-Image-ID-Changer/blob/main/images/screenshot.png?raw=true)
