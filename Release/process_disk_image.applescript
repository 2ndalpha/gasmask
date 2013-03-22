on run -- for testing in script editor
	set volumeName to system attribute "VOLUME_NAME"
	process_disk_image(volumeName)
end run

on process_disk_image(volumeName)
	tell application "Finder"
		tell disk (volumeName as string)
			open
			
			set theXOrigin to 100
			set theYOrigin to 100
			set theWidth to 520
			set theHeight to 229
			
			set theBottomRightX to (theXOrigin + theWidth)
			set theBottomRightY to (theYOrigin + theHeight)
			set dsStore to "\"" & "/Volumes/" & volumeName & "/" & ".DS_STORE\""
			--			do shell script "rm " & dsStore
			
			tell container window
				set current view to icon view
				set toolbar visible to false
				set statusbar visible to false
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
				set statusbar visible to false
				
			end tell
			
			set opts to the icon view options of container window
			tell opts
				set icon size to 96
				set arrangement to not arranged
			end tell
			
			set background picture of opts to file ".background:custom_background.png"
			set position of item "Gas Mask.app" to {120, 90}
			set position of item "Applications" to {370, 90}
			
			tell container window
				set statusbar visible to false
				
				set the bounds to {theXOrigin + 1, theYOrigin, theBottomRightX, theBottomRightY}
				
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
			end tell
			
			update without registering applications
		end tell
		
		--give the finder some time to write the .DS_Store file
		set waitTime to 0
		set ejectMe to false
		repeat while ejectMe is false
			delay 1
			set waitTime to waitTime + 1
			
			if (do shell script "[ -f " & dsStore & " ]; echo $?") = "0" then set ejectMe to true
		end repeat
		log "waited " & waitTime & " seconds for .DS_STORE to be created."
	end tell
end process_disk_image