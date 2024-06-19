::Please do this bat file For those stuck in waiting to install.
taskkill /im scclient.exe /f
taskkill /im ccmexec.exe /f
taskkill /im WmiPrvSE.exe /f
net stop CcmExec /y
net stop smstsmgr /y
net stop winmgmt /y
net stop appidsvc /y
net stop cryptsvc /y
net stop bits /y
net stop dosvc /y
net stop wuauserv /y
Ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
Ren C:\Windows\System32\catroot2 Catroot2.old
Ren C:\Windows\CCM\CcmStore.sdf CcmStore.sdf.old
rd /S /Q "C:\Windows\SoftwareDistribution.old"
rd /S /Q "C:\Windows\System32\catroot2.old"
rd /S /Q "C:\Windows\ccmcache"
Del /S /Q "C:\Windows\CCM\CcmStore.sdf.old"
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\Mobile Client\Software Distribution" /f
winmgmt /verifyrepository
winmgmt /salvagerepository
winmgmt /verifyrepository
sc config smstsmgr depend= winmgmt/ccmexec
sc config "smstsmgr" start= auto 
sc config "CCMExec" start= auto
sc config "winmgmt" start= auto
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\CCM\CcmExec /v ProvisioningMode /t REG_SZ /d false /f
net start smstsmgr /y
net start CcmExec /y
net start BITS
taskkill /im conhost.exe /f
CMD echo 'Reopen Software Centre and if install fail to start,spam on install again.'

