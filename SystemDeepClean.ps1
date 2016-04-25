#Sets Up Disc Clean for single Cmd line run
#Clears out BDog log files
#Removes obsoloete log folders
#Removes outdate copies of station config and language files

# Create reg keys
write-host "Gathering the Cleaning Supplies"
$volumeCaches = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
foreach($key in $volumeCaches)
{
    New-ItemProperty -Path "$($key.PSPath)" -Name StateFlags0088 -Value 2 -Type DWORD -Force | Out-Null
}

# Run Disk Cleanup 
Write-host "Spraying Some Bleach and Swinging a Mop"
cmd.exe /c "cleanmgr /sagerun:88"

# clear log folders
write-host "Getting Out the Duster and Clearing Cob-Webs"
Remove-Item "C:\B-cycle\logs\BDog\*.*" | Where { ! $_.PSIsContainer }
Remove-Item "C:\B-cycle\logs\BDogInbound" -Recurse
Remove-Item "C:\B-Cycle\logs\BDogOutbound" -Recurse
Remove-Item "C:\B-Cycle\logs\Update*" -Recurse

# remove old cofig, language files, and updates
Write-Host "Taking Old Used Stuff to GoodWill"
Remove-Item "C:\B-cycle\xml\*.xml_*"
Remove-Item "C:\B-cycle\xml\Language\*.xml_*"
Remove-Item "C:\*\*.zip" -Recurse


Write-Host "THESE PIPES ARE CLEAN"
Start-Sleep 8