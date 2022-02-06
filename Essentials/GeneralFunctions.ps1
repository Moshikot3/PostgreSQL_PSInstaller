function Uninstall-App {
    Write-Output "Uninstalling $($args[0])"
    foreach($obj in Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall") {
        $dname = $obj.GetValue("DisplayName")
        if ($dname -contains $args[0]) {
            $uninstString = $obj.GetValue("UninstallString")
            foreach ($line in $uninstString) {
                $found = $line -match '(\{.+\}).*'
                If ($found) {
                    $appid = $matches[1]
                    Write-Output $appid
                    start-process "msiexec.exe" -arg "/X $appid /qb" -Wait
                }
            }
        }
    }
}