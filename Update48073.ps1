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

$version = "KioskClient48073.zip"

# download 7za to C:\Tools

Write-Host "Downloading 7-Zip"

$TOOLS_PATH = "C:\Tools"

if ((Test-Path $TOOLS_PATH) -eq 0) {
	New-Item -ItemType directory -Path $TOOLS_PATH
}

if ((Test-Path "C:\Tools\7za.exe") -eq 0) {
	DownloadFile "https://bcyclepublic.blob.core.windows.net/kiosk/7za.exe" "C:\Tools\7za.exe"
}

# download latest B-cycle Update (V4)

Write-Host "Downloading Kiosk Client 4.8.0.73"
DownloadFile "https://bcyclepublic.blob.core.windows.net/kiosk/KioskClient48073.zip" "C:\Software\KioskClient48073.zip"

# terminate b-dog and b-cycle

taskkill /f /im b-dog.exe
taskkill /f /im b-cycle.exe

Start-Sleep -s 4

# clear log folder

Remove-Item "C:\B-cycle\logs\BDog\*.*" | Where { ! $_.PSIsContainer }

# Extract update

Write-Host "Extracting Update"
cmd /c "C:\Tools\7za.exe" x -y C:\Software\KioskClient48073.zip -oC:\B-cycle
Start-Sleep -s 4

# restart B-cycle app

restart-computer -force