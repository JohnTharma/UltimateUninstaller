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

# get the CSV file to work on
$filepath = fileGet("./")
# get the number of rows in the CSV file
$rowCount = 0; switch -File $filepath { default { ++$rowCount } }
$i = 1
$FileReader = [System.IO.File]::OpenText($filepath)
cls
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
			}		
		} else {
			$userADInfo = Get-ADUser -filter "SamAccountName -eq '$user'" -Properties * | select CanonicalName, EmailAddress, Title, LastLogonDate, Department,Enabled
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
				}
			} else {
				$server = $userADInfo.CanonicalName.substring(0,4)
				$userObj = [PSCustomObject]@{
					userName = $user
					server = $server
					userEmaiAddress = $userADInfo.EmailAddress
					userTitle = $userADInfo.Title
					userDepartment = $userADInfo.Department
					userLastLogonDate = $userADInfo.LastLogonDate
					userEnabled = $userADInfo.enabled
				}
			}
		}
	}
	$userDetails += @($userObj)
	$i++
}
$FileReader.Close()
$saveFileName = fileSave
$userDetails | Out-GridView -PassThru -Title "Users" | Export-Csv -Path $saveFileName
