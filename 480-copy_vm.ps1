#Connect
$vserver="10.0.17.3"
Connect-VIServer($vserver)


function Copy-VM(){
    
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
    $target_vm = Get-VM "DC1"
    $snap = Get-Snapshot -VM $target_vm -Name "Base"
    #$dest_folder = Get-Folder -Name $dest_folder
    $newvmname = Read-Host -prompt "what is the new vm's name?"
    $new_vm = New-VM -Name $newvmname -VM $target_vm -LinkedClone -ReferenceSnapshot $snap -VMHost $vm_host -Datastore $datastore 
    $new_vm | new-snapshot -Name "Base"
    Read-Host -Prompt "exit"

}
Copy-VM
