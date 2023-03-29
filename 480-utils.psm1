################################################################################################################
function 480banner() {
    $msg = '
    ___   ___  ________  ________          ___  ___  _________  ___  ___       ________      
    |\  \ |\  \|\   __  \|\   __  \        |\  \|\  \|\___   ___\\  \|\  \     |\   ____\     
    \ \  \\_\  \ \  \|\  \ \  \|\  \       \ \  \\\  \|___ \  \_\ \  \ \  \    \ \  \___|_    
     \ \______  \ \   __  \ \  \\\  \       \ \  \\\  \   \ \  \ \ \  \ \  \    \ \_____  \   
      \|_____|\  \ \  \|\  \ \  \\\  \       \ \  \\\  \   \ \  \ \ \  \ \  \____\|____|\  \  
             \ \__\ \_______\ \_______\       \ \_______\   \ \__\ \ \__\ \_______\____\_\  \ 
              \|__|\|_______|\|_______|        \|_______|    \|__|  \|__|\|_______|\_________\
                                                                                  \|_________|
                                                                                              
                                                                                              
    '
    write-host $msg
}
################################################################################################################
################################################################################################################
function connect-480([string] $server) {
    $conn = $global:DefaultVIServer
    if ($conn){
        $msg = "Already connected to: {0}" -f $conn
        write-host -ForegroundColor "Green" $msg
    }else {
        Connect-VIServer -Server $server
    }
}
################################################################################################################
################################################################################################################
function Get-480Config([string] $config_path){
    $conf=$null
    if(Test-Path $config_path) {
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        $msg = "Using config at {0}" -f $config_path
        write-host -ForegroundColor "Green" $msg
    }else {
        write-host -ForegroundColor "Yellow" "No config there"
    }
    return $conf
}
################################################################################################################
################################################################################################################
function Copy-VM(){
    
    #[cmdletbinding()]
    #param(
       # $dest_name,
       # $vm_host,
        #$datastore,
        #$dest_folder,
       # $target_vm
   # )
    
    # This function runs the cloning process -
    # - based on inputs/ hard coded inputs 
    # These inputs can be set in the config -
    # - file and used with the other function, this one is just all in one file.
    #######################################

    $vm_host = Get-VMHost -Name "192.168.7.34"
    $datastore = Get-Datastore -Name "datastore1"
    $target_vm = Get-VM "480-fw1"
    $snap = Get-Snapshot -VM $target_vm -Name "Base"
    #$dest_folder = Get-Folder -Name $dest_folder
    $newvmname = Read-Host -prompt "what is the new vm's name?"
    $new_vm = New-VM -Name $newvmname -VM $target_vm -LinkedClone -ReferenceSnapshot $snap -VMHost $vm_host -Datastore $datastore 
    $new_vm | new-snapshot -Name "Base"
    

}
################################################################################################################
################################################################################################################
function Copy-Snapshot{
    [cmdletbinding()]
    param(
        $situation
    )

    # This function runs the cloning process -
    # - based on snapshots 
    #######################################
    
    Remove-Item ./nameinventory.txt
    $namecount = 0

    Import-Csv $situation | ForEach-Object {

        $namecount = 0
        $snapshot = $($_.snapshot)
        $dest_name = $($_.dest_name)
        $datastore = $($_.datastore)
        $dest_network = $($_.dest_network)
        $dest_folder = $($_.dest_folder)
        $vm_host = $($_.vm_host)
        #$vcenter_server = $($_.vcenter_server)
        $target_vm = $($_.target_vm)
        $count = $($_.count)

        for ($var = 1; $var -le $count; $var++){
            
            $namecount++
            $dest_name1 = $dest_name + [string]$namecount
            $vm_host = Get-VMHost -Name $vm_host
            $datastore = Get-Datastore -Name $datastore
            #$dest_folder = Get-Folder -Name $dest_folder
            $target_vm = Get-VM $target_vm
            $snap = Get-Snapshot -VM $target_vm -Name $snapshot
            $global:new_vm = New-VM -Name $dest_name1 -VM $target_vm -LinkedClone -ReferenceSnapshot $snap -VMHost $vm_host -Datastore $datastore -Location $dest_folder
            $global:new_vm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $dest_network -Confirm:$false
            Start-VM -VM $dest_name1
            $dest_name1 | out-file -filepath ./nameinventory.txt -append
        }
    }
}
################################################################################################################
################################################################################################################
function Set-IPInventory{
    
    #This function creates an inventory file of the created machines.
    #This function is dynamic as it deletes the previous inventory file everytime it runs.
    # - This allows the function to dynamically target the hosts created in each process and feed that info to ansible
    ###############################################
    Remove-Item ./ipinventory.txt
    write-host "grabbing Ips, please wait this takes around 60 seconds. "
    Start-Sleep -Seconds 60
    $hostnames = Get-Content -Path ./nameinventory.txt
    ForEach ($name in $hostnames) {
        write-host $name 
        get-vm $name 
        $nadap = Get-NetworkAdapter -VM $name
        Write-Host $nadap.MacAddress
        $ip = (Get-VM $name).Guest.IPAddress[0] 
        write-host $ip + "check"
        $ip | out-file -append -filepath ./ipinventory.txt
    }
}
################################################################################################################
################################################################################################################
function New-Network {
    [cmdletbinding()]
    param (
        [string]$switchname,
        [string]$portgroupname,
        #[string]$adaptername,
        #[string]$adapterip,
        [string]$adaptersubnetmask = '255.255.255.0'
        )

    # Get the host object
    $VMhost = Get-VMHost

    # Get the network adapter object
    #$adapter = Get-VMHostNetworkAdapter -VMHost $VMhost -Name $AdapterName

    # Create a new virtual switch
    New-VirtualSwitch -VMHost $VMhost -Name $SwitchName -NumPorts 128 -Confirm:$false

    # Create a new port group on the virtual switch
    New-VirtualPortGroup -VirtualSwitch (Get-VirtualSwitch -VMHost $VMhost -Name $SwitchName) -Name $PortGroupName -VLanId 0

    # Create a new virtual NIC and connect it to the port group
    #$nic = New-VMHostNetworkAdapter -PortGroup $PortGroupName -VirtualSwitch $SwitchName -VMHost $VMhost -Confirm:$false

    # Configure the IP address and subnet mask on the virtual NIC
    #$nic | Set-VMHostNetworkAdapter -IP $AdapterIPAddress -SubnetMask $AdapterSubnetMask -Confirm:$false
}
################################################################################################################
################################################################################################################
Function Get-IP {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$VMName
    )

    # Get VM object
    $vm = Get-VM -Name $VMName

    # Get network adapter object
    $nic = Get-NetworkAdapter -VM $vm #| Select-Object -First 1

    # Get IP address, VM name, and MAC address
    #$ipAddress = $nic.IPAddress
    $vmName = $vm.Name
    $macAddress = $nic.MacAddress

    $ipaddr = (Get-VM -Name $vm).Guest.IPAddress[0]
    
    # Output results
    [PSCustomObject]@{
        "IPAddress" = $ipaddr
        "VMName" = $vmName
        "MACAddress" = $macAddress
    }
}
################################################################################################################
################################################################################################################
function VM-Starter{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$vmName
    )

    # Get VM name from user input
    $vmName = Read-Host "Enter VM name to start"

    # Get VM object by name
    $vm = Get-VM -Name $vmName

    # Check if VM exists
    if ($vm) {
    # Start VM
    Start-VM -VM $vm
    Write-Host "VM $vmName started."
    } else {
    Write-Host "VM $vmName not found."
    }
}
################################################################################################################
################################################################################################################
function Set-Network{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$vmName,
        [string]$netname
    )

    Get-Vm -Name $vmName | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $netname -Confirm:$false
}
################################################################################################################

480banner
