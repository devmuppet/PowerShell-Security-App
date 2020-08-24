$Encrypted = Read-Host "String"
$Passphrase = Read-Host "Passphrase"
$SaltCrypto = Read-Host "Slat"
$INITPW = Read-Host "Init"

function Decrypt-String($Encrypted=$Encrypted, $Passphrase=$Passphrase, $salt=$SaltCrypto, $init=$INITPW) 
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
Decrypt-String