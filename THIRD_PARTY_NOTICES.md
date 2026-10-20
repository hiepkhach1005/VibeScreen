# Third-party attribution

## ColorControl and retained Windows components

The source under `legacy-windows/` originates from
[ColorControl by Maassoft](https://github.com/Maassoft/ColorControl). Original
copyright notices and source files are retained. This directory is a behavioral
reference for the native macOS rewrite and is not linked into the Swift app.

The following upstream notices, missing from the imported workspace, have been
restored verbatim from ColorControl commit `d0d3bb4682c483b0b2c14a794958abf2d142100e`:

- [LICENSE.txt](LICENSE.txt): GNU General Public License version 3.
- [LICENSE-THIRD-PARTY.txt](LICENSE-THIRD-PARTY.txt): attribution and LGPL v3
  terms for NvAPIWrapper, EDIDParser, and WindowsDisplayAPI.
- [LICENSE-NOVIDEO.txt](LICENSE-NOVIDEO.txt): attribution for Novideo sRGB
  by ledoge and the upstream GPL v3 notice.

Other component-level copyright and license headers remain in their original
source files. No original Windows source or artwork was rebranded or edited
during publication. VibeScreen is an independent macOS rewrite and is not
an official Maassoft release.

## Little CMS

`legacy-windows/LittleCms/lcms2.dll` is a retained Little CMS runtime dependency.
The wrapper declares Little CMS 2.13.1. Its [MIT copyright/permission notice](LICENSES/LittleCMS-COPYING.txt) is copied verbatim from
[Little CMS tag lcms2.13.1](https://github.com/mm2/Little-CMS/blob/lcms2.13.1/COPYING).
The library is not linked into the native macOS application.
