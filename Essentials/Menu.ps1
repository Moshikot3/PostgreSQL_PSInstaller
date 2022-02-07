##Main menu
function Main-Menu
{
	do
	{
		Clear-Host
		Write-Host "======= PostgreSQL Menu======="
		"1.Get Available PostgreSQL Versions"
		"2.Download & Install"

		$menuresponse = Read-Host [Enter Selection]
		switch ($menuresponse) {
			"1" { PostgreSQLVersions }
			"2" { DownloadNInstall }
		}
	}
	until (1..2 -contains $menuresponse)
}

## Get Available PostgreSQL Versions
function PostgreSQLVersions
{
	do
	{
		Clear-Host
		Write-Host "PostgreSQL Available versions:"
		"=============================="
		$Versions
		"=============================="
		Write-Host "B. Back to Main Menu" -ForegroundColor Yellow

		$menuresponse = Read-Host [Enter Selection]
		switch ($menuresponse) {
			"1" { PostgreSQLVersions; continue }
			"B" { Main-Menu }
		}
	}
	until ("B" -contains $menuresponse)


}


function DownloadNInstall
{
	do
	{
		Start-Transcript -Path "$($ScriptPath)\logs\PostgreSQL_$datetime.log"
		Clear-Host
		if (Test-PGInstalled) {

			$msg = 'It seems that there is already PostgreSQL Installed on your system, Would you like to remove it first? (Silent) [Y/N]'
			do {
				$response = Read-Host -Prompt $msg
				if ($response -eq 'y') {
					$UninstallPath = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ | Where-Object { $_ -match "PostgreSQL" }).GetValue('UninstallString')
					Write-Host "Removing PostgreSQL, Please Wait"
					Start-Process -FilePath $UninstallPath -ArgumentList "--mode unattended --unattendedmodeui none" -Wait

					Remove-Item -Recurse -Force "$($env:ProgramFiles)\PostgreSQL\" -ErrorAction SilentlyContinue
					break;
				}
			} until ($response -eq 'n')


		}

		Clear-Host
		Write-Host "Select PostgreSQL version to install:"
		"=============================="

		$services = $Versions
		$menu = @{}
		for ($i = 1; $i -le $services.count; $i++)
		{ Write-Host "$i. $($services[$i-1])"
			$menu.Add($i,($services[$i - 1])) }
		Write-Host "B. Back to Main Menu"

		$ans = Read-Host '[Enter selection]'
		if (("B" -contains $ans) -or ($ans -notin 1..$($services.count))) {
			Main-Menu
			break
		}
		$selection = $menu.Item([int]$ans); Write-Host $selection
		Write-Host "Generating download links" -ForegroundColor Green

		$GetDownloadLink = "https://www.enterprisedb.com/postgresql-tutorial-resources-training?uuid=" + ($PostgreSQLWebData | Where-Object { $_.PostgreSQLVersion -contains $selection -and $_.field_os -eq $bit }).uuid
		Write-Host $GetDownloadLink

		$DownloadLink = ((Invoke-WebRequest -Uri $GetDownloadLink).links | Where-Object { $_.innerText -like "*Click here if your download does not start automatically.*" }).href
		Write-Host $DownloadLink

		Invoke-WebRequest $DownloadLink -OutFile "$($ScriptPath)\Downloads\$($selection -replace '\.','_').exe"

		Wait-FileUnlock "$($ScriptPath)\Downloads\$($selection -replace '\.','_').exe"
		Write-Host "Initiate PostgreSQL installation"

		Start-Process -FilePath "$($ScriptPath)\Downloads\$($selection -replace '\.','_').exe" -ArgumentList "--mode unattended --superpassword $($AidocPass) --install_runtimes 0" -Wait

		if (Test-PGInstalled) {
			Write-Host "PostgreSQL installed successfully"
		} elseif (!(Test-PGInstalled)) {
			throw "Error with installation occured Please contact your Administrator$($error[0])"
		}

		$lastpginstalled = (Get-ChildItem "$($env:ProgramFiles)\PostgreSQL" | Where-Object { $_.PSIsContainer } | sort CreationTime)[-1].Name
		if ((Get-Service -Name "postgresql$($lastinstallbit)$($lastpginstalled)" -ErrorAction Stop).Status -ne 'Running') {
			try { Start-Service -Name "postgresql$($lastinstallbit)$($lastpginstalled)" }
			catch { throw "PostgreSQL Service could not be started. $($error[0])" }

		}

		Remove-Item "$($ScriptPath)\Downloads\$($selection -replace '\.','_').exe" -Force

		Write-Host "Creating $($aidocuser) user"
		#Create AidocApp user as superuser
		#--Get last created directory
		$psqlPath = "$($env:ProgramFiles)\PostgreSQL\$($lastpginstalled)\bin\"
		$env:PGPASSWORD = "$($aidocPass)";

		#Create users and databases
		& "$($psqlpath)psql.exe" -c "create user $($aidocuser) password '$($aidocpass)';" "user=postgres dbname=postgres password=$($aidocpass)" | Out-Null
		#&"$($psqlpath)psql.exe" -U postgres -c "CREATE ROLE $($AidocUser) LOGIN SUPERUSER PASSWORD '$($aidocPass)';"

		& "$($psqlpath)psql.exe" -c "CREATE DATABASE $($aidocdb)" "user=postgres dbname=postgres password=$($aidocpass)"

		& "$($psqlpath)psql.exe" -c "GRANT ALL PRIVILEGES ON DATABASE $($aidocdb) TO $($aidocuser);" "user=postgres dbname=postgres password=$($aidocpass)"

		& "$($psqlpath)psql.exe" -l "user=$($aidocuser) dbname=$($aidocdb) password=$($aidocpass)"

		#Check if database is exist
		if ((& "$($psqlpath)psql.exe" -l "user=$($aidocuser) dbname=$($aidocdb) password=$($aidocpass)" | Out-String) -match "aidocapp*") {
			Write-Host "Database $($aidocdb) has been created with privileges for user $($aidocuser)" -ForegroundColor Green
		} else {

			throw "Somthing went wrong while creating $($aidocuser) user and database $($dbname)"
		}
		Pause
		#End
		Stop-Transcript
		Main-Menu
		break


	}
	until ($ans -contains "Q")


}
