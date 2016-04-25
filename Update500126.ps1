# This Update requires the removal of all .dll and .pdb files used by previous kiosk client as they are now obsolete
#
# This Update also include a change to the Bcycle.exe.config file
#
# This script will:
# 1. pull system specific App Settings from the config file 
# 2. install updated kiosk client
# 3. replace system specific App settings
# 4. remove obsolete log folders and config files
# 5. restart the kiosk
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
$version = "KioskClient500126.zip"
$client = "Kiosk Client 5.0.0.126"

# Client Config Location
$webConfigPath = "C:\B-cycle\B-cycle.exe.Config" 
$xml = [xml](get-content $webConfigPath);
$root = $xml.get_DocumentElement();            

# Parse and save System Specific App Settings in Hash Table
Write-Host "Saving Local Sytem Settings"
$setting = @{}
Foreach( $item in $root.appSettings.add)
{              
$setting.Add($item.key,$item.value)
}
$modem = $setting.ConnectionName
$manual = $setting.ManualCardEntryEnabled
$local = $setting.LocalCulture

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

# Replace Stock Bcycle.exe.config settings with system settings
foreach( $item in $root.appSettings.add)
{ 
    if($item.key –eq “ConnectionName”)
    { 
      $item.value = “$modem”
    } 
    if($item.key –eq “ManualCardEntryEnabled”)
    { 
      $item.value = “$manual”
    } 
    if($item.key –eq “LocalCulture”)    
    { 
      $item.value = “$local”
    } 
}
Write-Host "Local Settings Updated"

# clear log folders
Write-Host "Beginning Cleanup"
Remove-Item "C:\B-cycle\logs\Server\*.*" | Where { ! $_.PSIsContainer }
Remove-Item "C:\B-cycle\logs\BDog\*.*" | Where { ! $_.PSIsContainer }
Remove-Item "C:\B-cycle\logs\BDogInbound" -Recurse
Remove-Item "C:\B-Cycle\logs\BDogOutbound" -Recurse
Remove-Item "C:\B-Cycle\logs\Update*" -Recurse
Remove-Item "C:\B-cycle\xml\*" -Exclude *.xml -Recurse
Write-Host "Cleanup Complete"

# restart kiosk
Write-Host "Restarting Kiosk"
Start-Process C:\B-cycle\B-dog.exe
