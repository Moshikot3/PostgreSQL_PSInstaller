function Test-PGInstalled
{

	try
	{
		(Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ | Where-Object { $_ -match "PostgreSQL*" }).GetValue('UninstallString')
	}
	catch
	{
		return $false
	}

	$true
}

function Wait-FileUnlock {
	param(
		[Parameter()]
		[IO.FileInfo]$File,
		[int]$SleepInterval = 500
	)
	while (1) {
		try {
			$fs = $file.Open('open','read','Read')
			$fs.Close()
			Write-Verbose "$file not open"
			return
		}
		catch {
			Start-Sleep -Milliseconds $SleepInterval
			Write-Verbose '-'
		}
	}
}
