@"
 ____                         _             _ _ _   
|  _ \ _____      _____ _ __ / \  _   _  __| (_) |_ 
| |_) / _ \ \ /\ / / _ \ '__/ _ \| | | |/ _` | | __|
|  __/ (_) \ V  V /  __/ | / ___ \ |_| | (_| | | |_ 
|_|   \___/ \_/\_/ \___|_|/_/   \_\__,_|\__,_|_|\__|v0.2.1


"@
 

#-------------------------------------------- Warning messagebox ---------------------------------------------

Add-Type -AssemblyName PresentationFramework # loa the assemply .NET framework (to make the script able to create a message box interface)
$messageBoxText = "This script will collect some hardware and software information (such as your components, your disk space and your OS version).`nIf you don't want this, you can cancel the execution.`nExecute anyway ?"
$caption = "Warning"
$button = [System.Windows.MessageBoxButton]::OKCancel
$icon = [System.Windows.MessageBoxImage]::Information
$bytes = [System.Text.Encoding]::Default.GetBytes($messageBoxText)
$textUtf8 = [System.Text.Encoding]::UTF8.GetString($bytes)
$bytes = [System.Text.Encoding]::Default.GetBytes($caption)
$captionUtf8 = [System.Text.Encoding]::UTF8.GetString($bytes)

$result = [System.Windows.MessageBox]::Show($textUtf8, $captionUtf8, $button, $icon) # Mixing all components

if ($result -eq "OK") {# If user clicked "OK"
    # User accepted
} else {
    # User declined, canceling the script
    exit
}

#-------------------------------------------- Progress-bar definition ---------------------------------------------

#$TotalSteps = 100 

#function Show-CustomProgressBar {
#    param (
#        [int]$CurrentStep,
#        [int]$TotalSteps
#    )
    
#    $ProgressWidth = 50 
#    $ProgressBar = [string]::Join('', ('|' * [math]::Round(($CurrentStep / $TotalSteps) * $ProgressWidth)))
    
#    Write-Host -NoNewline "`r[$ProgressBar] $([math]::Round(($CurrentStep / $TotalSteps) * 100))%"

#    if ($CurrentStep -eq $TotalSteps) {
#        Write-Host ""  
#    }
#}

#Show-CustomProgressBar -CurrentStep <percentage> -TotalSteps $TotalSteps

#----------------------------------------------- Folder creation ------------------------------------------------

$folderName = "Client-apps" #Defining the destination folder name

if([System.IO.Directory]::Exists($folderName)) #If the folder exists
{
 #Folder exists :shocked_face:
}
else{ #Else
    New-Item $folderName -ItemType Directory | Out-Null #Creating the folder silently
}

#-------------------------------------------- Defining file names ----------------------------------------------

$userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
 
$fileName = "results.csv"
$fileName2 = "Applications-" + $userName + ".csv"

#-------------------------------------------- Full installed software list ---------------------------------------------

$appsList = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                  HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                  Select-Object DisplayName, DisplayVersion, Publisher |
                  Where-Object { $_.DisplayName -ne $null } |
                  Sort-Object DisplayName

#---------------------------------------------- Defining objects -----------------------------------------------

$diskInfo = Get-PhysicalDisk | Where-Object { $_.DriveType -ne 'Removable' -and $_.DriveType -ne 'CD-ROM' -and $_.BusType -ne 'USB'} #Get the disk type and his RPM (if it's HDD) 
    $diskType = ($diskInfo | ForEach-Object { $_.MediaType}) -join ', ' # Put , separator between disks
    $diskModel = ($diskInfo | ForEach-Object { $_.Model}) -join ', ' # Put , separator between disks

$systemInfo = Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory, Domain # Obtain PC specs

$osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture, CSName # Obtain OS informations
    $systemMemory = [math]::Round($systemInfo.TotalPhysicalMemory / 1GB, 2)
        $systemMemoryRounded = [math]::Ceiling($systemMemory)
            $systemMemoryGB = "$systemMemoryRounded GB"

$SN = Get-CimInstance Win32_BIOS | Select-Object SerialNumber # Obtain the computer S/N

$processorInfo = Get-CimInstance Win32_Processor | Select-Object Name, MaxClockSpeed # Obtain CPU name and max clock speed
 
$gpuInfo = Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name } # Obtain GPU model
    $gpuList = $gpuInfo -join ', '

$currentDate = Get-Date -Format "yyyy-MM-dd" # Obtain the date


$encryptionStatus = manage-bde -status C: | Out-String #Check if your computer is encrypted by BitLocker
    $isEncrypted = if ($encryptionStatus -match "Protection On") { "Yes" } else { "No" } # Write "Yes" or "No"


$totalSpace = Get-Volume | Where-Object { $_.DriveType -ne 'Removable' -and $_.DriveType -ne 'CD-ROM' -and $_.BusType -ne 'USB'}  # Get the total volume ingore USB, Removable and CD-ROM devices
    $totalSpace2 = ($totalSpace | Measure-Object -Property Size -Sum).Sum / 1GB
        $totalSpaceGo = [math]::Round($totalSpace2, 2)
    $totalFreeSpace = ($totalSpace | Measure-Object -Property SizeRemaining -Sum).Sum / 1GB # Measure the free space
        $totalFreeSpaceGo = [math]::Round($totalFreeSpace, 2) # Divide the free space (in MB) to get in in GB

#----------------------------------------------- Finding office licence ------------------------------------------------

$365 = $appsList | Where-Object { $_.DisplayName -like "*365*"} # $365 take the name of 365 software
$office = $appsList | Where-Object {$_.DisplayName -like "*Office*"} # $office take the name of Office software

if ($365) { 
    $365 =  if ($365 -match '=([^;]+)') { $matches[1] } else { $null } # Cut the text to only get the software version
    $officeVersion = $365
} if ($office) {
    $office = if($office -match '=([^;]+)') {$matches[1]} else {$null} # Cut the text to only get the software version
    $officeVersion = $office
} else {
    Write-Host "No Office version found."
}

#-------------------------------------------- Searching a specific software ---------------------------------------------

#$specificSoftware = "Your Sofware Name" # Define the software to research
#$softwareVersion = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, # Checking the \Uninstall folder
#                                   HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
#                   Where-Object { $_.DisplayName -like "*$specificSoftware*" } | # Searching for your software
#                   Select-Object -ExpandProperty DisplayVersion -First 1 # Get the sofware version

 
#------------------------------------------------- Creating global tab --------------------------------------------------

$combinedData = [PSCustomObject]@{
    "Username" = $userName
    "Model" = $systemInfo.Model
    "Manufacturer" = $systemInfo.Manufacturer
    "S/N" = $SN.SerialNumber
    "Computer name" = $osInfo.CSName
    "CPU" = $processorInfo.Name
    "Frequency" = ($processorInfo.MaxClockSpeed /1000).ToString() + " GHz"
    "GPU" = $gpuList
    "RAM" = $systemMemoryGB
    "Total disk space" = "$totalSpaceGo GB"
    "Total free space" = "$totalFreeSpaceGo GB"
    "Disks type" = $diskType
    "Disks model" = $diskModel
    "OS" = $osInfo.Caption
    "Version" = $osInfo.Version
    "Architecture" = $osInfo.OSArchitecture
    "Domain" = $systemInfo.Domain
    "Office version" = $officeVersion
#    "Specific software" = $softwareVersion
    "BitLocker encryption" = $isEncrypted
    "Scan date" = $currentDate
}

#----------------------------------------------- Exporting all CSV files ------------------------------------------------

$combinedData | Export-Csv -Path $fileName -Delimiter ";" -Append -NoTypeInformation
$appsList | Export-Csv -Path "$folderName\$fileName2" -Delimiter ";" -Append -NoTypeInformation