$String = Read-Host "String"
$Passphrase = Read-Host "Passphrase"
$SaltCrypto = Read-Host "Slat"
$INITPW = Read-Host "Init"
function Encrypt-String($String=$string, $Passphrase=$Passphrase, $salt=$SaltCrypto, $init=$INITPW, [switch]$arrayOutput) 
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
Encrypt-String