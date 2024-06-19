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
		foreach ($device in $devices) {
			$deviceAffinity = Get-CMUserDeviceAffinity -DeviceName $device | select UniqueUserName, ResourceName, CreationTime
			$deviceStatus = Get-ADComputer -filter "Name -eq '$device'" -Properties * | select name, description, enabled, DistinguishedName, Created, LastLogonDate
			$deviceCMDetails = Get-CMDevice -Name $device | select Username, LastActiveTime, CurrentLogonUser, LastLogonUser
			if ($deviceStatus -eq $null) {
				$deviceStatus =Get-ADComputer -Server "reg3" -filter "Name -eq '$device'" -Properties * | select name, description, enabled, DistinguishedName, Created, LastLogonDate
			}
			if ($deviceStatus -eq $null) {
				$deviceObj = [PSCustomObject]@{
					"Device Name" = $device
					"Description" = "Not found"
					"Current Logon User" = "Not found"
					"Last Logon User" = "Not found"
					"Last Active Time" = "Not found"
					"Distinguished Name" = "Not found"
					"Creation Time" = "Not found"
					"Last Logon Date" = "Not found"
					"Device Affinity User Names" = "Not found" 
					"Device Affinity Creation Time" = "Not found"
					"Enabled" = "Not found"
				}
			} else {
				$deviceObj = [PSCustomObject]@{
					"Device Name" = $device
					"Description" = $deviceStatus.description
					"Current Logon User" = $deviceCMDetails.CurrentLogonUser
					"Last Logon User" = $deviceCMDetails.LastLogonUser
					"Last Active Time" = $deviceCMDetails.LastActiveTime
					"Distinguished Name" = $deviceStatus.DistinguishedName
					"Creation Time" = $deviceStatus.Created
					"Last Logon Date" = $deviceStatus.LastLogonDate
					"Device Affinity User Names" = $deviceAffinity.UniqueUserName 
					"Device Affinity Creation Time" = $deviceAffinity.CreationTime
					"Enabled" = $deviceStatus.enabled
				}
			}
			$deviceDetails += @($deviceObj)
		}
    }

    End {
    #cleanup
		if ($csv -eq "Y") {
			$ts = Get-Date -UFormat "%Y%m%d_%H%m"
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
		foreach ($user in $users) {
			$userADInfo =  Get-ADUser -filter "SamAccountName -eq '$user'" -Properties * | select CanonicalName, emailAddress, Title, Department, LastLogonDate, Enabled
			$userHWInfo = Get-CMUserDeviceAffinity -Username "reg1\$user" | select ResourceName
			if ($userADInfo -eq $null) {
				$userADInfo = Get-ADUser -Server "reg3" -filter "SamAccountName -eq '$user'" -Properties * | select CanonicalName, emailAddress, Title, Department, LastLogonDate, Enabled
				$userHWInfo = Get-CMUserDeviceAffinity -Username "reg3\$user" | select ResourceName
			}
			if ($userADInfo -eq $null) {
				$userObj = [PSCustomObject]@{
					"User Name" = $user
					"Server" = "Not found"
					"Email Address" = "Not found"
					"Title" = "Not found"
					"Department" = "Not found"
					"Last Logon Date" = "Not found"
					"Enabled" = "Not found"
					"Hostname Detail" = "Not found"
				}
			} else {
				$userObj = [PSCustomObject]@{
					"User Name" = $user
					"Server" = $userADInfo.CanonicalName.substring(0,4)
					"Email Address" = $userADInfo.emailAddress
					"Title" = $userADInfo.Title
					"Department" = $userADInfo.Department
					"Last Logon Date" = $userADInfo.LastLogonDate
					"Enabled" = $userADInfo.enabled
					"Hostname Detail" = $userHWInfo.ResourceName

				}
			}
			$userDetails += @($userObj)
		}	
    }

    End {
    #cleanup
		if ($csv -eq "Y") {
			$ts = Get-Date -UFormat "%Y%m%d_%H%m"
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
			$members =  Get-ADGroup -filter "Name -eq '$group'" | Get-ADGroupMember | select name, SamAccountName				
			if ($members -eq $null) {
				$members =  Get-ADGroup -Server "reg3" -filter "Name -eq '$group'" | Get-ADGroupMember | select name, SamAccountName				
			}
			if ($members -eq $null) {
				$groupObj = [PSCustomObject]@{
					"Group Name" = $group
					"Member Detail" = "Not found"
				}
				$groupDetails += @($groupObj)
			} else {
				foreach ($member in $members.SamAccountName) {
					$groupObj = [PSCustomObject]@{
						"Group Name" = $group
						"Member Detail" = $member
					}
					$groupDetails += @($groupObj)
				}
			}
		}		
    }

    End {
    #cleanup
		if ($csv -eq "Y") {
			$ts = Get-Date -UFormat "%Y%m%d_%H%m"
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
	# $choices  = '&User Info','&Hardware Info'
	$title    = '==== Information Retrieval Script (version 0.1c) ===='
	$question = 'What information do you want to retrieve?'
	$Choices = @(
		[System.Management.Automation.Host.ChoiceDescription]::new("&User Info", "Get information for user (1BankId)")
		[System.Management.Automation.Host.ChoiceDescription]::new("&Hardware Info", "Get information for hardware (hostname)")
		[System.Management.Automation.Host.ChoiceDescription]::new("&Group Info", "Get information for group (groupname)")
		[System.Management.Automation.Host.ChoiceDescription]::new("&Exit", "Exit Powershell")
	)
	$decision = $Host.UI.PromptForChoice($title, $question, $Choices, 1)

	switch ($decision)
	{
		0 {
			$userArray = Read-Host "Enter 1BankIDs (e.g.) : id1,id2..."
			$outputCSV = Read-Host "Output to CSV? N/Y"
			cls			
			Write-Host("======= Processing User(s) Details =======")
			$splitUser = $userArray -split ','
			GetUserDetails @($splitUser) $outputCSV
			Pause
			cls
		}
		1 {
			$hwArray = Read-Host "Enter Hostnames (e.g.) : hostname1,hostname2..."
			$outputCSV = Read-Host "Output to CSV? N/Y" 
			cls			
			Write-Host("======= Processing Hostname(s) Details =======")
			$splitHw = $hwArray -split ','
			GetHWDetails @($splitHw) $outputCSV
			Pause
			cls
		}
		2 {
			$groupArray = Read-Host "Enter Group Name (e.g.) : 01REG1_Test1, 01REG1_Test2..."
			$outputCSV = Read-Host "Output to CSV? N/Y"
			cls			
			Write-Host("======= Processing Group(s) Details =======")
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
