# This Update requires the removal of all .dll and .pdb files used by previous kiosk client as they are now obsolete
#

function DownloadFile($url, $targetFile)
{
   $uri = New-Object "System.Uri" "$url"
   $request = [System.Net.HttpWebRequest]::Create($uri)
   $request.set_Timeout(15000) #15 second timeout
   $response = $request.GetResponse()
   $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
   $responseStream = $response.GetResponseStream()
   $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
   $buffer = new-object byte[] 10KB
   $count = $responseStream.Read($buffer,0,$buffer.length)
   $downloadedBytes = $count

   while ($count -gt 0)
   {
       $targetStream.Write($buffer, 0, $count)
       $count = $responseStream.Read($buffer,0,$buffer.length)
       $downloadedBytes = $downloadedBytes + $count
       Write-Progress -activity "Downloading file '$($url.split('/') | Select -Last 1)'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength)  * 100)
   }

   Write-Host "Finished downloading file"

   $targetStream.Flush()
   $targetStream.Close()
   $targetStream.Dispose()
   $responseStream.Dispose()
}

# Client Version to be installed
$version = "KioskClient5013.zip"
$client = "Kiosk Client 5.0.1.3"


# terminate b-dog and b-cycle
Write-Host "Closing B-cycle Application"
taskkill /f /im b-dog.exe
taskkill /f /im b-cycle.exe
Start-Sleep -s 4

# clear B-cycle folder of outdated version
Write-Host "Removing Previous Versions of Kiosk Client"
remove-item C:\B-cycle\* -include *.dll, *.pdb

# download 7za to C:\Tools
Write-Host "Preparing for Download of Client"

$TOOLS_PATH = "C:\Tools"
if ((Test-Path $TOOLS_PATH) -eq 0) {
	New-Item -ItemType directory -Path $TOOLS_PATH
} else {
	write-host "Tools folder exists"
}

if ((Test-Path "C:\Tools\7za.exe") -eq 0) {
	DownloadFile "https://bcyclepublic.blob.core.windows.net/kiosk/7za.exe" "C:\Tools\7za.exe"
} else {
	write-host "7za program exists"
}

# download latest B-cycle Update (V5)
Write-Host "Downloading $version"
DownloadFile "https://bcyclepublic.blob.core.windows.net/kiosk/$version" "C:\Software\KioskClient.zip"

# Extract update
Write-Host "Extracting Update"
cmd /c "C:\Tools\7za.exe" x -y C:\Software\KioskClient.zip -oC:\B-cycle
Start-Sleep -s 4

write-host "$client Installed"


# download System Screen Flow Images
Write-Host "Downloading Screen Flow Images"
DownloadFile "http://bcyclepublic.blob.core.windows.net/kiosk/88images.zip" "C:\Software\screenimages.zip"

# Extract images

Write-Host "Extracting Images"
cmd /c "C:\Tools\7za.exe" x -y C:\Software\screenimages.zip -oC:\B-cycle\images 
Start-Sleep -s 4

# restart kiosk
Write-Host "Restarting Kiosk"
Start-Process C:\B-cycle\B-dog.exe