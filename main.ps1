##Main
$ProgressPreference = 'SilentlyContinue'
$ScriptPath = "D:\PostgreSQL"
 ."$($Scriptpath)\Essentials\Checks.ps1"
  ."$($Scriptpath)\Essentials\Menu.ps1"


$AidocUser = "aidocapp"
$key = gc "$($Scriptpath)\Secret\key.key"
$Key -join ","
$secure = gc "$($Scriptpath)\Secret\Encrypted.txt" | ConvertTo-SecureString -key $Key
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
$aidocpass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)


    ##New Scraping tool
    $Page = Invoke-WebRequest 'https://www.enterprisedb.com/downloads/postgres-postgresql-downloads'
    $Unicode = [System.Text.Encoding]::Unicode.GetBytes($Page.Content)
    $Document = New-Object -Com 'HTMLFile'
    if ($Document.IHTMLDocument2_Write) { $Do2cument.IHTMLDocument2_Write($Unicode) } else { $Document.write($Unicode) }
    $Document.Close()
    $Data = $Document.getElementById('__NEXT_DATA__').innerHTML | ConvertFrom-Json

    #Add full version number to array
    foreach ($ScrapperAddVersion in $Data.props.pageProps.postgreSQLDownloads.products){
    $Ver= -join("$($ScrapperAddVersion.field_installer_version)", ".", "$($ScrapperAddVersion.field_sub_version)");
    $ScrapperAddVersion | Add-Member -MemberType NoteProperty -Name "PostgreSQLVersion" -value $Ver
     [Array]$PostgreSQLWebData += $ScrapperAddVersion
        }


if ([Environment]::Is64BitOperatingSystem) {
	$bit = "Windows x86-64"
} else {
	$bit = "Windows x86-32"
}

##Collect all Available PostgreSQL Versions
$Versions = ($PostgreSQLWebData | ?{$_.field_os -eq $bit}).PostgreSQLVersion


if (!(Test-Path $ScriptPath\Downloads)) {
	New-Item -ItemType Directory -Path $ScriptPath\Downloads
}

Main-Menu
