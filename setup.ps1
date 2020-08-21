$host.UI.RawUI.WindowTitle = "Security-App Setup"

Write-Host -ForegroundColor Yellow "[INFO] `t Creating direcories."
New-item -ItemType Directory -Path $PSScriptRoot -Name "_code"
New-item -ItemType Directory -Path $PSScriptRoot -Name "_data"
Write-Host -ForegroundColor Yellow "[OK] `t Done creating direcories."
"`n"
Write-Host -ForegroundColor Yellow "[INFO] `t Creating config files."
$settingsINI = @("[Settings]","SettingSet=0","[Admin Settings]","DomainAdminGroup=UoO/0Do4t96SGbUpgMqB8w==","[Log Path]","LogPath=vGFgscE8CRCXYqC4+Cp3WQ==")
$credentailINI = @("[ADM]","ADMUsername=tMqniQcteZlNkxYQ++MApQ==","ADMPassword=tMqniQcteZlNkxYQ++MApQ==","[Standard User]","Username=a9NYndtdxI3149R19HS1xA==","Password=PTy/K/fLjtK9biwekjdDYg==")
Set-Content -Path "$PSScriptRoot\_data\settings.ini" -Value $settingsINI
Set-Content -Path "$PSScriptRoot\_data\credentail.ini" -Value $credentailINI
Write-Host -ForegroundColor Yellow "[OK] `t Done creating configs."
"`n"
## pre requiments Block

$preRequiments = @'

    $proxyset = Get-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    if($proxyset.proxyEnable -eq 1)
    {
    Write-Host "Proxy is enabled, please provide some info." -ForegroundColor Cyan
    $pAddress = Read-Host "Proxy Address"
    $pPort = Read-Host "Proxy Port"
    Write-Host -ForegroundColor Yellow "[INFO] `t Creating config."
    $parentPath = (get-item $PSScriptRoot).parent.FullName
    $pAddress | Out-File $parentPath\_data\proxy.conf
    $pPort | Out-File $parentPath\_data\proxy.conf -Append
    Write-Host -ForegroundColor Green "[OK] `t Done creating config."
    
    ## Set Proxy
    [system.net.webrequest]::defaultwebproxy = new-object system.net.webproxy('http://pAddress:pPort')
    [system.net.webrequest]::defaultwebproxy.credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    [system.net.webrequest]::defaultwebproxy.BypassProxyOnLocal = $true
    
    }
    if($true))
        {
        ## Install Choco
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }
'@

## PowerShell block

$setupPS = @'
Function Check-PS-RL {
    $Modules = (Get-Module -ListAvailable).Name
    if($Modules -contains "PSReadLine")
        {
        
        return $true
        
        }
    else
        {
        
        return $false
    
        }
    }
    
    if((Check-PS-RL) -eq $False)
        {
            $parentPath = (get-item $PSScriptRoot).parent.FullName 
            if(Test-Path -Path "$parentPath\_data\proxy.conf")
            {
                $proxy = Get-Content $PSScriptRoot\proxy.conf
                $pAddress= $proxy[0]
                $pPort = $proxy[1]
                ## setup Proxy
                [system.net.webrequest]::defaultwebproxy = new-object system.net.webproxy('http://$pAddress:$pPort')
                [system.net.webrequest]::defaultwebproxy.credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
                [system.net.webrequest]::defaultwebproxy.BypassProxyOnLocal = $true
                ## install PSReadLine
                Install-Module -Name PSReadLine -Scope CurrentUser -Force
            }
            else
            {
                ## install PSReadLine
                Install-Module -Name PSReadLine -Scope CurrentUser -Force  
            }
        }
'@

## Active Directory block

$setupAD= @'
$OSName=(Get-WmiObject Win32_OperatingSystem).Name
$OSName=$OSName.Substring(0,$OSName.IndexOf('|'))
Write-Host -ForegroundColor Cyan "$OSName detected."
$title    = 'AD install'
$question = 'Are you sure you want to proceed?'
$choices  = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    Write-Host -ForegroundColor Green 'confirmed'
    $install = $true
} else {
    Write-Host -ForegroundColor Red 'cancelled'
    $install=$false
}

if($install)
{
    if("Microsoft Windwos 10" -Match $OSName){
        #Install RSAT
        if((Get-Item DISM.exe)){
            DISM.exe /Online /Add-Capability /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
        }
    }
    else{
        Install-WindowsFeature (Get-WindowsFeature -Name "RSAT")
    }    
}
'@

$setupCMD = @'
choco install clink -y
'@

## Set content of files
Set-Content -Path "$PSScriptRoot\_code\preRequimentsS.ps1" -Value $preRequiments -Encoding utf8BOM
Set-Content -Path "$PSScriptRoot\_code\setupPS.ps1" -Value $setupPS -Encoding utf8BOM
Set-Content -Path "$PSScriptRoot\_code\setupAD.ps1" -Value $setupAD -Encoding utf8BOM
Set-Content -Path "$PSScriptRoot\_code\setupCMD.ps1" -Value $setupCMD -Encoding utf8BOM

try{
    $testchoco = Test-Path -Path C:\ProgramData\chocolatey
    if(!$testchoco){
    Write-Host -ForegroundColor Yellow "[INFO] `t Starting Chocolatey setup."
    Powershell.exe -noprofile -File "$PSScriptRoot\_code\preRequiments.ps1"
    Write-Host -ForegroundColor Green "[OK] `t Chocolatey installed"
    }
    "`n"
    Write-Host -ForegroundColor Yellow "[INFO] `t Starting PowerShell setup."
    Powershell.exe -noprofile -File "$PSScriptRoot\_code\SetupPS.ps1"
    Write-Host -ForegroundColor Green "[OK] `t Setup of PowerShell is complete."
    "`n"
    Write-Host -ForegroundColor Yellow "[INFO] `t Starting Acttive Directory setup."
    Powershell.exe -noprofile -File "$PSScriptRoot\_code\SetupAD.ps1"
    Write-Host -ForegroundColor Green "[OK] `t Setup of Active Directory is complete."
    "`n"
    Write-Host -ForegroundColor Yellow "[INFO] `t Starting CMD setup."
    Start-Process cmd.exe -argumentList 'cmd.exe /c "$PSScriptRoot\_code\SetupCMD.Bat"' -Wait -PassThru -NoNewWindow
    Start-Sleep -sec 3
    Start-Process cmd.exe -argumentList '/c exit' -Wait -PassThru -NoNewWindow
    $User = $env:UserName
    $parentPath = (get-item $PSScriptRoot).parent.FullName
    Copy-Item -Path "$parentPath\0_data\settings" -Destination "C:\Users\$user\AppData\Local\clink"
    Start-Sleep -sec 3
    $prevContennt = Get-Content "C:\Users\$user\AppData\Local\clink"
    $newContent = $prevContennt -replace "history_io = 0", "history_io = 1"
    $newContent | Set-Content "C:\Users\$user\AppData\Local\clink"
    Write-Host -ForegroundColor Green "[OK] `t Setup of CMD is complete."
}catch{$_.Exception.Message}
## Cleanup
Start-Sleep -Seconds 2
Remove-item -Path "$PSScriptRoot\_code\preRequiments.ps1"
Remove-item -Path "$PSScriptRoot\_code\SetupAD.ps1"
Remove-item -Path "$PSScriptRoot\_code\SetupCMD.Bat"
Remove-item -Path "$PSScriptRoot\_code\SetupPS.ps1"
