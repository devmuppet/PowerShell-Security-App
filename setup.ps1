$host.UI.RawUI.WindowTitle = "Security-App Setup"

[string]$Root = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])


Write-Host -ForegroundColor Yellow "[INFO] `t Creating direcories."
New-item -ItemType Directory -Path $Root -Name "_code"
New-item -ItemType Directory -Path $Root -Name "_data"
Write-Host -ForegroundColor Green "[OK] `t Done creating direcories."
"`n"
Write-Host -ForegroundColor Yellow "[INFO] `t Creating config files."
$settingsINI = @("[Settings]","SettingSet=0","[Admin Settings]","DomainAdminGroup=oCzHYDIz4djPYXxxeSzgeg==","[Log Path]","LogPath=sLP+UVLn0MRezZcommYnow==")
$credentailINI = @("[ADM]","ADMUsername=iBoqEsvutYcWZWX89wn6/g==","ADMPassword=iBoqEsvutYcWZWX89wn6/g==","[Standard User]","Username=Yp9unjM+/EXAqmZsFoTZKQ==","Password=S4DxHDx53kCqtJOn4t95zg==")
Set-Content -Path "$Root\_data\settings.ini" -Value $settingsINI
Set-Content -Path "$Root\_data\credential.ini" -Value $credentailINI
Write-Host -ForegroundColor Green "[OK] `t Done creating configs."
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
    $parentPath = (get-item $Root).parent.FullName
    $pAddress | Out-File $parentPath\_data\proxy.conf
    $pPort | Out-File $parentPath\_data\proxy.conf -Append
    Write-Host -ForegroundColor Green "[OK] `t Done creating config."
    
    ## Set Proxy
    [system.net.webrequest]::defaultwebproxy = new-object system.net.webproxy('http://pAddress:pPort')
    [system.net.webrequest]::defaultwebproxy.credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    [system.net.webrequest]::defaultwebproxy.BypassProxyOnLocal = $true
    
    }
    if($true)
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
            $parentPath = (get-item $Root).parent.FullName 
            if(Test-Path -Path "$parentPath\_data\proxy.conf")
            {
                $proxy = Get-Content $Root\proxy.conf
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

$ClinkSettings = @'
# name: Pressing Ctrl-D exits session
# type: bool
# Ctrl-D exits cmd.exe when it is pressed on an empty line.
ctrld_exits = 1

# name: Toggle if pressing Esc clears line
# type: bool
# Clink clears the current line when Esc is pressed (unless Readline's Vi mode
# is enabled).
esc_clears_line = 1

# name: Match display colour
# type: int
# Colour to use when displaying matches. A value less than 0 will be the
# opposite brightness of the default colour.
match_colour = -1

# name: Executable match style
# type: enum
#  0 = PATH only
#  1 = PATH and CWD
#  2 = PATH, CWD, and directories
# Changes how Clink will match executables when there is no path separator on
# the line. 0 = PATH only, 1 = PATH and CWD, 2 = PATH, CWD, and directories. In
# all cases both executables and directories are matched when there is a path
# separator present. A value of -1 will disable executable matching completely.
exec_match_style = 2

# name: Whitespace prefix matches files
# type: bool
# If the line begins with whitespace then Clink bypasses executable matching and
# will match all files and directories instead.
space_prefix_match_files = 1

# name: Colour of the prompt
# type: int
# Surrounds the prompt in ANSI escape codes to set the prompt's colour. Disabled
# when the value is less than 0.
prompt_colour = -1

# name: Auto-answer terminate prompt
# type: enum
#  0 = Disabled
#  1 = Answer 'Y'
#  2 = Answer 'N'
# Automatically answers cmd.exe's 'Terminate batch job (Y/N)?' prompts. 0 =
# disabled, 1 = answer 'Y', 2 = answer 'N'.
terminate_autoanswer = 0

# name: Lines of history saved to disk
# type: int
# When set to a positive integer this is the number of lines of history that
# will persist when Clink saves the command history to disk. Use 0 for infinite
# lines and <0 to disable history persistence.
history_file_lines = 10000

# name: Skip adding lines prefixed with whitespace
# type: bool
# Ignore lines that begin with whitespace when adding lines in to the history.
history_ignore_space = 0

# name: Controls how duplicate entries are handled
# type: enum
#  0 = Always add
#  1 = Ignore
#  2 = Erase previous
# If a line is a duplicate of an existing history entry Clink will erase the
# duplicate when this is set 2. A value of 1 will not add duplicates to the
# history and a value of 0 will always add lines. Note that history is not
# deduplicated when reading/writing to disk.
history_dupe_mode = 2

# name: Read/write history file each line edited
# type: bool
# When non-zero the history will be read from disk before editing a new line and
# written to disk afterwards.
history_io = 1

# name: Sets how command history expansion is applied
# type: enum
#  0 = Off
#  1 = On
#  2 = Not in single quotes
#  3 = Not in double quote
#  4 = Not in any quotes
# The '!' character in an entered line can be interpreted to introduce words
# from the history. This can be enabled and disable by setting this value to 1
# or 0. Values or 2, 3 or 4 will skip any ! character quoted in single, double,
# or both quotes respectively.
history_expand_mode = 4

# name: Support Windows' Ctrl-Alt substitute for AltGr
# type: bool
# Windows provides Ctrl-Alt as a substitute for AltGr, historically to support
# keyboards with no AltGr key. This may collide with some of Readline's
# bindings.
use_altgr_substitute = 1

# name: Strips CR and LF chars on paste
# type: enum
#  0 = Paste unchanged
#  1 = Strip
#  2 = As space
# Setting this to a value >0 will make Clink strip CR and LF characters from
# text pasted into the current line. Set this to 1 to strip all newline
# characters and 2 to replace them with a space.
strip_crlf_on_paste = 2

# name: Enables basic ANSI escape code support
# type: bool
# When printing the prompt, Clink has basic built-in support for SGR ANSI escape
# codes to control the text colours. This is automatically disabled if a third
# party tool is detected that also provides this facility. It can also be
# disabled by setting this to 0.
ansi_code_support = 1
'@

## Set content of files
Set-Content -Path "$Root\_data\settings" -Value $ClinkSettings
Set-Content -Path "$Root\_code\preRequiments.ps1" -Value $preRequiments
Set-Content -Path "$Root\_code\setupPS.ps1" -Value $setupPS
Set-Content -Path "$Root\_code\setupAD.ps1" -Value $setupAD

try{
    $testchoco = Test-Path -Path C:\ProgramData\chocolatey
    if(!$testchoco){
    Write-Host -ForegroundColor Yellow "[INFO] `t Starting Chocolatey setup."
    Powershell.exe -noprofile -File "$Root\_code\preRequiments.ps1"
    Write-Host -ForegroundColor Green "[OK] `t Chocolatey installed"
    }
    "`n"
    Write-Host -ForegroundColor Yellow "[INFO] `t Starting PowerShell setup."
    Powershell.exe -noprofile -File "$Root\_code\SetupPS.ps1"
    Write-Host -ForegroundColor Green "[OK] `t Setup of PowerShell is complete."
    "`n"
    Write-Host -ForegroundColor Yellow "[INFO] `t Starting Acttive Directory setup."
    Powershell.exe -noprofile -File "$Root\_code\SetupAD.ps1"
    Write-Host -ForegroundColor Green "[OK] `t Setup of Active Directory is complete."
    "`n"
    Write-Host -ForegroundColor Yellow "[INFO] `t Starting CMD setup."
    Start-Process cmd.exe -argumentList 'cmd.exe /c "choco install clink -y"' -Wait -PassThru -NoNewWindow
    Start-Sleep -sec 3
    Start-Process cmd.exe -argumentList '/c exit' -Wait -PassThru -NoNewWindow
    $User = $env:UserName
    Set-Content "C:\Users\$user\AppData\Local\clink\settings" -Value $ClinkSettings
    Write-Host -ForegroundColor Green "[OK] `t Setup of CMD is complete."
}catch{$_.Exception.Message}
## Cleanup
Start-Sleep -Seconds 2
Write-Host -ForegroundColor Yellow "[INFO] `t Starting cleanup."
Remove-item -Path "$Root\_code\preRequiments.ps1"
Remove-item -Path "$Root\_code\SetupAD.ps1"
Remove-item -Path "$Root\_code\SetupPS.ps1"
Write-Host -ForegroundColor Green "[OK] `t Cleanup complete."

Write-Output -InputObject "Press any key to continue..."
[void]$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
