##Main menu
function Main-Menu
{
	do
	{
		Clear-Host
		Write-Host "======= PostgreSQL Menu======="
		"1.Get Available PostgreSQL Versions"
		"2.Download & Install"
		"3.Menu3"

		$menuresponse = Read-Host [Enter Selection]
		switch ($menuresponse) {
			"1" { PostgreSQLVersions }
			"2" { DownloadNInstall }
			"3" { sub-menu3 }
		}
	}
	until (1..3 -contains $menuresponse)
}

function sub-menu1
{
	do
	{
		Clear-Host
		Write-Host "1. Option 1 `n2. Option 2 `n3. Return to Main Menu"
		$menuresponse = Read-Host [Enter Selection]
		switch ($menuresponse) {
			"1" { Option-1 }
			"2" { Option-2 }
			"3" { Main-Menu }
		}
	}
	until (1..3 -contains $menuresponse)
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
			"2" { sub-menu2 }
			"B" { Main-Menu }
		}
	}
	until ("B" -contains $menuresponse)


}


function DownloadNInstall
{
	do
	{
        Clear-Host
    if(Test-PGInstalled){
        
        $msg = 'It seems that there is already PostgreSQL Installed on your system, Would like to remove it first? (Silent) [Y/N]'
        do {
            $response = Read-Host -Prompt $msg
        if ($response -eq 'y') {
            $UninstallPath = (Get-Childitem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ | ? { $_ -match "PostgreSQL" }).GetValue('UninstallString')
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
			Break
		}
		$selection = $menu.Item([int]$ans); Write-Host $selection
		Write-Host "Generating download link" -ForegroundColor Green

		$GetDownloadLink = "https://www.enterprisedb.com/postgresql-tutorial-resources-training?uuid="+($PostgreSQLWebData | ?{ $_.PostgreSQLVersion -contains $selection -and $_.field_os -eq $bit }).uuid
		Write-Host $GetDownloadLink
        
		$DownloadLink = ((Invoke-WebRequest -Uri $GetDownloadLink).links | Where-Object { $_.innerText -like "*Click here if your download does not start automatically.*" }).href
        Write-Host $DownloadLink

        Write-Host "initiate PostgreSQL installation"
		Invoke-WebRequest $DownloadLink -OutFile "$($ScriptPath)\Downloads\$($selection -replace '\.','_').exe"
        
        Wait-FileUnlock "$($ScriptPath)\Downloads\$($selection -replace '\.','_').exe"

        Start-Process -FilePath "$($ScriptPath)\Downloads\$($selection -replace '\.','_').exe" -ArgumentList "--mode unattended --superpassword $($AidocPass)" -Wait

        if(Test-PGInstalled){
            Write-Host "PostgreSQL installed successfully"
        }elseif(!(Test-PGInstalled)){
            Write-Host "Error occured Please contact your Administrator"
        }


        Write-Host "Creating user as superuser"
        #Create AidocApp user as superuser
        #--Get last created directory
        $psqlPath = "$($env:ProgramFiles)\PostgreSQL\$((gci $PostgreDirectory | ? { $_.PSIsContainer } | sort CreationTime)[-1].Name)\bin\psql"
        $env:PGPASSWORD = "$($aidocPass)";
        &"$($psqlpath)" -U postgres -c "CREATE ROLE $($AidocUser) LOGIN SUPERUSER PASSWORD '$($aidocPass)';"
            

        pause
        break;


	}
	until ($ans -contains "Q")


}