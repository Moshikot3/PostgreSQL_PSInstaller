$ScriptPath = "D:\PostgreSQL"



# encrypt
$key = 202,144,73,88,228,1,7,104,95,212,137,87,125,201,80,75,53,18,39,108,60,218,212,151,239,241,34,117,106,184,212,179 | out-file "$($Scriptpath)\Secret\key.key"
$key = gc "$($Scriptpath)\Secret\key.key"
$Key -join ","

$secret = "aidcopass"

$secretSecured = ConvertTo-SecureString $secret -AsPlainText -Force
$encrypted = ConvertFrom-SecureString -secureString $secretSecured -key $key | Out-file "$($Scriptpath)\Secret\Encrypted.txt"


# decrypt
$key = gc "$($Scriptpath)\Secret\key.key"
$Key -join ","
$secure = gc "$($Scriptpath)\Secret\Encrypted.txt" | ConvertTo-SecureString -key $Key
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
$decrypted = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
