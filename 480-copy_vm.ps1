#Connect
$vserver="480vcenter.guinther.local"
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

    $vm_host = Get-VMHost -Name "esxiguinther"
    $datastore = Get-Datastore -Name "datastore1"
    $target_vm = Get-VM "dc1-sam.guinther.local"
    $snap = Get-Snapshot -VM $target_vm -Name "Base"
    #$dest_folder = Get-Folder -Name $dest_folder
    $linkedname = "{0}.linked" -f $target_vm.name
    $linkedvm = New-VM -LinkedClone -Name $linkedname -VM $target_vm -ReferenceSnapshot $snap -VMHost $vm_host -Datastore $datastore
    $new_vm = New-VM -Name "dc2-sam" -VM $linkedvm -VMHost $vm_host -Datastore $datastore 
    $new_vm | new-snapshot -Name "Base"
    $linkedvm | Remove-VM

}

Copy-VM
