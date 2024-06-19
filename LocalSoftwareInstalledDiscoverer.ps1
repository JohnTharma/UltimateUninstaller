Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate , UninstallString , QuietUninstallString | Export-Csv -path C:\Temp\SampleListx32.csv -append
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate , UninstallString , QuietUninstallString | Export-Csv -path C:\Temp\SampleListx64.csv -append
exit
