#!/bin/bash
#
# Convert ICO and BMP files to XPM files
#
# To use this script you will need ImageMagick installed.

echo "Starting conversion of ICO and BMP files to XPM."

# Start with ICO files.
for image in *.ico *.bmp
do
  echo "Converting $image"
  x=${image%\.*}.xpm
  echo $x
  convert $image $x
  # Get rid of an extra _xpm in the name, if it exists.
  sed -i 's/_xpm\[]/[]/g' $x
  sed -i 's/^static char\(.*\)\[]/static const char\1_xpm[]/g' $x
done

echo "Done with conversion."
