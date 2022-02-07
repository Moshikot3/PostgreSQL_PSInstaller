##Main
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if(!(Test-Connection -computername www.enterprisedb.com -quiet -Count 2)){
    throw "Script can't connect to Enterprisedb.com (PostgreSQL download source), Please check internet connection"
}


$datetime = (Get-Date -Format 'dd_mm_yy__HH_mm')
$ProgressPreference = 'SilentlyContinue'
#$ScriptPath = "D:\PostgreSQL"
$ScriptPath = $PSScriptRoot
 ."$($Scriptpath)\Essentials\Checks.ps1"
  ."$($Scriptpath)\Essentials\Menu.ps1"

$aidocDB = "aidocapp"
$AidocUser = "aidocapp"
$key = gc "$($Scriptpath)\Secret\key.key"
$Key -join ',' | out-null
$secure = gc "$($Scriptpath)\Secret\Encrypted.txt" | ConvertTo-SecureString -key $Key
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
$aidocpass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

try{

##New Scraping tool
$Page = Invoke-WebRequest 'https://www.enterprisedb.com/downloads/postgres-postgresql-downloads'
$Unicode = [System.Text.Encoding]::Unicode.GetBytes($Page.Content)
$Document = New-Object -Com 'HTMLFile'
if ($Document.IHTMLDocument2_Write) { $Document.IHTMLDocument2_Write($Unicode) } else { $Document.write($Unicode) }
$Document.Close()
$Data = $Document.getElementById('__NEXT_DATA__').innerHTML |ConvertFrom-Json
#$Data |ConvertTo-Json -Depth 10

foreach ($ScrapperAddVersion in $Data.props.pageProps.postgreSQLDownloads.products){
$Ver= -join("$($ScrapperAddVersion.field_installer_version)", ".", "$($ScrapperAddVersion.field_sub_version)");
$ScrapperAddVersion | Add-Member -MemberType NoteProperty -Name "PostgreSQLVersion" -value $Ver

[Array]$PostgreSQLWebData += $ScrapperAddVersion

}
}catch{

throw "Error getting PostgreSQL versions. $($error[0])"


}

if ([Environment]::Is64BitOperatingSystem) {
	$bit = "Windows x86-64"
    $lastinstallbit = "-x64-"

} else {
	$bit = "Windows x86-32"
    $lastinstallbit = "-"
}

##Collect all Available PostgreSQL Versions
$Versions = ($PostgreSQLWebData | ?{$_.field_os -eq $bit}).PostgreSQLVersion


if (!(Test-Path $ScriptPath\Downloads)) {
	New-Item -ItemType Directory -Path $ScriptPath\Downloads
}

if (!(Test-Path $ScriptPath\logs)) {
	New-Item -ItemType Directory -Path $ScriptPath\logs
}

##Start-Menu
Main-Menu
