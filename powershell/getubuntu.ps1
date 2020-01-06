Write-Host "Ubuntu ISO Downloader for Desktop x64 architectures`n"

<# Setting the directory on which the file will be downloaded #>

$Directory_Path = "$Home\Desktop"

<# Information to the user about what this script does and about the funtions of it#>
Write-Host "This Script will download a specific version of Ubuntu 64bit for Desktop.`n"
Write-Host "You have the ability to change the download directory of the ISO.`n"
Write-Host "The current download directory is set to $Directory_Path"

<# Asking the user if he wants to change the directory #>

$directory_input = Read-Host -prompt "Do you want to change the directory for the Ubuntu download? (Y,N)"
if ($directory_input -match "[yY]") {

<#Getting the information of where the user wished to save the downloaded Ubuntu ISO#>
<#Creates the users desired location and in case it exists already i sent out a message to the screen notifying the user that the directory already exists and the script will be saved on that one#>

    $user_download_location = Read-Host -prompt "Enter your desired directory name for the download"
    if (-not (Test-Path $user_download_location))  {
        Write-Host "Creating Folder $user_download_location"
        New-Item -ItemType Directory -Path $user_download_location 
        Write-Host "Created Folder  $user_download_location"
        $Directory_Path = $user_download_location
 
    }
    else {

        Write-Host "Folder $user_download_location already exists."
        $Directory_Path = $user_download_location

    }

}

else {

<# the script continues if the user does not want to change directory with the default directory again with the message if the default directory exists. if it doesnt the script creates it and saved the ISO there #>

    if (-not (Test-Path $Directory_Path)) {

        Write-Host "Creating Folder $Directory_Path"
        New-Item -ItemType Directory -Path $Directory_Path
        Write-Host "Created Folder $Directory_Path"

    }
 
    else {
        Write-Host "Folder $Directory_Path already exists."

    }
} 

<# This function is fetching all the available versions from ubuntu website and sorts them in a menu from which the user can select which version wishes to download.#>

function Ubuntu_Versions()
{

    Write-Host "Fetching available Ubuntu versions and building menu. Please wait...`n"
    $parsehtml = Invoke-WebRequest -Uri 'http://releases.ubuntu.com/' -UseBasicParsing
    $available_ubuntu_versions = $parsehtml.Links.href | ForEach-Object{[regex]::Matches($_,"(\d+\.\d+\.\d)|(\d+\.\d+)")} | Select-Object value
    [int]$count = 0
    $ISO_ubuntu_versions = @()

<# This statement takes every version fetched by web Request that matched the criteria of the regex and puts them on a menu#>

    foreach ($h in $available_ubuntu_versions)
    {
        $count++
        $ISO_ubuntu_versions += $("[ $count ]: Ubuntu Desktop " + $h.Value + " 64bit")
    }
        
<# The results are being printed on the screen where the user is able to choose which one he want to be downloaded #>

    [int]$User_Input = 0
    while ($User_Input -lt 1 -or $User_Input -gt $available_ubuntu_versions.Count+1)
    {
        Write-Host "_________________________________________________"
        Write-Host "The following versions of Ubuntu are available:`n"
        $ISO_ubuntu_versions
        Write-host "[ $($available_ubuntu_versions.Count+1) ]: Exit"
        Write-Host "_________________________________________________"
        [Int]$User_Input = Read-Host "`nPlease enter a choice number from 1 to $($available_ubuntu_versions.Count+1)..." 
    }

<# if the user inputs a wrong choice the script will halt and go back until the user inputs a correct value #>

    if($User_Input -eq $($available_ubuntu_versions.Count+1) )
    {
        break
    }
    else 
    {
        Get_Directory_Link $User_Input
    }
}

<# this funtion is set to get the correct link for the specific version the user chose. #>

function Get_Directory_Link() {
    <#[CmdletBinding()]
    param(
    [Parameter(Mandatory=$True,ValueFromPipeline=$False)]
    [int]$Choice = 0
    )#>
    #Write-Host $Choice, $available_ubuntu_versions, $ISO_ubuntu_versions
    Write-host $ISO_ubuntu_versions[$($Choice-1)].Replace('Enter','You have selected')
    [string]$hersionToDownload = $($available_ubuntu_versions[$($Choice-1)]).Value
    [string]$dl_file = "ubuntu-$hersionToDownload-desktop-amd64"+".iso"
    [string]$download_location = "http://releases.ubuntu.com/$hersionToDownload/"
    [string]$downloadURL = $download_location + $dl_file
    [string]$savedfile = Join-Path -Path $Directory_Path -ChildPath $dl_file
    DownloadISO -SourceUrl $downloadURL -SaveAsPath $savedfile
}

<# the use of this funtion is to start the bits transfer and start the download after the user accepts it #>

function DownloadISO(){
[CmdletBinding()]
    param(
    [Parameter(Mandatory=$True,ValueFromPipeline=$False)]
    [string]$SourceUrl,
    [string]$SaveAsPath
    )

    $confirm_download = Read-Host "`nDo you want to proceed with the download? (Y,N)"
    if ($confirm_download -match "[yY]") {
        Write-Host "`nInitiating Download"
        Start-BitsTransfer -Source $SourceUrl -Destination $SaveAsPath -Asynchronous -Priority Normal -RetryTimeout 60 -RetryInterval 120 -DisplayName "UbuntuDownload"
        $bits = Get-BitsTransfer -Name "UbuntuDownload"
        $pct = 0
        while ($bits.JobState -ne "Transferred" -and $pct -ne 100){
            if ($bits.jobstate -eq "Error" -or $bits.JobState -eq "TransientError" )
            {
                Resume-BitsTransfer -BitsJob $bits
            }
        }
        Complete-BitsTransfer -BitsJob $bits | Out-Null
    }
    else
    {
        Write-Host "`nThe download of the Ubuntu ISO will not start. The script will exit."
        exit
    }

}

Ubuntu_Versions
