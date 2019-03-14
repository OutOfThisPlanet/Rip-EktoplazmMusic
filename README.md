# Rip-EktoplazmMusic
This is a PowerShell function for the automated asynchronous download of free music available on the Ektoplazm site. 

Requires PowerShell 5, or later

Choose MP3, WAV, or FLAC downloads (all files seem to come in an archive)

Choose the scope of what to Download: DJs, Producers, Labels, or ALL THE THINGS!!

If you have 7zip installed, you can even check if each download has completed successfully. 

Load the function, and run it with:

Rip-EktoplazmMusic 

If no flags are specified, a menu will be presented

Alternatively, it can be ran like this:

Rip-EktoplazmMusic -OutputPath "C:\Temp" -AudioFormat "MP3" -Mode "Labels" -TestDownload:$true
