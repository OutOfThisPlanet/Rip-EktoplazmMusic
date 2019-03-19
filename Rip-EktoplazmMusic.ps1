Function Rip-EktoplazmMusic
{
    param ([string]$OutputPath, [string]$AudioFormat, [string]$Scope, [Parameter()][bool]$TestDownload)
    CLS
    #region Splatting Colours
    $RedText = `
    @{
        ForegroundColor = "Red"
        BackgroundColor = "Black"
    }
    $GreenText = `
    @{
        ForegroundColor = "Green"
        BackgroundColor = "Black"
    }
    $YellowText = `
    @{
        ForegroundColor = "Yellow"
        BackgroundColor = "Black"
    }
    $CyanText = `
    @{
        ForegroundColor = "Cyan"
        BackgroundColor = "Black"
    }
    #endregion

    #region Choices
    if (!$OutputPath -or !$AudioFormat -or !$Scope)
    {
        Write-Host 'Valid Audio Format choices are "MP3", "WAV", or "FLAC"' @RedText 
        Write-Host 'Valid Scope choices are "DJs", "Producers", "Labels", or "Leech"' @RedText 
        Write-Host 'You can also choose to test your downloads have completed properly by setting the "TestDownload" flag to "True". The 7zip program is required for this.' @RedText
        Write-Host "To save time, you can pre-specify your options:" @YellowText
        Write-Host ""
        Write-Host 'Rip-EktoplazmMusic -OutputPath "<Output Path>" -AudioFormat "<Audio Format>" -Scope "<Scope>" -TestDownload:$True' @CyanText  
        Write-Host ""
    }
    #Display some things if certain flags were not set at run time
    if (!$OutputPath)
    {
        $OutPutPath = Read-Host "Please enter the path where you want your files saved (e.g. C:\Temp)"
        
        if (!(Test-Path $OutputPath))
        {
            Write-Host "Output path does not exist" @RedText
            return;
        }
        else
        {
            CLS
            Write-host "Output Path is:" $OutputPath @GreenText
            Write-Host ""
        }
    }
    #Choose an audio format
    if (!$AudioFormat)
    {
        Write-Host "Which Audio Format do you want to download?" @RedText
        Write-Host ""
        Write-Host 'Choose "1" for "MP3"' @GreenText
        Write-Host 'Choose "2" for "WAV"' @GreenText
        Write-Host 'Choose "3" for "FLAC"' @GreenText
        Write-Host ""

        $AudioFormat = Read-Host "Which Audio Format do you want?"

	Switch ($AudioFormat)
	{
	    1 {$AudioChoice = "MP3"}
	    2 {$AudioChoice = "WAV"}
	    3 {$AudioChoice = "FLAC"}
        }
        $AudioFormat = $AudioChoice
        if (!$AudioFormat)
        {
            Write-Host "That was not a valid choice" @RedText
            return;
        }
    }
    cls
    #Choose download scope
    if (!$Scope)
    {
        Write-Host "Download scope has not yet been set!" @RedText 
        Write-Host "Please choose:" @GreenText
        Write-Host ""
        Write-Host "1 - DJs only" @YellowText
        Write-Host "2 - Producers only" @YellowText
        Write-Host "3 - Labels only" @YellowText
        Write-Host "4 - Leech ALL THE THINGS!!!!!" @YellowText
        Write-Host ""
        Write-Host "Select number from 1 - 4" @RedText
         
        $Scope = Read-Host "Please enter choice number"
        Switch ($Scope)
        {
	    1 {$ScopeChoice = "DJs"}
	    2 {$ScopeChoice = "Producers"}
	    3 {$ScopeChoice = "Labels"}
            4 {$ScopeChoice = "Leech"}
        }
        $Scope = $ScopeChoice
        if (!$Scope)
        {
            Write-Host "That was not a valid choice" @RedText
            return;
        }
    }
    Cls
    #Set some stuff based on choices so far
    if ($Scope -eq "DJs")
    {
        Write-Host "Retrieving list of DJs" @RedText
        $SectionStub = "profiles/djs"
        $GotoSection = "Scoped"
    }
    elseif ($Scope -eq "Producers")
    {
        Write-Host "Retrieving list of Producers" @RedText
        $SectionStub = "profiles/producers"
        $GotoSection = "Scoped"
    }
    elseif ($Scope -eq "Labels")
    {
        Write-Host "Retrieving list of Labels" @RedText
        $SectionStub = "profiles/labels"
        $GotoSection = "Scoped"
    }
    elseif ($Scope -eq "Leech")
    {
        Write-Host "Leech ALL THE THINGS!!!" @RedText
        $SectionStub = "free-music"
        $GotoSection = "Everything"
    }
    #endregion

    #region Config
    $BasePageLink = "http://www.ektoplazm.com/section/$($SectionStub)"
    $progressPreference = 'silentlyContinue'
    #endregion

    #region Get Links
    #This is for a more selective download experience
    if ($GotoSection -eq "Scoped")
    {
        $AllProfileURLS = ((Invoke-WebRequest –Uri $BasePageLink).Links | where {$_.outerHTML -like "*Permanent Link to*"} | select href).href | Sort-Object -Unique

        #Build a hashtable for available profile urls and profile names. This may take a miniute or two
        $ProfilesWithDownloads = $null
        $ProfilesWithDownloads = @{}

        foreach ($ProfileURL in $AllProfileURLS)
        {
            #Get all the profile information where a profile has download links (not all do)
            $ProfileFiles = ((Invoke-WebRequest –Uri $ProfileURL).Links | where {$_.outerHTML -like "*Download*" -and $_.innerHTML -notlike ""})
    
            if ($ProfileFiles)
            {
                #If there were any download links, add the information to the hashtable
                $ProfilesWithDownloads.Add(($ProfileURL | Split-Path -Leaf),$ProfileURL)
            }
        }

        #Build a selection menu for the discovered profiles with download links
        $ProfileMenu = @{}
        #For each of the profile links...
        for ($i=1;$i -le $ProfilesWithDownloads.count; $i++) 
        {
            #Display profile information in the console, with a bit of formatting magic thrown in for good measure
            Write-Host "$i. $((Get-Culture).textinfo.totitlecase((($ProfilesWithDownloads.GetEnumerator() | select -Index ($i-1)).Name).replace('-',' ')))"
            $ProfileMenu.Add($i,($ProfilesWithDownloads.GetEnumerator() | select -Index ($i-1)).Name)
        }
        #If there are more than 1 profiles found, display the menu and wait for user input
        if ($ProfilesWithDownloads.count -gt 1)
        {
            Write-Host ""
            [int]$ProfileSelection = Read-Host "Select the number of the $($Scope.Replace('s','')) that you want"
        }
        #If there is only 1 profile, just select it
        else
        {
            [int]$ProfileSelection = 1
        }

        $ProfileSelected = $ProfileMenu.Item($ProfileSelection)

        #Selected Profile Page URL
        $ChosenProfileURL = $ProfilesWithDownloads."$ProfileSelected"
        #Chosen Download Links
        $Links = ((Invoke-WebRequest –Uri $ChosenProfileURL).Links | where {$_.outerHTML -like "*Download*" -and $_.innerHTML -notlike ""} | select href ).href
        #This is just to avoid some code used for the Leech option
        $SkipPageNumber = $true
        #Everthing is on one page, so set the last page number to 1
        $MaxPages = 1
    }
    #This is for if you wanna leech ALL THE THINGS!!!!
    elseif ($GotoSection -eq "Everything")
    {
        #Check out how many pages of free music downloads there are by looking at the last page number
        $AllPages = ((Invoke-WebRequest –Uri $BasePageLink).Links | where {$_.outerHTML -like "*Last*"} | select href).href | Split-Path -Leaf
        #Set the number of pages to the last page number
        $MaxPages = [int]$AllPages
        CLS
    }

    #endregion 

    #region Downloading
    #For every page up to the last page number...
    for ($PageNumber = 1; $PageNumber -le $MaxPages; $PageNumber++)
    {
        #This is just for the Leech option
        if (!$SkipPageNumber)
        {
            #Getting all the download links on the CURRENT page
            Write-Host "Checking Ektoplazm Page number $($PageNumber) of $($MaxPages) for download links" @CyanText 
            $PageLink = $BasePageLink + "/page/" + $PageNumber
            #Chosen Download Links for the CURRENT PAGE
            $Links = ((Invoke-WebRequest –Uri $PageLink).Links | where {$_.outerHTML -like "*$($AudioFormat) Download*" -and $_.innerHTML -notlike ""} | select href).href
        }        
        #For every download link
        foreach ($Link in $Links)
        {
            #Work out the filename from the download link
            $Filename = ($Link | Split-Path -Leaf) -replace ("%20"," ")
            #Set the save location
            $FileOutput = $OutputPath + "\" + $Filename
            #If the file doesn't already exist in the download location...
            if (!(Test-Path -Path $FileOutput))
            {
                #Download it
                Write-Host " Downloading $($Filename) " @YellowText -NoNewline
                (New-Object System.Net.WebClient).DownloadFile($Link, $FileOutput)
                Write-Host " Done! " @GreenText
            }
            else
            {
                #Otherwise skip it
                Write-Host " Already have $($Filename) " @RedText
            }
            #If the test download flag has been set in the command...
            if ($TestDownload)
            {
               #Test it
               $7z = "C:\Program Files\7-Zip\7z.exe"

                if (($FileOutput |  % { & $7z t $_ -r}) -contains "Everything is Ok")
                {
                    Write-Host "Download is ok" @YellowText
                    continue;
                }
                #If it is bad, redownload it
                else
                {
                    Write-Host " Re-Downloading $($Filename) " @CyanText -NoNewline
                    (New-Object System.Net.WebClient).DownloadFile($Link, $FileOutput)
                    Write-Host " Done! " @GreenText
                    #Test it again, and if it is still bad, move on...
                    if (($FileOutput |  % { & $7z t $_ -r}) -contains "Everything is Ok")
                    {
                        Write-Host "Download is ok" @YellowText
                        continue;
                    }

                    else
                    {
                        Write-Host "Download is corrupted!" @RedText
                        continue;
                    }
                }
            }
        }
        #Finish the CURRENT page
        Write-Host " Page $PageNumber Done! " @GreenText
    }
    #Finished everything!
    Write-Host " All $($AudioFormat) files ripped! " @GreenText
    #endregion

}

#Uncomment the line below to run the function
#Rip-EktoplazmMusic -OutputPath "C:\Temp" -AudioFormat "MP3" -Mode "Labels" -TestDownload:$false
