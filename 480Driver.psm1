Import-Module '480-utils' -Force
$conf = Get-480Config -config_path "./480.json"
connect480 -server $conf.vcenter_server
$sit = read-host "which CSV will you be using for deployment? (ex. sit1.csv)"
Copy-Snapshot -situation $sit
Set-IPInventory
read-host 'exit'