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
		$uniqueUserNames = ""
		$currentLogonNames = ""
		$lastLogonNames = ""
		$lAT = ""
		foreach ($device in $devices) {
			$deviceAffinity = Get-CMUserDeviceAffinity -DeviceName $device | select UniqueUserName, ResourceName, CreationTime
			$deviceStatus = Get-ADComputer -filter "Name -like '$device*'" -Properties * | select name, description, enabled, DistinguishedName, Created, LastLogonDate
			$deviceCMDetails = Get-CMDevice -Name $device | select Username, LastActiveTime, CurrentLogonUser, LastLogonUser
			if ($deviceStatus -eq $null) {
				$deviceStatus =Get-ADComputer -Server "reg3" -filter "Name -like '$device*'" -Properties * | select name, description, enabled, DistinguishedName, Created, LastLogonDate
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
					DeviceAffinityUserNames = "Not found" 
					DeviceAffinityCreationTime = "Not found"
					Enabled = "Not found"
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
					DeviceAffinityUserNames = $uniqueUserNames 
					DeviceAffinityCreationTime = $deviceAffinity.CreationTime
					Enabled = $deviceStatus.enabled
				}
			}
			$deviceDetails += @($deviceObj)
		}
    }

    End {
    #cleanup
		if ($csv -eq "Y") {
			$ts = (Get-Date -UFormat "%Y%m%d_") + (Get-Date -Format "%H%m") +  "_" + (Get-Random -Minimum 1000 -Maximum 9999)
			Write-Host $ts
			$deviceDetails | Export-CSV -Path "C:\Temp\Hostnames_$ts.csv"
			Write-Host "==========================================================="
			Write-Host "CSV file output : C:\Temp\Hostnames__$ts.csv"
			Write-Host "==========================================================="
		} else {			
			$deviceDetails
		}
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
		$hW = ""
		foreach ($user in $users) {
			$userADInfo =  Get-ADUser -filter "SamAccountName -eq '$user'" -Properties * | select CanonicalName, emailAddress, Title, LastLogonDate, Department,Enabled
			$userHWInfo = Get-CMUserDeviceAffinity -Username "reg1\$user" | select ResourceName
			if ($userADInfo -eq $null) {
				$userADInfo = Get-ADUser -Server "reg3" -filter "SamAccountName -eq '$user'" -Properties * | select DistinguishedName,CanonicalName, emailAddress, Title, LastLogonDate, Department, Enabled
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
				}
			} else {
				$hW = $(foreach($hh in $userHWInfo.ResourceName){if ($hh -eq $null) {"null"} else {$hh}})-join', '
				$userObj = [PSCustomObject]@{
					userName = $user
					server = $userADInfo.CanonicalName.substring(0,4)
					userEmaiAddress = $userADInfo.emailAddress
					userTitle = $userADInfo.Title
					userDepartment = $userADInfo.Department
					userLastLogonDate = $userADInfo.LastLogonDate
					userEnabled = $userADInfo.enabled
					userHWDetail = $hW
				}
			}
			$userDetails += @($userObj)
		}	
    }

    End {
    #cleanup
		if ($csv -eq "Y") {
			$ts = (Get-Date -UFormat "%Y%m%d_") + (Get-Date -Format "%H%m") +  "_" + (Get-Random -Minimum 1000 -Maximum 9999)
			$userDetails | Export-CSV -Path "C:\Temp\Users_$ts.csv"
			Write-Host "==========================================================="
			Write-Host "CSV file output : C:\Temp\Users_$ts.csv"
			Write-Host "==========================================================="			
		} else {
			$userDetails
		}
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
		if ($csv -eq "Y") {
			$ts = (Get-Date -UFormat "%Y%m%d_") + (Get-Date -Format "%H%m") +  "_" + (Get-Random -Minimum 1000 -Maximum 9999)
			$groupDetails | Export-CSV -Path "C:\Temp\Groups_$ts.csv"
			Write-Host "==========================================================="
			Write-Host "CSV file output : C:\Temp\Groups_$ts.csv"
			Write-Host "==========================================================="			
		} else {
			$groupDetails
		}
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
	$choices  = '&User Info','&Hardware Info'
	$title    = 'Information Retrieval'
	$question = 'What information do you want to retrieve?'
	$Choices = @(
		[System.Management.Automation.Host.ChoiceDescription]::new("&User Info", "Get information for user (1BankId)")
		[System.Management.Automation.Host.ChoiceDescription]::new("&Hardware Info", "Get information for hardware (hostname)")
		[System.Management.Automation.Host.ChoiceDescription]::new("&Group Info", "Get information for group (groupname)")
		[System.Management.Automation.Host.ChoiceDescription]::new("&Exit", "Exit Powershell")
	)
	$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)

	switch ($decision)
	{
		0 {
			$userArray = Read-Host "Enter 1BankIDs (e.g.) : id1,id2..."
			$outputCSV = Read-Host "Output to CSV? N/Y" 
			$splitUser = $userArray -split ','
			GetUserDetails @($splitUser) $outputCSV
			Pause
			cls
		}
		1 {
			$hwArray = Read-Host "Enter Hostnames (e.g.) : hostname1,hostname2..."
			$outputCSV = Read-Host "Output to CSV? N/Y" 
			$splitHw = $hwArray -split ','
			GetHWDetails @($splitHw) $outputCSV
			Pause
			cls
		}
		2 {
			$groupArray = Read-Host "Enter Group Name (e.g.) : 01REG1_Test1, 01REG1_Test2..."
			$outputCSV = Read-Host "Output to CSV? N/Y" 
			$splitGrp = $groupArray -split ','
			GetGroupDetails @($splitGrp) $outputCSV
			Pause
			cls
		}
		3 {
			exit
		}
		Default {}
	}	
} until ($loop -eq "N") #neverending loop, the third option should exit the powershell
