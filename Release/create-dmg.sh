#!/bin/sh

VOLUME_NAME="Gas Mask 0.6"
APP_PATH="./Gas Mask.app"
SRC="dmg_src"
DMG_TEMP_NAME="Gas Mask 0.6 temp.dmg"
DMG_NAME="Gas Mask 0.6.dmg"
BACKGROUND_FILE="DMG Background.png"

test -f $SRC && rm -f $SRC
mkdir $SRC
cp -r "$APP_PATH" $SRC/ 2> /dev/null

# Make Applications alias
ln -s /Applications $SRC/Applications

# Create the image
echo "Creating disk image..."
test -f "${DMG_TEMP_NAME}" && rm -f "${DMG_TEMP_NAME}"
hdiutil create -srcfolder "$SRC" -volname "${VOLUME_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 300m "${DMG_TEMP_NAME}"

# mount it
echo "Mounting disk image..."
MOUNT_DIR="/Volumes/${VOLUME_NAME}"
echo "Mount directory: $MOUNT_DIR"
DEV_NAME=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TEMP_NAME}" | egrep '^/dev/' | sed 1q | awk '{print $1}')
echo "Device name: $DEV_NAME"

echo "Copying background file..."
test -d "$MOUNT_DIR/.background" || mkdir "$MOUNT_DIR/.background"
cp "$BACKGROUND_FILE" "$MOUNT_DIR/.background/custom_background.png"

# run applescript
echo "Running applescript..."
VOLUME_NAME=$VOLUME_NAME osascript process_disk_image.applescript

# Make sure it's not world writeable
echo "Fixing permissions..."
chmod -Rf go-w "${MOUNT_DIR}" || true

# unmount
echo "Unmounting disk image..."
hdiutil detach "${DEV_NAME}"

echo "Compressing disk image..."
hdiutil convert "${DMG_TEMP_NAME}" -format UDBZ -o "${DMG_NAME}"

rm -rf "${DMG_TEMP_NAME}"

rm -rf $SRC