# Board support

This directory contains files implementing NuttX's board support. The external
board is used to allow modification of the code.

This directory content is almost the same as an appropriate directory in NuttX.
The changes are:

* Missing `Kconfig`, because it isn't available to the external boards.
* `configs` contains config files directly instead of profiles and those files
  are also manually managed not generated as minification of the configuration.
* Header-file in `src` is not named after board but simply as `sam_board.h`.
* Added `rcS` and `rc.sysinit` files

It is highly advised to update this directory with changes in the upstream board
support directories when updating NuttX!
