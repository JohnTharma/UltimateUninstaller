Add-Type -AssemblyName System.Windows.Forms

# fileGet - Gets the filename to open, usually a CSV for importing data
function fileGet($InitialDirectory) {
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $InitialDirectory
    $OpenFileDialog.filter = "CSV (*.csv) | *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.FileName
}

# fileSave - Gets the filename to save, usually a CSV for importing data
Function fileSave {
    $saveFileDialog = [System.Windows.Forms.SaveFileDialog]@{
        CheckPathExists  = $true
        CreatePrompt     = $true
        OverwritePrompt  = $true
        InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
        FileName         = 'NewFile'
        Title            = 'Choose directory to save the output file'
        Filter           = "CSV (*.csv) | *.csv"
    }

    # Show save file dialog box
    if($saveFileDialog.ShowDialog() -eq 'Ok') {
        New-Item -Path $saveFileDialog.FileName -ItemType File -Force
    } else {
		return "C:\Temp\exported_details.csv"
	}
}

function getOS($hW) {
	$hostnameOS = ""
	foreach($hh in $hW) {
		$os = Get-ADComputer -filter "name -eq '$hh'" -Properties * | Select OperatingSystem
		$osVersion = $os.OperatingSystem
		$hostnameOS += "$hh-($osVersion) " 
	}
	return $hostnameOS
}


function GetHWDetails {
    [cmdletBinding()] #adv
    param(
        [Parameter(Mandatory)][array]$devices,
		[string]$csv
    )
    Begin {
    #setup 
		$deviceDetails = @()
    }

    Process {
    #main work
		$deviceObj = [system.collections.generic.list[pscustomobject]]::new()		
		$uniqueUserNames = ""
		$currentLogonNames = ""
		$lastLogonNames = ""
		$lAT = ""
		$count = 1
		$rowCount = $devices.length
		Write-Host ""
		Write-Host "Output process logs"
		Write-Host "*******************"		
		foreach ($device in $devices) {
			# progress bar
			$percentCompleted = ($count/$rowCount*100)
			$roundedPercent = [math]::Round($percentCompleted,1)
		    Write-Progress -Activity "Getting user information details... " -Status "$roundedPercent% Complete:" -PercentComplete $percentCompleted
			if (($device -eq $null) -or ($device -eq "")) {
				Write-Host "Empty entry at row $count"
				$deviceObj = [PSCustomObject]@{
					DeviceName = "Empty entry at $count"
					Description = "Not found"
					CurrentLogonUser = "Not found"
					LastLogonUser = "Not found"
					LastActiveTime = "Not found"
					DistinguishedName = "Not found"
					CreationTime = "Not found"
					LastLogonDate = "Not found"
					DeviceAffinityUserNames = "Not found" 
					DeviceAffinityCreationTime = "Not found"
					Enabled = "Not found"
					OSVersion = "Not found"
				}

			} else {
				# $deviceAffinity = Get-CMUserDeviceAffinity -DeviceName $device | select UniqueUserName, ResourceName, CreationTime
				$deviceStatus = Get-ADComputer -filter "Name -like '$device*'" -Properties * | select name, description, enabled, DistinguishedName, Created, LastLogonDate, OperatingSystem
				$deviceCMDetails = Get-CMDevice -Name $device | select Username, LastActiveTime, CurrentLogonUser, LastLogonUser
				if ($deviceStatus -eq $null) {
					$deviceStatus =Get-ADComputer -Server "reg3" -filter "Name -like '$device*'" -Properties * | select name, description, enabled, DistinguishedName, Created, LastLogonDate, OperatingSystem
				}
				if ($deviceStatus -eq $null) {
					$deviceObj = [PSCustomObject]@{
						DeviceName = $device
						Description = "Not found"
						CurrentLogonUser = "Not found"
						LastLogonUser = "Not found"
						LastActiveTime = "Not found"
						DistinguishedName = "Not found"
						CreationTime = "Not found"
						LastLogonDate = "Not found"
						Enabled = "Not found"
						OSVersion = "Not found"
					}
				} else {
					$lastLogonNames = $(foreach($ll in $deviceCMDetails.LastLogonUser){if ($ll -eq $null) {"null"} else {$ll}})-join', '
					$currentLogonNames = $(foreach($cc in $deviceCMDetails.CurrentLogonUser){if ($cc -eq $null) {"null"} else {$cc}})-join', '
					$uniqueUserNames = $(foreach($uu in $deviceAffinity.UniqueUserName){if ($uu -eq $null) {"null"} else {$uu}})-join', '
					$lAT = $(foreach($at in $deviceCMDetails.LastActiveTime){if ($at -eq $null) {"null"} else {$at}})-join', '
					$deviceObj = [PSCustomObject]@{
						DeviceName = $device
						Description = $deviceStatus.description
						CurrentLogonUser = $currentLogonNames
						LastLogonUser = $lastLogonNames
						LastActiveTime = $lAT
						DistinguishedName = $deviceStatus.DistinguishedName
						CreationTime = $deviceStatus.Created
						LastLogonDate = $deviceStatus.LastLogonDate
						Enabled = $deviceStatus.enabled
						OSVersion = $deviceStatus.OperatingSystem
					}
				}
			}
			$deviceDetails += @($deviceObj)
			$count++
		}
    }

    End {
		$ts = (Get-Date -UFormat "%Y%m%d_") + (Get-Date -Format "%H%m") +  "_" + (Get-Random -Minimum 1000 -Maximum 9999)
		Write-Host "Exporting file as C:\Temp\DeviceDetails_$ts.csv"
		$deviceDetails | Export-CSV -Path "C:\Temp\DeviceDetails_$ts.csv" -NoTypeInformation
		pause
    }
}

# sepcial function for big CSV file
function GetUserDetailsSOP {
	[cmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$filepath
	)
	
	Process {
		# start of Bulk Op
		# get the number of rows in the CSV file
		$rowCount = 0; switch -File $filepath { default { ++$rowCount } }
		$i = 1
		$FileReader = [System.IO.File]::OpenText($filepath)
		$userObj = [system.collections.generic.list[pscustomobject]]::new()
		While ($FileLine = $FileReader.ReadLine()) {
			# progress bar setup
			$percentCompleted = ($i/$rowCount*100)
			$roundedPercent = [math]::Round($percentCompleted,1)
			# Write-Host "Working on row $i out of $rowCount"
			Write-Progress -Activity "Getting user information details... " -Status "$roundedPercent% Complete:" -PercentComplete $percentCompleted
			
			# process the headers first
			if ($i -eq 1) {
				# do nothing	
			} else {		
				# dump line to array
				$lineArray = $FileLine -split ','
				#col User Name should be column 2, array index 1
				$user = $lineArray[1]
				if (($user -eq $null) -or ($user -eq "")) {
					$userObj = [PSCustomObject]@{
						userName = "Empty cell"
						server = " - "
						userEmailAddress = " - "
						userTitle = " - "
						userDepartment = " - "
						userLastLogonDate = " - "
						userEnabled = " - "
						userCountry = " - "
					}		
				} else {
					$userADInfo = Get-ADUser -filter "SamAccountName -eq '$user'" -Properties * | select DistinguishedName, CanonicalName, EmailAddress, Title, LastLogonDate, Department,Enabled
					if ($userADInfo -eq $null) {
						$userADInfo = Get-ADUser -Server "reg3" -filter "SamAccountName -eq '$user'" -Properties * | select DistinguishedName,CanonicalName, EmailAddress, Title, LastLogonDate, Department, Enabled, OperatingSystem
					}
					if ($userADInfo -eq $null) {
						$userObj = [PSCustomObject]@{
							userName = $user
							server = "Not found"
							userEmailAddress = "Not found"
							userTitle = "Not found"
							userDepartment = "Not found"
							userLastLogonDate = "Not found"
							userEnabled = "Not found"
							userCountry = "Not found"
						}
					} else {
						$countryCode = $userADInfo.DistinguishedName.split(',')[1]
						if($countryCode -eq "OU=Account") {
							$countryCode = $userADInfo.DistinguishedName.split(',')[2]
						}
						$cL = $countryCode.length
						$country = $countryCode.substring(3,$cL-3)
						$server = $userADInfo.CanonicalName.substring(0,4)
						$userObj = [PSCustomObject]@{
							userName = $user
							server = $server
							userEmaiAddress = $userADInfo.EmailAddress
							userTitle = $userADInfo.Title
							userDepartment = $userADInfo.Department
							userLastLogonDate = $userADInfo.LastLogonDate
							userEnabled = $userADInfo.enabled
							userCountry = $country
						}
					}
				}
			}
			$userDetails += @($userObj)
			$i++
		}		
	}
	
	End {
		#timestamp for saving file
		$ts = (Get-Date -UFormat "%Y%m%d_") + (Get-Date -Format "%H%m") +  "_" + (Get-Random -Minimum 1000 -Maximum 9999)
		Write-Host "Exporting file as C:\Temp\UserDetails_$ts.csv"
		$userDetails | Export-CSV -Path "C:\Temp\UserDetails_$ts.csv" -NoTypeInformation
		$FileReader.Close()
		pause		
	}
}

function GetUserDetails {
    [cmdletBinding()] #adv
    param(
        [Parameter(Mandatory)][array]$users,
		[string]$csv
    )
    Begin {
    #setup 
		$userDetails = @()
    }

    Process {
    #main work
		$userObj = [system.collections.generic.list[pscustomobject]]::new()
		$hW = ""
		$count = 1
		$rowCount = $users.length
		$country = ""
		Write-Host ""
		Write-Host "Output process logs"
		Write-Host "*******************"
		foreach ($user in $users) {
			# progress bar
			$percentCompleted = ($count/$rowCount*100)
			$roundedPercent = [math]::Round($percentCompleted,1)
		    Write-Progress -Activity "Getting user information details... " -Status "$roundedPercent% Complete:" -PercentComplete $percentCompleted
			if (($user -eq $null) -or ($user -eq "")) {
				Write-Host "Empty entry at row $count"
				$userObj = [PSCustomObject]@{
					userName = "Empty entry at $count"
					server = "Not found"
					userEmailAddress = "Not found"
					userTitle = "Not found"
					userDepartment = "Not found"
					userLastLogonDate = "Not found"
					userEnabled = "Not found"
					userHWDetail = "Not found"
					userOS = "Not found"
					userCountry = "Not found"
				}				
			} else {
				$userADInfo =  Get-ADUser -filter "SamAccountName -eq '$user'" -Properties * | select DistinguishedName,CanonicalName, emailAddress, Title, LastLogonDate, Department,Enabled
				$userHWInfo = Get-CMUserDeviceAffinity -Username "reg1\$user" | select ResourceName
				if ($userADInfo -eq $null) {
					$userADInfo = Get-ADUser -Server "reg3" -filter "SamAccountName -eq '$user'" -Properties * | select DistinguishedName,CanonicalName, emailAddress, Title, LastLogonDate, Department, Enabled, OperatingSystem
					$userHWInfo = Get-CMUserDeviceAffinity -Username "reg3\$user" | select ResourceName
				}
				if ($userADInfo -eq $null) {
					$userObj = [PSCustomObject]@{
						userName = $user
						server = "Not found"
						userEmailAddress = "Not found"
						userTitle = "Not found"
						userDepartment = "Not found"
						userLastLogonDate = "Not found"
						userEnabled = "Not found"
						userHWDetail = "Not found"
						userOS = "Not found"
						userCountry = "Nopt found"
					}
				} else {
					# $hW = $(foreach($hh in $userHWInfo.ResourceName){if ($hh -eq $null) {"null"} else {$hh}})-join', '
					if($userHWInfo.ResourceName -eq $null) {
						$os = "No hardware details"
					} else {
						$os = getOS($userHWInfo.ResourceName)
					}
					# if($hW -Match ",") { $os = "Multiple hostname entries" } else { $os = getOS($hW)}
					#get country code
					$countryCode = $userADInfo.DistinguishedName.split(',')[1]
					if($countryCode -eq "OU=Account") {
						$countryCode = $userADInfo.DistinguishedName.split(',')[2]
					}					
					$cL = $countryCode.length
					$country = $countryCode.substring(3,$cL-3)
					$server = $userADInfo.CanonicalName.substring(0,4)
					$userObj = [PSCustomObject]@{
						userName = $user
						server = $server
						userEmaiAddress = $userADInfo.emailAddress
						userTitle = $userADInfo.Title
						userDepartment = $userADInfo.Department
						userLastLogonDate = $userADInfo.LastLogonDate
						userEnabled = $userADInfo.enabled
						userHWDetail = $hW
						userOS = $os
						userCountry = $country
					}
				}
			}
			$userDetails += @($userObj)
			$count++
		}	
    }

    End {
    #cleanup
		#timestamp for saving file
		$ts = (Get-Date -UFormat "%Y%m%d_") + (Get-Date -Format "%H%m") +  "_" + (Get-Random -Minimum 1000 -Maximum 9999)
		Write-Host "Exporting file as C:\Temp\UserDetails_$ts.csv"
		$userDetails | Export-CSV -Path "C:\Temp\UserDetails_$ts.csv" -NoTypeInformation
		pause
    }
}


function GetGroupDetails {
    [cmdletBinding()] #adv
    param(
        [Parameter(Mandatory)][array]$groups,
		[string]$csv
    )
    Begin {
    #setup 
		$groupDetails = @()
    }

    Process {
    #main work
		# if the numbers exceed 5000, can use this instead
		# Get-ADGroup '01UREG1EMMDYN_INTUNE_DEFAULT' -server reg1.1bank.dbs.com -Properties Member | Select-Object -ExpandProperty Member | Get-ADUser | Select name, Samaccountname
		$groupObj = [system.collections.generic.list[pscustomobject]]::new()
		foreach ($group in $groups) {
			# $membersArray = @()
			$members =  Get-ADGroup -filter "Name -like '$group*'" | Get-ADGroupMember | select name, SamAccountName				
			if ($members -eq $null) {
				$members =  Get-ADGroup -Server "reg3" -filter "Name -like '$group*'" | Get-ADGroupMember | select name, SamAccountName				
			}
			if ($members -eq $null) {
				$groupObj = [PSCustomObject]@{
					groupName = $group
					groupMemberDetail = "Not found"
				}
				$groupDetails += @($groupObj)
			} else {
				foreach ($member in $members.SamAccountName) {
					$groupObj = [PSCustomObject]@{
						groupName = $group
						groupMemberDetail = $member
					}
					$groupDetails += @($groupObj)
				}
			}
		}		
    }

    End {
    #cleanup
		$ts = (Get-Date -UFormat "%Y%m%d_") + (Get-Date -Format "%H%m") +  "_" + (Get-Random -Minimum 1000 -Maximum 9999)
		Write-Host "Exporting file as C:\Temp\GroupDetails_$ts.csv"
		$groupDetails | Export-CSV -Path "C:\Temp\GroupDe1tails_$ts.csv" -NoTypeInformation
		pause
    }
}

# Site configuration (setup retrieved from SCCM Powershell ISE)
$SiteCode = "SG1" # Site code 
$ProviderMachineName = "w01gsccmpss1a.reg1.1bank.dbs.com" # SMS Provider machine name
$initParams = @{}
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}
Set-Location "$($SiteCode):\" @initParams
# end of config

do {
	Clear-Host
	Write-Host "Information Retrieval System - IRS"
	Write-Host ""
	Write-Host "1. User Info (Manual input)"
	Write-Host "2. User Info (CSV file)"
	Write-Host "3. Hardware Info (Manual input)"
	Write-Host "4. Hardware Info (CSV file)"
	Write-Host "5. Group Info (Manual input)"
	Write-Host "6. Group Info (CSV file)"
	Write-Host "7. Special Bulk Op for Large CSV file"
	Write-Host "8. Exit"
	Write-Host ""
	$decision = Read-Host "Enter your choice"

	switch ($decision)
	{
		1 {
			$userArray = Read-Host "Enter 1BankIDs (e.g.) : id1,id2..."
			$splitUser = $userArray -split ','
			GetUserDetails @($splitUser)
		}
		2 {
			$fileGetPath = fileGet("./")
			$csvGet = Import-CSV -Path $fileGetPath
			GetUserDetails $csvGet."User Name"
		}
		3 {
			$hwArray = Read-Host "Enter Hostnames (e.g.) : hostname1,hostname2..."
			$splitHw = $hwArray -split ','
			GetHWDetails @($splitHw)
		}
		4 {
			$fileGetPath = fileGet("./")
			$csvGet = Import-CSV -Path $fileGetPath
			GetHWDetails $csvGet."NetBIOS Name"
		}
		5 {
			$groupArray = Read-Host "Enter Group Name (e.g.) : 01REG1_Test1, 01REG1_Test2..."
			$splitGrp = $groupArray -split ','
			GetGroupDetails @($splitGrp)
		}
		6 {
			$fileGetPath = fileGet("./")
			$csvGet = Import-CSV -Path $fileGetPath
			GetGroupDetails $csvGet."Group Name"
		}
		7 {
			$fileGetPath = fileGet("./")
			GetUserDetailsSOP $fileGetPath
		}
		8 {
			exit
		}
		Default {}
	}	
} until ($loop -eq "N") #neverending loop, the third option should exit the powershell
