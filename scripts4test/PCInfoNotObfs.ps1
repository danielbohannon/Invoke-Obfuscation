$ComputerHW = Get-WmiObject -Class Win32_ComputerSystem | select Manufacturer,Model | FT -AutoSize
$ComputerCPU = Get-WmiObject win32_processor | select DeviceID,Name | FT -AutoSize
$ComputerRam_Total = Get-WmiObject Win32_PhysicalMemoryArray| select MemoryDevices,MaxCapacity | FT -AutoSize
$ComputerRAM = Get-WmiObject Win32_PhysicalMemory | select DeviceLocator,Manufacturer,PartNumber,Capacity,Speed | FT -AutoSize
$ComputerDisks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | select DeviceID,VolumeName,Size,FreeSpace | FT -AutoSize
$ComputerDomain = Get-ADDomain | select DomainMode,Name,NetBIOSName,InfrastructureMaster | FT -AutoSize
$User = Get-ADUser -filter "SamAccountName -like `"$env:USERNAME`"" | select SID,DistinguishedName | FT -AutoSize
$RDS = (Get-ADDomain).ReplicaDirectoryServers
$testConnection = Test-Connection $RDS -Count 1
$ComputerOS = (Get-WmiObject Win32_OperatingSystem).Version
switch -Wildcard ($ComputerOS){
    "6.1.7600" {$OS = "Windows 7"; break}
    "6.1.7601" {$OS = "Windows 7 SP1"; break}
    "6.2.9200" {$OS = "Windows 8"; break}
    "6.3.9600" {$OS = "Windows 8.1"; break}
    "10.0.*" {$OS = "Windows 10"; break}
    default {$OS = "Unknown Operating System"; break}
   }
Write-Host "Computer Name: $Computer"
Write-Host "Operating System: $OS"
Write-Output $ComputerHW
Write-Output $ComputerCPU
Write-Output $ComputerRam_Total
Write-Output $ComputerRAM
Write-Output $ComputerDisks
Write-Output $ComputerDomain
Write-Output $User
Write-Host "Results of availabilyty of DC"
Write-Output ($testConnection | FT -AutoSize)
[string] $cmd = 'cmd /c calc'; Write-Verbose -Message $cmd; Invoke-Command -ScriptBlock ([ScriptBlock]::Create($cmd))