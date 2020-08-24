$LogDate = Get-Date -format ddMMyyyy

## Global Vars
$Passphrase=""
$SaltCrypto=""
$INITPW=""
[string]$Root = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])

## endregion Global Vars

## Functions
Function Get-SettingsINI {
    $SettingsINI = Get-Content "$Root\_data\settings.ini"
    return $SettingsINI 
}

Function Get-CredentialINI {
    $CredentialINI = Get-Content "$Root\_data\Credential.ini"
    return $CredentialINI
}

[Reflection.Assembly]::LoadWithPartialName("System.Security") 
 
function Encrypt-String($String, $Passphrase=$Passphrase, $salt=$SaltCrypto, $init=$INITPW, [switch]$arrayOutput) 
{ 
    $r = new-Object System.Security.Cryptography.RijndaelManaged 
    $pass = [Text.Encoding]::UTF8.GetBytes($Passphrase) 
    $salt = [Text.Encoding]::UTF8.GetBytes($salt) 
 
    $r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8 
    $r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15] 

    $c = $r.CreateEncryptor() 
    $ms = new-Object IO.MemoryStream 
    $cs = new-Object Security.Cryptography.CryptoStream $ms,$c,"Write" 
    $sw = new-Object IO.StreamWriter $cs 
    $sw.Write($String) 
    $sw.Close() 
    $cs.Close() 
    $ms.Close() 
    $r.Clear() 
    [byte[]]$result = $ms.ToArray() 
    return [Convert]::ToBase64String($result) 
} 
 
function Decrypt-String($Encrypted, $Passphrase=$Passphrase, $salt=$SaltCrypto, $init=$INITPW) 
{ 
    if($Encrypted -is [string]){ 
        $Encrypted = [Convert]::FromBase64String($Encrypted) 
       } 
 
    $r = new-Object System.Security.Cryptography.RijndaelManaged 
    $pass = [Text.Encoding]::UTF8.GetBytes($Passphrase) 
    $salt = [Text.Encoding]::UTF8.GetBytes($salt) 
 
    $r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8 
    $r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15] 
 
 
    $d = $r.CreateDecryptor() 
    $ms = new-Object IO.MemoryStream @(,$Encrypted) 
    $cs = new-Object Security.Cryptography.CryptoStream $ms,$d,"Read" 
    $sr = new-Object IO.StreamReader $cs 
    Write-Output $sr.ReadToEnd() 
    $sr.Close() 
    $cs.Close() 
    $ms.Close() 
    $r.Clear() 
} 

Function GD {
    return (get-date)   
}

Function PS-Log {
        Param
        (
        [Parameter(Mandatory=$true)]
 [string]$Permission
        )
         if($UN -eq $null)
 {
 $user = $env:USERNAME
 $HostName = hostname
        
 $date = $LogDate
 
 Write-Output "User: $user; Host: $HostName; Permission: $Permission; Log: History `n" | Out-File "$LogPath\PS-Log_$date.log" -Append
 Write-Output $PSHistory | Out-File "$LogPath\PS-Log_$date.log" -Append
 }
        else
 {
 $user = $UN
 $HostName = hostname
 $date = $LogDate
 
 Write-Output "User: $user; Host: $HostName; Permission: $Permission; Log: History `n" | Out-File "$LogPath\PS-Log_$date.log" -Append
 Write-Output $PSHistory | Out-File "$LogPath\PS-Log_$date.log" -Append    }
        }
        
Function CMD-Log {
        Param
        (
        [Parameter(Mandatory=$true)]
 [string]$Permission
        )
         if($UN -eq $null)
 {
 $user = $env:USERNAME
 $HostName = hostname
        
 $date = $LogDate
 
 Write-Output "User: $user; Host: $HostName; Permission: $Permission; Log: History `n" | Out-File "$LogPath\CMD-Log_$date.log" -Append
 Write-Output $CMDHistory | Out-File "$LogPath\CMD-Log_$date.log" -Append
 }
        else
 {
 $user = $UN
 $HostName = hostname
 $date = $LogDate
 
 Write-Output "User: $user; Host: $HostName; Permission: $Permission; Log: History `n" | Out-File "$LogPath\CMD-Log_$date.log" -Append
 Write-Output $CMDHistory | Out-File "$LogPath\CMD-Log_$date.log" -Append
 }
        }
        

Function File-Log {
        Param
        (
        [Parameter(Mandatory=$true)]
 [string]$Permission,
 [string]$User
        )
        
         if($UN -eq $null)
 {
 $user = $env:USERNAME
 $HostName = hostname
 $date = $LogDate
 Write-Output "User: $user; Host: $HostName; Permission: $Permission; Log: File `n Datei wurde geöffnet: $($File.FileName)" | Out-File "$LogPath\File-Log_$date.log" -Append
 }
        else
 {
 $user = $UN
 $HostName = hostname
 $date = $LogDate
 Write-Output "User: $user; Host: $HostName; Permission: $Permission; Log: File `n Datei wurde geöffnet: $($File.FileName)" | Out-File "$LogPath\File-Log_$date.log" -Append
 }
        
        }
Function Cred-Check-AD {

 $username = $Credentials.username
 $password = $Credentials.GetNetworkCredential().password

 # Get current domain using logged-on user's credentials
 $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
 $domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)

if ($domain.name -eq $null)
{
 return $false
}
else
{
 return $true
}
}
Function Cred-Check-Local {
$username = $Credentials.username
$password = $Credentials.GetNetworkCredential().password
$computer = $env:COMPUTERNAME

Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$obj = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine',
$computer)
$check = $obj.ValidateCredentials($username, $password)
if ($check)
{
 return $false
}
else
{
 return $true
}
}
Function Check-Local-Admin-AD {

 if($UN -eq $null)
     {
     $user = $env:USERNAME
     $GrpName = $ServerAdminGroup
         $GrpMember = (Get-ADGroup $GrpName -Properties member).member
  foreach($member in $GrpMember)
      {
      
      $GrpMemberSam += (Get-ADUser -filter * -SearchBase $member).SamAccountName
         if($user -in $GrpMemberSam){return $true}else{return $false}
 
      }
     }
 else
     {
     $user = $UN
     $GrpName = $ServerAdminGroup
         $GrpMember = (Get-ADGroup $GrpName -Properties member).member
  foreach($member in $GrpMember)
      {
      
      $GrpMemberSam += (Get-ADUser -filter * -SearchBase $member).SamAccountName
         if($user -in $GrpMemberSam){return $true}else{return $false}
 
      }
     }
 }
 Function Check-Local-Admin-Local {
       if($UN -eq $null)
       {
       $user = "$env:COMPUTERNAME\$env:USERNAME"
       $group = 'Administrators'
       $GrpMember = (Get-LocalGroupMember $group).Name
              if($GrpMember -contains $user){return $true}else{return $false}
       }
   else
       {
       $user = "$env:COMPUTERNAME\$UN"
       $group = 'Administrators'
       $GrpMember = (Get-LocalGroupMember $group).Name -contains $user
              if($GrpMember -contains $user){return $true}else{return $false}
       }
}

Function Get-SettingsFromIni {
    $settingsInfo = Get-SettingsINI
    $SettingsSet = $settingsInfo[1]
    $DomainADminGroup = $settingsInfo[3]
    $LogPath = $settingsInfo[5]
    Set-Variable -Name SettingsSet -Value $SettingsSet -Scope Global
    Set-Variable -Name EncDomainADminGroup -Value $DomainADminGroup -Scope Global
    Set-Variable -Name EncLogPath -Value $LogPath -Scope Global
}
Function Get-CredentialFromIni {
    $CredentialInfo = Get-CredentialINI
    $ADMUser = $CredentialInfo[1]
    $ADMPass = $CredentialInfo[2]
    $SUser = $CredentialInfo[4]
    $SPass = $CredentialInfo[5]
    Set-Variable -Name EncADMUser -Value $ADMUser -Scope Global
    Set-Variable -Name EncADMPass -Value $ADMPass -Scope Global
    Set-Variable -Name EncSUser -Value $SUser -Scope Global
    Set-Variable -Name EncSPass -Value $SPass -Scope Global
}

Function Encrypt-Setting-ADMGroup {

    if($ADMGroup_TB.Text -ne "")
    {
        $DomainAdminGroup=Encrypt-String $ADMGroup_TB.Text
        Set-Variable -Name EncDomainADminGroupSet -Value $DomainAdminGroup -Scope Global
    }
    else
    {
        $Group = $EncDomainADminGroup -replace "DomainAdminGroup=", ""
        Set-Variable -Name EncDomainADminGroupSet -Value $Group -Scope Global
    }
}
Function Encrypt-Setting-LogPath {

    if($LogPath_TB.Text -ne "")
    {
        $LogPath=Encrypt-String $LogPath_TB.Text
        Set-Variable -Name EncLogPathSet -Value $LogPath -Scope Global
    }
    else
    {
        $Log = $EncLogPath -replace "LogPath=", ""
        Set-Variable -Name EncLogPathSet -Value $Log -Scope Global
    }
}
Function Encrypt-Setting-ADMUserName {

    if($ADMUserName_TB.Text -ne "")
    {
        $ADMUsername=Encrypt-String $ADMUserName_TB.Text
        Set-Variable -Name EncADMUserSet -Value $ADMUsername -Scope Global
    }
    else
    {
        $Username = $EncADMUser -replace "ADMUsername=", ""
        Set-Variable -Name EncADMUserSet -Value $Username -Scope Global
    }
}
Function Encrypt-Setting-ADMPassword {

    if($ADMPassword_TB.Text -ne "")
    {
        $ADMPassword=Encrypt-String $ADMPassword_TB.Text
        Set-Variable -Name EncADMPassSet -Value $ADMPassword -Scope Global
    }
    else
    {
        $Password = $EncADMPass -replace "ADMPassword=", ""
        Set-Variable -Name EncADMPassSet -Value $Password -Scope Global
    }
}
Function Encrypt-Setting-SUserName {

    if($SUserName_TB.Text -ne "")
    {
        $SUsername=Encrypt-String $SUserName_TB.Text
        Set-Variable -Name EncSUserSet -Value $SUsername -Scope Global
    }
    else
    {
        $Username = $EncSUser -replace "Username=", ""
        Set-Variable -Name EncSUserSet -Value $Username -Scope Global
    }
}
Function Encrypt-Setting-SPassword {
    if($SPassword_TB.Text -ne "")
    {
        $SPassword=Encrypt-String $SPassword_TB.Text
        Set-Variable -Name EncSPassSet -Value $SPassword -Scope Global
    }
    else
    {
        $Password = $EncSPass -replace "Password=", ""
        Set-Variable -Name EncSPassSet -Value $Password -Scope Global
    }
}
Function Decrypt-Settings {

    $DomainAdminGroup = $EncDomainADminGroup -replace "DomainAdminGroup=", ""
    $DomainAdminGroup = Decrypt-String $DomainAdminGroup

    Set-Variable -Name DecDomainAdminGroup -Value $DomainAdminGroup -Scope Global

    $PathLog = $EncLogPath -replace "LogPath=", ""
    $PathLog = Decrypt-String $PathLog

    Set-Variable -Name DecLogPath -Value $PathLog -Scope Global
}
function Decrypt-Credential {
    $ADMUsername = $EncADMUser -replace "ADMUsername="
    $ADMUsername = Decrypt-String $ADMUsername

    $ADMPassword = $EncADMPass -replace "ADMPassword=", ""
    $ADMPassword = Decrypt-String $ADMPassword
    
    $SUsername = $EncSUser -replace "Username=", ""
    $SUsername = Decrypt-String $SUsername

    $SPassword = $EncSPass -replace "Password="
    $SPassword = Decrypt-String $SPassword

    Set-Variable -Name DecADMUser -Value $ADMUsername -Scope Global
    Set-Variable -Name DecADMPass -Value $ADMPassword -Scope Global
    Set-Variable -Name DecSUser -Value $SUsername -Scope Global
    Set-Variable -Name DecSPass -Value $SPassword -Scope Global
}
Function Write-Settings {
    Clear-Content -Path "$Root\_data\settings.ini"
    $ContentSettings = @("[Settings]", "SettingSet=1", "[Admin Settings]", "DomainAdminGroup=$EncDomainADminGroupSet", "[Log Path]", "LogPath=$EncLogPathSet")
    Set-Content -Path "$Root\_data\settings.ini" -Value $ContentSettings

    Clear-Content -Path "$Root\_data\Credential.ini"
    $ContentCredntail = @("[ADM]", "ADMUsername=$EncADMUserSet", "ADMPassword=$EncADMPassSet", "[Standard User]", "Username=$EncSUserSet", "Password=$EncSPassSet")
    Set-Content -Path "$Root\_data\Credential.ini" -Value $ContentCredntail
}
Function Read-Settings {
    $Settings_LB.Items.Add("[settings.ini]")
    $Settings_LB.Items.Add("DomainAdminGroup: $($DecDomainADminGroup)")
    $Settings_LB.Items.Add("LogPath: $($DecLogPath)")
    $Settings_LB.Items.Add("[Credential.ini]")
    $Settings_LB.Items.Add("ADMUsername: $($DecADMUser)")
    $Settings_LB.Items.Add("ADMPassword: $($DecADMPass)")
    $Settings_LB.Items.Add("Username: $($DecSUser)")
    $Settings_LB.Items.Add("Password: $($DecSPass)")
}
Function Set-Login-Crednetail{
    Get-CredentialFromINI
    Decrypt-Credential
    Set-Variable -Name LoginUsernameADM -Value $DecADMUser -Scope Global
    Set-Variable -Name LoginPasswordADM -Value $DecADMPass -Scope Global
    Set-Variable -Name LoginUsername -Value $DecSUser -Scope Global
    Set-Variable -Name LoginPassword -Value $DecSPass -Scope Global
}
Function Set-Settings{
    Get-SettingsFromINI
    Decrypt-Settings
    Set-Variable -Name ServerAdminGroup -Value $DecDomainADminGroup -Scope Global
    Set-Variable -Name LogPath -Value $DecLogPath -Scope Global
}
Function Load-PS-Log{
    $PSLog= Get-Content -Path "$LogPath\PS-Log_$date.log"
    return $PSLog
}
Function Load-CMD-Log{
    $CMDLog= Get-Content -Path "$LogPath\CMD-Log_$date.log"
    return $CMDLog
}
Function Load-File-Log{
    $FileLog= Get-Content -Path "$LogPath\File-Log_$date.log"
    return $FileLog
}
## Form Login


Add-Type -AssemblyName PresentationCore, PresentationFramework, System.Windows.Forms

$XamlLogin = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="600" Height="400" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="0,0,0,0" Background="#35333a" BorderThickness="0" BorderBrush="#666374" Foreground="#514e5d" OpacityMask="#5b586d" Name="LoginPageWPF" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Title="Login Security-App" WindowChrome.IsHitTestVisibleInChrome="True">
	<Grid Background="#262335" ShowGridLines="False" Name="MainGrid">
		<TabControl Name="TabNav" SelectedIndex="0" Padding="-1">
			<TabItem Name="LoginTab" Header="Tab 1" Visibility="Collapsed">
				<Grid Background="#262335" Margin="0">
					<TextBox Name="UsernameTB" Background="#171520" Foreground="#ffffff" BorderThickness="0" HorizontalContentAlignment="Center" VerticalContentAlignment="Center" Text="username" Height="24" Width="200" Margin="0,0,0,80"/>
					<PasswordBox Name="PasswordTB" Background="#171520" Foreground="#ffffff" BorderThickness="0" HorizontalContentAlignment="Center" VerticalContentAlignment="Center" Height="24" Width="200" Margin="0,0,0,0"/>
					<Button Name="LoginBT" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Login" Margin="0,80,0,0" Height="24" Width="200" IsDefault="True"/>
        </Grid>
      </TabItem>
		</TabControl>
	</Grid>
</Window>
"@

Function Login {
  if ($UsernameTB.text -EQ $LoginUsernameadm){
    if ($UsernameTB.text -EQ $LoginUsernameadm -and $PasswordTB.password -EQ $LoginPasswordadm) {
      Set-Variable -Name AdminLogin -Scope Global -Value $true
      $WindowLogin.Close()
    }
  }
  elseif ($UsernameTB.text -EQ $LoginUsername -and $PasswordTB.password -EQ $LoginPassword) {
    Set-Variable -Name AdminLogin -Scope Global -Value $false
    $WindowLogin.Close()
  }
}

function ClearUsername {
	$UsernameTB.Text = ""
}
function ClearPassword {
	$PasswordTB.Password = ""
}

$WindowLogin = [Windows.Markup.XamlReader]::Parse($XamlLogin)

[xml]$xmlLogin = $XamlLogin

$xmlLogin.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $WindowLogin.FindName($_.Name) }


$UsernameTB.Add_GotFocus({ClearUsername $this $_})
$PasswordTB.Add_GotFocus({ClearPassword $this $_})
$LoginBT.Add_Click({Login $this $_})

## Set Settings and Credential
Set-Login-Crednetail
Set-Settings

$WindowLogin.ShowDialog()

if($AdminLogin -eq $true)
{
    
## Form Admin
$XamlAdmin = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="700" Height="600" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="0,0,0,0" Background="#35333a" BorderThickness="0" BorderBrush="#666374" Foreground="#514e5d" OpacityMask="#5b586d" Name="TestWPF1" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Title="Security-App Admin" WindowChrome.IsHitTestVisibleInChrome="True">
	<Grid Background="#262335" ShowGridLines="False" Name="MainGrid">
		<Grid.RowDefinitions>
			<RowDefinition Height="24"/>
			<RowDefinition Height="13*"/>
		</Grid.RowDefinitions>

		<Grid.ColumnDefinitions>
			<ColumnDefinition Width="2*"/>
			<ColumnDefinition Width="8*"/>
		</Grid.ColumnDefinitions>

		<Border BorderBrush="Black" BorderThickness="0" Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="2" Background="#241b2f">
			<StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
			</StackPanel>
		</Border>

		<StackPanel Background="#241b2f" SnapsToDevicePixels="True" Grid.Row="1" Grid.Column="0">
			<Button Content="Operations" VerticalAlignment="Top" Height="40" Background="#241b2f" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab1BT"/>
			<Button Content="Output" VerticalAlignment="Top" Height="40" Background="#241b2f" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab2BT"/>
			<Button Content="Settings" VerticalAlignment="Top" Height="40" Background="#241b2f" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab3BT"/>
		</StackPanel>

		<TabControl Grid.Row="1" Grid.Column="1" Padding="-1" Name="TabNav" SelectedIndex="0">
			<TabItem Header="Operations" Visibility="Collapsed" Name="Tab1">
				<Grid Background="#262335">
				<TextBlock HorizontalAlignment="Center" VerticalAlignment="Top" TextWrapping="Wrap" Text="Operations" FontSize="14" FontWeight="Bold" Height="21" Foreground="#ffffff"/>
				<TextBlock Foreground="#ffffff" HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="Options" Margin="89,68,0,0"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="CMD" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="150,131,0,0" Name="CMD_BT"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="PowerShell" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="150,175,0,0" Name="PowerShell_BT"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Server Manager" HorizontalAlignment="Left" VerticalAlignment="Top" Width="120" Margin="250,131,0,0" Name="SM_BT"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Active Directory" HorizontalAlignment="Left" VerticalAlignment="Top" Width="120" Margin="250,175,0,0" Name="AD_BT"/>
				<CheckBox Foreground="#ffffff" HorizontalAlignment="Left" VerticalAlignment="Top" Content="as Admin" Margin="390,155,0,0" Name="asAdmin_CB"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Credential" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="240,281,0,0" Name="Credential_BT"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Close" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="198,406,0,0" Name="Close_BT"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Check Local Admin" HorizontalAlignment="Left" VerticalAlignment="Top" Width="130" Margin="330,281,0,0" Name="CLA_BT"/>
				<TextBox Background="#171520" Foreground="#ffffff" BorderThickness="0" HorizontalAlignment="Left" VerticalAlignment="Top" Height="23" Width="300" TextWrapping="Wrap" Margin="94,229,0,0" Name="FilePath_TB"/>
                <Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Open" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="428,229,0,0" Name="OpenFile_BT"/>

				<ComboBox Background="#ffffff" Foreground="#171520" BorderThickness="0" HorizontalAlignment="Left" VerticalAlignment="Top" Width="120" Margin="95,281,0,0" Name="Mode_CB"/>
				</Grid>
			</TabItem>

			<TabItem Header="Output" Visibility="Collapsed" Name="Tab2">
				<Grid Background="#262335">
					<TextBlock HorizontalAlignment="Center" VerticalAlignment="Top" TextWrapping="Wrap" Text="Output" FontSize="14" FontWeight="Bold" Height="21" Foreground="#ffffff"/>
					<ListBox Foreground="#ffffff" Background="#000000" HorizontalAlignment="Left" BorderBrush="Black" BorderThickness="0" Height="400" VerticalAlignment="Top" Width="500" Margin="25,70,0,0" Name="Output_LB"/>
					<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Clear" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="180,485,0,0" Name="ClearOutput_BT"/>
                    <Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Get-Log" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="260,485,0,0" Name="LoadLog_BT"/>
                </Grid>
			</TabItem>

			<TabItem Header="Settings" Visibility="Collapsed" Name="Tab3">
				<Grid Background="#262335">
					<TextBlock HorizontalAlignment="Center" VerticalAlignment="Top" TextWrapping="Wrap" Text="Settings" FontSize="14" FontWeight="Bold" Height="21" Foreground="#ffffff"/>
					<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="GO" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="143,405,0,0" Name="Go_BT"/>
  					<TextBox Background="#171520" Foreground="#ffffff" BorderThickness="0" HorizontalAlignment="Left" VerticalAlignment="Top" Height="23" Width="120" TextWrapping="Wrap" Margin="115,110,0,0" Name="ADMGroup_TB"/>
  					<TextBox Background="#171520" Foreground="#ffffff" BorderThickness="0" HorizontalAlignment="Left" VerticalAlignment="Top" Height="23" Width="120" TextWrapping="Wrap" Margin="115,312,0,0" Name="ADMUserName_TB"/>
  					<TextBox Background="#171520" Foreground="#ffffff" BorderThickness="0" HorizontalAlignment="Left" VerticalAlignment="Top" Height="23" Width="120" TextWrapping="Wrap" Margin="115,260,0,0" Name="SUserName_TB"/>
  					<TextBox Background="#171520" Foreground="#ffffff" BorderThickness="0" HorizontalAlignment="Left" VerticalAlignment="Top" Height="23" Width="120" TextWrapping="Wrap" Margin="259,260,0,0" Name="SPassword_TB"/>
  					<TextBox Background="#171520" Foreground="#ffffff" BorderThickness="0" HorizontalAlignment="Left" VerticalAlignment="Top" Height="23" Width="120" TextWrapping="Wrap" Margin="259,312,0,0" Name="ADMPassword_TB"/>
  					<TextBlock Foreground="#ffffff" HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="Admin Group" Margin="137,92,0,0"/>
  					<TextBlock Foreground="#ffffff" HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="Standard Username" Margin="125,240,0,0"/>
  					<TextBlock Foreground="#ffffff" HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="Standard Password" Margin="267,239,0,0"/>
  					<TextBlock Foreground="#ffffff" HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="Admin Username" Margin="127,292,0,0"/>
  					<TextBlock Foreground="#ffffff" HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="Admin Password" Margin="275,293,0,0"/>
					<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Get-Values" Name="Values_BT" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="267,405,0,0"/>
					<TextBlock Foreground="#ffffff" HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="LogPath" Margin="110,41,0,0"/>
					<TextBox Background="#171520" Foreground="#ffffff" BorderThickness="0" HorizontalAlignment="Left" VerticalAlignment="Top" Name="LogPath_TB" Height="23" Width="230" TextWrapping="Wrap" Margin="20,60,0,0"/>    
					<ListBox Foreground="#ffffff" Background="#000000" HorizontalAlignment="Left" BorderBrush="Black" BorderThickness="1" Height="170" VerticalAlignment="Top" Width="268" Margin="253,60,0,0" Name="Settings_LB"/>
					  
				</Grid>
			</TabItem>

		</TabControl>
	</Grid>
</Window>
"@

Function Tab1Click() {
	$TabNav.SelectedItem = $Tab1
}
Function Tab2Click() {
	$TabNav.SelectedItem = $Tab2
}
Function Tab3Click() {
	$TabNav.SelectedItem = $Tab3
}
#endregion

$WindowADM = [Windows.Markup.XamlReader]::Parse($XamlAdmin)

[xml]$xmlAdmin = $XamlAdmin

$xmlAdmin.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $WindowADM.FindName($_.Name) }


## Tabs
$Tab1BT.Add_Click({Tab1Click $this $_})
$Tab2BT.Add_Click({Tab2Click $this $_})
$Tab3BT.Add_Click({Tab3Click $this $_})
## Buttons
$ClearOutput_BT.Add_Click({
    $Output_LB.Items.Clear()
})

$LoadLog_BT.Add_Click({
    $PSLog=Load-PS-Log
    $CMDLog=Load-CMD-Log
    $FileLog=Load-File-Log
    $Output_LB.items.Clear()
    $Output_LB.items.Add("PowerShell Log")
    foreach($entry in $PSLog)
    {
        $Output_LB.items.Add($entry)
    }
    $Output_LB.items.Add("CMD Log")
    foreach($entry in $CMDLog)
    {
        $Output_LB.items.Add($entry)
    }
    $Output_LB.items.Add("File Log")
    foreach($entry in $FileLog)
    {
        $Output_LB.items.Add($entry)
    }
})

$CMD_BT.Add_Click({
    if($asAdmin_CB.Checked -eq $true)
    {
        $Check = $true    
    }
    else
    {
        $Check = $false
    }
    if($Check -eq $false)
    {

        Clear-Content C:\Users\$($env:USERNAME)\AppData\Local\clink\.history
        $Output_LB.Items.Add("$(GD)   CMD successfully started.")
        $Process = Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-noprofile -command &{Start-Process C:\Windows\system32\cmd.exe}" -WorkingDirectory $env:windir -PassThru -Wait
         
        $Process.WaitForExit()
         if($UN -eq $null)
            {
            $user = $env:USERNAME
            $history = Get-Content  C:\Users\$($user)\AppData\Local\clink\.history
            Set-Variable -Name CMDHistory -Value $history -Scope global
            }
        else
            {
            $user = $UN
            $history = Get-Content  C:\Users\$($user)\AppData\Local\clink\.history
            Set-Variable -Name CMDHistory -Value $history -Scope global
            }
            $Process.WaitForExit()
            CMD-Log -Permission Admin
        
    }
        else
    {
        
        if($CredSet -eq $True -and $Credentials -ne $null){

        Clear-Content C:\Users\$($env:USERNAME)\AppData\Local\clink\.history
         $Output_LB.Items.Add("$(GD)   CMD successfully started as Admin.")
        $Process = Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -Credential $Credentials -ArgumentList "-noprofile -command &{Start-Process C:\Windows\system32\cmd.exe -verb runAs}" -WorkingDirectory $env:windir -PassThru -Wait
        
        $Process.WaitForExit()
         if($UN -eq $null)
            {
            $user = $env:USERNAME
            $history = Get-Content  C:\Users\$($user)\AppData\Local\clink\.history
            Set-Variable -Name CMDHistory -Value $history -Scope global
            }
        else
            {
            $user = $UN
            $history = Get-Content  C:\Users\$($user)\AppData\Local\clink\.history
            Set-Variable -Name CMDHistory -Value $history -Scope global
            }
            CMD-Log -Permission Admin
        }else{
        [System.Windows.Forms.MessageBox]::Show('Credntials not set!', 'Error', 'Ok', 'Error')
         $Output_LB.Items.Add("$(GD)   CMD couldn't be started")
        }
        
    }
})
$PowerShell_BT.Add_Click({
    if($asAdmin_CB.Checked -eq $true)
    {
        $Check = $true    
    }
    else
    {
        $Check = $false
    }
    if($Check -eq $false)
    {
        
        
        Clear-Content C:\Users\$($env:USERNAME)\AppData\Local\clink\.history
        $Output_LB.Items.Add("$(GD)   PowerShell successfully started.")
        $Process = Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-noprofile -command &{Start-Process C:\Windows\system32\WindowsPowerShell\v1.0\\PowerShell.exe}" -WorkingDirectory $env:windir -PassThru -Wait
         
        $Process.WaitForExit()
        if($UN -eq $null)
           {
           $user = $env:USERNAME
           $history = Get-Content  C:\Users\$($user)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
           Set-Variable -Name PSHistory -Value $history -Scope global
           }
       else
           {
           $user = $UN
           $history = Get-Content  C:\Users\$($user)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
           Set-Variable -Name PSHistory -Value $history -Scope global
           }
           $Process.WaitForExit()
           PS-Log -Permission User
        
    }
        else
    {
        
        if($CredSet -eq $True -and $Credentials -ne $null){
            
            
        Clear-Content C:\Users\$($env:USERNAME)\AppData\Local\clink\.history
         $Output_LB.Items.Add("$(GD)   PowerShell successfully started as Admin.")
         $Process = Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -Credential $Credentials -ArgumentList "-noprofile -command &{Start-Process C:\Windows\system32\WindowsPowerShell\v1.0\\PowerShell.exe -verb runAs}" -WorkingDirectory $env:windir -PassThru -Wait
        
         $Process.WaitForExit()
         if($UN -eq $null)
            {
            $user = $env:USERNAME
            $history = Get-Content  C:\Users\$($user)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
            Set-Variable -Name PSHistory -Value $history -Scope global
            }
        else
            {
            $user = $UN
            $history = Get-Content  C:\Users\$($user)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
            Set-Variable -Name PSHistory -Value $history -Scope global
            }
            $Process.WaitForExit()
            PS-Log -Permission Admin
        }else{
        [System.Windows.Forms.MessageBox]::Show('Credntials not set!', 'Error', 'Ok', 'Error')
         $Output_LB.Items.Add("$(GD)   PowerShell couldn't be started.")
        }
        
    }
})
$AD_BT.Add_Click({
    $cmd="$env:windir\system32\rundll32.exe"
    $param="dsquery.dll,OpenQueryWindow"
    Start-Process $cmd $param
    $Output_LB.Items.Add("$(GD)   Active Directory query successfully started.")
    
})
$SM_BT.Add_Click({
    if($asAdmin_CB.Checked -eq $true)
    {
        $Check = $true    
    }
    else
    {
        $Check = $false
    }
    if($Check -eq $false)
    {
        if($CredSet -eq $True -and $Credentials -ne $null){
            
            
             Start-Process -WindowStyle Hidden "PowerShell.exe" -ArgumentList -Credential $Credentials "-noprofile -command &{Start-Process C:\Windows\system32\ServerManager.exe -verb runas}"
             $Output_LB.Items.Add("$(GD)   Server Manager successfully started.")
            
            }
            else
            {
                
                
                Start-Process -WindowStyle Hidden "PowerShell.exe" -ArgumentList "-noprofile -command &{Start-Process C:\Windows\system32\ServerManager.exe}"
                $Output_LB.Items.Add("$(GD)   Server Manager successfully started.")
            }
    }
})
$Credential_BT.Add_Click({
    if($UN -eq $null){$TempUN = $env:USERNAME}else{$TempUN = $UN}
    $Output_LB.items.Clear()
    $Output_LB.Items.Add("Current loged in User: $($TempUN)")
    
    $CredSet = $null
    $UN = $null
    #$Credentials = $null
    
    $Cred = Get-Credential -ErrorAction SilentlyContinue
    if($Cred -ne $null)
    {
        if($Mode_CB.Text -eq "AD")
        {
            $CredCheck=Cred-Check-AD
            if($CredCheck)
            {
                Set-Variable -Name CredSet -Value $true -Scope global
                Set-Variable -Name UN -Value $UserName -Scope global
                Set-Variable -Name Credentials -Value $Cred -Scope global
                $UserName = $Cred.UserName
                $UserName = $UserName -replace "$($env:USERDOMAIN)\\", ""

                $Output_LB.Items.Add("$(GD)    Current user switched to $UserName.")                
            }
        }
        elseif($Mode_CB.Text -eq "Local")
        {
            $CredCheck=Cred-Check-Local
            if($CredCheck)
            {
                Set-Variable -Name CredSet -Value $true -Scope global
                Set-Variable -Name UN -Value $UserName -Scope global
                Set-Variable -Name Credentials -Value $Cred -Scope global
                $UserName = $Cred.UserName
                $UserName = $UserName -replace "$($env:USERDOMAIN)\\", ""

                $Output_LB.Items.Add("$(GD)   Current user switched to $UserName.")                
            }            
        } 
    }	
})
$CLA_BT.Add_Click({
    if($Mode_CB.Text -eq "AD")
    {
        $ADMCheck = Check-Local-Admin-AD
        if($ADMCheck -eq $True)
            {
            if($UN -eq $null){$Name = $env:username}else{$Name = $UN}
            $Output_LB.Items.Add("$(GD)   User $Name is in the Admin group.")
            }
        else
            {
            if($UN -eq $null){$Name = $env:username}else{$Name = $UN}
            $Output_LB.Items.Add("$(GD)   User $Name is not in the Admin group.")
            }
    }
    else
    {
        $ADMCheck = Check-Local-Admin-Local
        if($ADMCheck -eq $True)
            {
            if($UN -eq $null){$Name = $env:username}else{$Name = $UN}
            $Output_LB.Items.Add("$(GD)   User $Name is in the Admin group.")
            }
        else
            {
            if($UN -eq $null){$Name = $env:username}else{$Name = $UN}
            $Output_LB.Items.Add("$(GD)   User $Name is not in the Admin group.")
            } 
    }
})
$OpenFile_BT.Add_Click({
    if($asAdmin_CB.Checked -eq $true)
    {
        $Check = $true    
    }
    else
    {
        $Check = $false
    }
    if($Check -eq $false)
    {
        if($FilePath_TB.Text -ne "")
        {
            if(Test-Path -Path $FilePath_TB.Text)
            {
                
                
                Set-Variable -Name File -Value $FilePath_TB.Text -Scope global
                Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-noprofile -command &{Start-Process $($File.FileName)}" -WorkingDirectory $env:windir -PassThru
                $Output_LB.Items.Add("$(GD)   Programm successfully started as Admin.")
                File-Log -Permission Admin

            }
            else
            {
                [System.Windows.Forms.MessageBox]::Show('Path is invalid.', 'Error', 'Ok', 'Error')
            }
        }
        elseif($FilePath_TB.Text -eq "")
        {
            $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog 
            $OpenFileDialog.initialDirectory = $initialDirectory
            $OpenFileDialog.filter = "EXE Files | *.exe" 
            $OpenFileDialog.Title = $Title 
            $OpenFileDialog.ShowDialog() | Out-Null 
            $OpenFileDialog.filename 
            Set-Variable -Name File -Value $OpenFileDialog -Scope global
            
            
            Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-noprofile -command &{Start-Process $($File.FileName) -verb runAs}" -WorkingDirectory $env:windir -PassThru
            $Output_LB.Items.Add("$(GD)   Programm successfully started as Admin.")
            File-Log -Permission User  
        }
    }
    else
    {
        if($FilePath_TB.Text -ne "")
        {
            if(Test-Path -Path $FilePath_TB.Text)
            {
                
                
                Set-Variable -Name File -Value $FilePath_TB.Text -Scope global
                Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -Credential $Credentials -ArgumentList "-noprofile -command &{Start-Process $($File.FileName)}" -WorkingDirectory $env:windir -PassThru
                $Output_LB.Items.Add("$(GD)   Programm successfully started as Admin.")
                File-Log -Permission Admin

            }
            else
            {
                [System.Windows.Forms.MessageBox]::Show('Path is invalid.', 'Error', 'Ok', 'Error')    
            }
        }
        elseif($FilePath_TB.Text -eq "")
        {
            $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog 
            $OpenFileDialog.initialDirectory = $initialDirectory
            $OpenFileDialog.filter = "EXE Files | *.exe" 
            $OpenFileDialog.Title = $Title 
            $OpenFileDialog.ShowDialog() | Out-Null 
            $OpenFileDialog.filename 
            Set-Variable -Name File -Value $OpenFileDialog -Scope global
            
            
            Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -Credential $Credentials -ArgumentList "-noprofile -command &{Start-Process $($File.FileName)}" -WorkingDirectory $env:windir -PassThru
            $Output_LB.Items.Add("$(GD)   Programm successfully started as Admin.")
            File-Log -Permission User  
        }  
    }
})
$Close_BT.Add_Click({
	$WindowAdmin.close()
})
$Go_BT.Add_Click({
    Encrypt-Setting-ADMGroup
    Encrypt-Setting-LogPath
    Encrypt-Setting-ADMUserName
    Encrypt-Setting-ADMPassword
    Encrypt-Setting-SUserName
    Encrypt-Setting-SPassword
    Write-Settings
    [System.Windows.Forms.MessageBox]::Show('Settings set. App will close now!', 'Info', 'Ok', 'Info')
    exit
})
$Values_BT.Add_Click({
    # Get Values from Ini
    Get-CredentialFromIni
    Get-CredentialINI
    # Decrypt Values
    Decrypt-Settings
    Decrypt-Credential
    # Read Settings
    Read-Settings
})
## else
$Mode_CB.Items.Add("AD")
$Mode_CB.Items.Add("Local")



$WindowADM.ShowDialog()

}
elseif($AdminLogin -eq $false)
{
## Form User
$XamlUser = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="700" Height="600" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="0,0,0,0" Background="#35333a" BorderThickness="0" BorderBrush="#666374" Foreground="#514e5d" OpacityMask="#5b586d" Name="TestWPF1" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Title="Security-App User" WindowChrome.IsHitTestVisibleInChrome="True">
	<Grid Background="#262335" ShowGridLines="False" Name="MainGrid">
		<Grid.RowDefinitions>
			<RowDefinition Height="24"/>
			<RowDefinition Height="13*"/>
		</Grid.RowDefinitions>

		<Grid.ColumnDefinitions>
			<ColumnDefinition Width="2*"/>
			<ColumnDefinition Width="8*"/>
		</Grid.ColumnDefinitions>

		<Border BorderBrush="Black" BorderThickness="0" Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="2" Background="#241b2f">
			<StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
			</StackPanel>
		</Border>

		<StackPanel Background="#241b2f" SnapsToDevicePixels="True" Grid.Row="1" Grid.Column="0">
			<Button Content="Operations" VerticalAlignment="Top" Height="40" Background="#241b2f" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab1BT"/>
			<Button Content="Output" VerticalAlignment="Top" Height="40" Background="#241b2f" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab2BT"/>
		</StackPanel>

		<TabControl Grid.Row="1" Grid.Column="1" Padding="-1" Name="TabNav" SelectedIndex="0">
			<TabItem Header="Operations" Visibility="Collapsed" Name="Tab1">
				<Grid Background="#262335">
				<TextBlock HorizontalAlignment="Center" VerticalAlignment="Top" TextWrapping="Wrap" Text="Operations" FontSize="14" FontWeight="Bold" Height="21" Foreground="#ffffff"/>
				<TextBlock Foreground="#ffffff" HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="Options" Margin="89,68,0,0"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="CMD" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="150,131,0,0" Name="CMD_BT"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="PowerShell" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="150,175,0,0" Name="PowerShell_BT"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Server Manager" HorizontalAlignment="Left" VerticalAlignment="Top" Width="120" Margin="250,131,0,0" Name="SM_BT"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Active Directory" HorizontalAlignment="Left" VerticalAlignment="Top" Width="120" Margin="250,175,0,0" Name="AD_BT"/>
				<CheckBox Foreground="#ffffff" HorizontalAlignment="Left" VerticalAlignment="Top" Content="as Admin" Margin="390,155,0,0" Name="asAdmin_CB"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Credential" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="240,281,0,0" Name="Credential_BT"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Close" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="198,406,0,0" Name="Close_BT"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Check Local Admin" HorizontalAlignment="Left" VerticalAlignment="Top" Width="130" Margin="330,281,0,0" Name="CLA_BT"/>
				<TextBox Background="#171520" Foreground="#ffffff" BorderThickness="0" HorizontalAlignment="Left" VerticalAlignment="Top" Height="23" Width="300" TextWrapping="Wrap" Margin="94,229,0,0" Name="FilePath_TB"/>
				<Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Open" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="428,229,0,0" Name="OpenFile_BT"/>
				
				<ComboBox Background="#ffffff" Foreground="#171520" BorderThickness="0" HorizontalAlignment="Left" VerticalAlignment="Top" Width="120" Margin="95,281,0,0" Name="Mode_CB"/>
			</Grid>
			</TabItem>

			<TabItem Header="Output" Visibility="Collapsed" Name="Tab2">
				<Grid Background="#262335">
				<TextBlock HorizontalAlignment="Center" VerticalAlignment="Top" TextWrapping="Wrap" Text="Output" FontSize="14" FontWeight="Bold" Height="21" Foreground="#ffffff"/>
				<ListBox Foreground="#ffffff" Background="#000000" HorizontalAlignment="Left" BorderBrush="Black" BorderThickness="0" Height="400" VerticalAlignment="Top" Width="500" Margin="25,70,0,0" Name="Output_LB"/>
                <Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Clear" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="180,485,0,0" Name="ClearOutput_BT"/>
                <Button FontSize="14" Background="#171520" Foreground="#ffffff" BorderThickness="0" Content="Get-Log" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="260,485,0,0" Name="LoadLog_BT"/>
				</Grid>
			</TabItem>

		</TabControl>
	</Grid>
</Window>
"@


Function Tab1Click() {
	$TabNav.SelectedItem = $Tab1
}
Function Tab2Click() {
	$TabNav.SelectedItem = $Tab2
}

$WindowUser = [Windows.Markup.XamlReader]::Parse($XamlUser)

[xml]$xmlUser = $XamlUser

$xmlUser.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $WindowUser.FindName($_.Name) }

## Tabs
$Tab1BT.Add_Click({Tab1Click $this $_})
$Tab2BT.Add_Click({Tab2Click $this $_})
## Buttons
$ClearOutput_BT.Add_Click({
    $Output_LB.Items.Clear()
})
$LoadLog_BT.Add_Click({
    $PSLog=Load-PS-Log
    $CMDLog=Load-CMD-Log
    $FileLog=Load-File-Log
    $Output_LB.items.Clear()
    $Output_LB.items.Add("PowerShell Log")
    foreach($entry in $PSLog)
    {
        $Output_LB.items.Add($entry)
    }
    $Output_LB.items.Add("CMD Log")
    foreach($entry in $CMDLog)
    {
        $Output_LB.items.Add($entry)
    }
    $Output_LB.items.Add("File Log")
    foreach($entry in $FileLog)
    {
        $Output_LB.items.Add($entry)
    }
})
$CMD_BT.Add_Click({
    if($asAdmin_CB.Checked -eq $true)
    {
        $Check = $true    
    }
    else
    {
        $Check = $false
    }
    if($Check -eq $false)
    {
        
        
        Clear-Content C:\Users\$($env:USERNAME)\AppData\Local\clink\.history
        $Output_LB.Items.Add("$(GD)   CMD successfully started.")
        $Process = Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-noprofile -command &{Start-Process C:\Windows\system32\cmd.exe}" -WorkingDirectory $env:windir -PassThru -Wait
         
        $Process.WaitForExit()
         if($UN -eq $null)
            {
            $user = $env:USERNAME
            $history = Get-Content  C:\Users\$($user)\AppData\Local\clink\.history
            Set-Variable -Name CMDHistory -Value $history -Scope global
            }
        else
            {
            $user = $UN
            $history = Get-Content  C:\Users\$($user)\AppData\Local\clink\.history
            Set-Variable -Name CMDHistory -Value $history -Scope global
            }
            $Process.WaitForExit()
            CMD-Log -Permission Admin
        
    }
        else
    {
        
        if($CredSet -eq $True -and $Credentials -ne $null){
            
            
        Clear-Content C:\Users\$($env:USERNAME)\AppData\Local\clink\.history
         $Output_LB.Items.Add("$(GD)   CMD successfully started as Admin.")
        $Process = Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -Credential $Credentials -ArgumentList "-noprofile -command &{Start-Process C:\Windows\system32\cmd.exe -verb runAs}" -WorkingDirectory $env:windir -PassThru -Wait
        
        $Process.WaitForExit()
         if($UN -eq $null)
            {
            $user = $env:USERNAME
            $history = Get-Content  C:\Users\$($user)\AppData\Local\clink\.history
            Set-Variable -Name CMDHistory -Value $history -Scope global
            }
        else
            {
            $user = $UN
            $history = Get-Content  C:\Users\$($user)\AppData\Local\clink\.history
            Set-Variable -Name CMDHistory -Value $history -Scope global
            }
            CMD-Log -Permission Admin
        }else{
        [System.Windows.Forms.MessageBox]::Show('Credntials not set!', 'Error', 'Ok', 'Error')
         $Output_LB.Items.Add("$(GD)   CMD couldn't be started")
        }
        
    }
})
$PowerShell_BT.Add_Click({
    if($asAdmin_CB.Checked -eq $true)
    {
        $Check = $true    
    }
    else
    {
        $Check = $false
    }
    if($Check -eq $false)
    {
        
        
        Clear-Content C:\Users\$($env:USERNAME)\AppData\Local\clink\.history
        $Output_LB.Items.Add("$(GD)   PowerShell successfully started.")
        $Process = Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-noprofile -command &{Start-Process C:\Windows\system32\WindowsPowerShell\v1.0\\PowerShell.exe}" -WorkingDirectory $env:windir -PassThru -Wait
         
        $Process.WaitForExit()
        if($UN -eq $null)
           {
           $user = $env:USERNAME
           $history = Get-Content  C:\Users\$($user)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
           Set-Variable -Name PSHistory -Value $history -Scope global
           }
       else
           {
           $user = $UN
           $history = Get-Content  C:\Users\$($user)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
           Set-Variable -Name PSHistory -Value $history -Scope global
           }
           $Process.WaitForExit()
           PS-Log -Permission User
        
    }
        else
    {
        
        if($CredSet -eq $True -and $Credentials -ne $null){
            
            
        Clear-Content C:\Users\$($env:USERNAME)\AppData\Local\clink\.history
         $Output_LB.Items.Add("$(GD)   PowerShell successfully started as Admin.")
         $Process = Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -Credential $Credentials -ArgumentList "-noprofile -command &{Start-Process C:\Windows\system32\WindowsPowerShell\v1.0\\PowerShell.exe -verb runAs}" -WorkingDirectory $env:windir -PassThru -Wait
        
         $Process.WaitForExit()
         if($UN -eq $null)
            {
            $user = $env:USERNAME
            $history = Get-Content  C:\Users\$($user)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
            Set-Variable -Name PSHistory -Value $history -Scope global
            }
        else
            {
            $user = $UN
            $history = Get-Content  C:\Users\$($user)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
            Set-Variable -Name PSHistory -Value $history -Scope global
            }
            $Process.WaitForExit()
            PS-Log -Permission Admin
        }else{
        [System.Windows.Forms.MessageBox]::Show('Credntials not set!', 'Error', 'Ok', 'Error')
         $Output_LB.Items.Add("$(GD)   PowerShell couldn't be started.")
        }
        
    }
})
$AD_BT.Add_Click({
    
    
    $cmd="$env:windir\system32\rundll32.exe"
    $param="dsquery.dll,OpenQueryWindow"
    Start-Process $cmd $param
$Output_LB.Items.Add("$(GD)   Active Directory query successfully started.")
})
$SM_BT.Add_Click({
    if($asAdmin_CB.Checked -eq $true)
    {
        $Check = $true    
    }
    else
    {
        $Check = $false
    }
    if($Check -eq $false)
    {
        if($CredSet -eq $True -and $Credentials -ne $null){
            
            
             Start-Process -WindowStyle Hidden "PowerShell.exe" -ArgumentList "-noprofile -command &{Start-Process C:\Windows\system32\ServerManager.exe -verb runas}"
             $Output_LB.Items.Add("$(GD)   Server Manager successfully started.")
            
            }
            else
            {
                
                
                Start-Process -WindowStyle Hidden "PowerShell.exe" -ArgumentList "-noprofile -command &{Start-Process C:\Windows\system32\ServerManager.exe}"
                $Output_LB.Items.Add("$(GD)   Server Manager successfully started.")
            }
    }
})
$Credential_BT.Add_Click({
    if($UN -eq $null){$TempUN = $env:USERNAME}else{$TempUN = $UN}
    $Output_LB.items.Clear()
     $Output_LB.Items.Add("Current loged in User: $($TempUN)")
    
    $CredSet = $null
    $UN = $null
    #$Credentials = $null
    
    $Cred = Get-Credential -ErrorAction SilentlyContinue
    if($Cred -ne $null)
    {
        if($Mode_CB.Text -eq "AD")
        {
            $CredCheck=Cred-Check-AD
            if($CredCheck)
            {
                Set-Variable -Name CredSet -Value $true -Scope global
                Set-Variable -Name UN -Value $UserName -Scope global
                Set-Variable -Name Credentials -Value $Cred -Scope global
                $UserName = $Cred.UserName
                $UserName = $UserName -replace "$($env:USERDOMAIN)\\", ""

                $Output_LB.Items.Add("$(GD)    Current user switched to $UserName.")                
            }
        }
        elseif($Mode_CB.Text -eq "Local")
        {
            $CredCheck=Cred-Check-Local
            if($CredCheck)
            {
                Set-Variable -Name CredSet -Value $true -Scope global
                Set-Variable -Name UN -Value $UserName -Scope global
                Set-Variable -Name Credentials -Value $Cred -Scope global
                $UserName = $Cred.UserName
                $UserName = $UserName -replace "$($env:USERDOMAIN)\\", ""

                $Output_LB.Items.Add("$(GD)   Current user switched to $UserName.")                
            }            
        } 
    }	
})
$CLA_BT.Add_Click({
    if($Mode_CB.Text -eq "AD")
    {
        $ADMCheck = Check-Local-Admin-AD
        if($ADMCheck -eq $True)
            {
            if($UN -eq $null){$Name = $env:username}else{$Name = $UN}
            $Output_LB.Items.Add("$(GD)   User $Name is in the Admin group.")
            }
        else
            {
            if($UN -eq $null){$Name = $env:username}else{$Name = $UN}
            $Output_LB.Items.Add("$(GD)   User $Name is not in the Admin group.")
            }
    }
    else
    {
        $ADMCheck = Check-Local-Admin-Local
        if($ADMCheck -eq $True)
            {
            if($UN -eq $null){$Name = $env:username}else{$Name = $UN}
            $Output_LB.Items.Add("$(GD)   User $Name is in the Admin group.")
            }
        else
            {
            if($UN -eq $null){$Name = $env:username}else{$Name = $UN}
            $Output_LB.Items.Add("$(GD)   User $Name is not in the Admin group.")
            } 
    }
})
$OpenFile_BT.Add_Click({
    if($asAdmin_CB.Checked -eq $true)
    {
        $Check = $true    
    }
    else
    {
        $Check = $false
    }
    if($Check -eq $false)
    {
        if($FilePath_TB.Text -ne "")
        {
            if((Test-Path -Path $FilePath_TB.Text))
            {
                
                
                Set-Variable -Name File -Value $FilePath_TB.Text -Scope global
                Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-noprofile -command &{Start-Process $($File.FileName)}" -WorkingDirectory $env:windir -PassThru
                $Output_LB.Items.Add("$(GD)   Programm successfully started as Admin.")
                File-Log -Permission Admin

            }
            else
            {
                [System.Windows.Forms.MessageBox]::Show('Path is invalid.', 'Error', 'Ok', 'Error')
            }
        }
        elseif($FilePath_TB.Text -eq "")
        {
            $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog 
            $OpenFileDialog.initialDirectory = $initialDirectory
            $OpenFileDialog.filter = "EXE Files | *.exe" 
            $OpenFileDialog.Title = $Title 
            $OpenFileDialog.ShowDialog() | Out-Null 
            $OpenFileDialog.filename 
            Set-Variable -Name File -Value $OpenFileDialog -Scope global
            
            
            Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-noprofile -command &{Start-Process $($File.FileName)}" -WorkingDirectory $env:windir -PassThru
            $Output_LB.Items.Add("$(GD)   Programm successfully started as Admin.")
            File-Log -Permission User  
        }
    }
    else
    {
        if($FilePath_TB.Text -ne "")
        {
            if((Test-Path -Path $FilePath_TB.Text))
            {
                
                
                Set-Variable -Name File -Value $FilePath_TB.Text -Scope global
                Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -Credential $Credentials -ArgumentList "-noprofile -command &{Start-Process $($File.FileName)}" -WorkingDirectory $env:windir -PassThru
                $Output_LB.Items.Add("$(GD)   Programm successfully started as Admin.")
                File-Log -Permission Admin

            }
            else
            {
                [System.Windows.Forms.MessageBox]::Show('Path is invalid.', 'Error', 'Ok', 'Error')    
            }
        }
        elseif($FilePath_TB.Text -eq "")
        {
            $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog 
            $OpenFileDialog.initialDirectory = $initialDirectory
            $OpenFileDialog.filter = "EXE Files | *.exe" 
            $OpenFileDialog.Title = $Title 
            $OpenFileDialog.ShowDialog() | Out-Null 
            $OpenFileDialog.filename 
            Set-Variable -Name File -Value $OpenFileDialog -Scope global
            
            
            Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -Credential $Credentials -ArgumentList "-noprofile -command &{Start-Process $($File.FileName)}" -WorkingDirectory $env:windir -PassThru
            $Output_LB.Items.Add("$(GD)   Programm successfully started as Admin.")
            File-Log -Permission User  
        }  
    }
})
$Close_BT.Add_Click({
	$WindowUser.close()
})
## else
$Mode_CB.Items.Add("AD")
$Mode_CB.Items.Add("Local")

$WindowUser.ShowDialog()

}
