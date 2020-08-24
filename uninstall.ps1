$host.UI.RawUI.WindowTitle = "Security-App Uinstall"

[string]$Root = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])

Write-Host -ForegroundColor Yellow "[INFO] `t Removing clink."
Start-Process cmd.exe -ArgumentList '/c choco uninstall clink -y' -Wait
Write-Host -ForegroundColor Yellow "[OK] `t Done removing clink."
"`n"
sleep -sec 3
Write-Host -ForegroundColor Yellow "[INFO] `t Uninstalling chocolatey direcories."
Remove-Item -Path C:\ProgramData\chocolatey -Recurse -Force
Write-Host -ForegroundColor Yellow "[OK] `t Done uninstalling chocolatey."
"`n"
Write-Host -ForegroundColor Yellow "[INFO] `t Deleting direcories."
$Files = Get-ChildItem -Path $Root -Recurse
ForEach-Object($file in $Files)
{
    Remove-Item -Path $file.FullName -Force
}
Write-Host -ForegroundColor Yellow "[OK] `t Done deleting direcories."
Write-Output -InputObject "Press any key to continue..."
[void]$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
