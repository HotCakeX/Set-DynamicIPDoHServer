
 # test if the session has administrator privileges
 # https://devblogs.microsoft.com/scripting/check-for-admin-credentials-in-a-powershell-script/
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`

    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"

    Break
}


  # main function 
  function Set-DynamicIPDoHServer {

    [Alias("set-ddoh")]

    param ($DoHTemplate, $DoHDomain)



  # check if DohTemplate and DohDomain are not empty
  if ((-NOT ($dohTemplate)) -or (-NOT ($DoHDomain)))
  {
    write-host "DoH template and DoH domain are both required" -ForegroundColor red
    
    Break
    }

  # DoH template must start with "HTTPS:// and needs a / after the TLD. the Add-DnsClientDohServerAddress cmdlet will fail if there is no / after the TLD"
  if ($dohTemplate -notmatch '^https\:\/\/.+\..+\/.*')

  {
    write-host "The DNS over HTTPS (DoH) template starts with HTTPS:// and needs a / after the TLD" -ForegroundColor Magenta
    
    Break
    }

 # DoH domain must have a proper TLD
 if ($DohDomain -notmatch '^.+\..+')

  {
    write-host "DoH Domain isn't right" -ForegroundColor Magenta

    Break
  }

  



# error handling for the entire function - to make sure there is no error before attempting to create the scheduled task
try { 





# get the currently active network interface/adapter that is being used for Internet access



# This gets the correct network adapter if no VPN or Hyper-V virtual switch is being used
$ActiveNetworkInterface = Get-NetRoute -DestinationPrefix '0.0.0.0/0', '::/0' |
          Sort-Object -Property { $_.InterfaceMetric + $_.RouteMetric } -Top 1 -PipelineVariable ActiveAdapter |
           Get-NetAdapter | Where-Object {$_.ifIndex -eq $ActiveAdapter.ifIndex}


        
           $ActiveNetworkInterface.InterfaceDescription
           

      # checks if the detected active interface from the previous step is virtual, if it is, checks if it's an external virtual Hyper-V network adapter or VPN virtual network adapter
        if ((Get-NetAdapter | Where-Object { $_.InterfaceGuid -eq $ActiveNetworkInterface.InterfaceGuid}).Virtual)
        {
            Write-Host "Interface is virtual" -ForegroundColor Magenta

            # if it's an external virtual Hyper-V network adapter, it must be the correct adapter
            if ($ActiveNetworkInterface.InterfaceDescription -like "*Hyper-V Virtual Ethernet Adapter*"  )

            {

                Write-Host "this is virtual but OK because it's Hyper-V External switch that is active" -ForegroundColor Magenta
                   $ActiveNetworkInterface = $ActiveNetworkInterface
            }
              
# if the detected active network adapter is virtual and not virtual external Hyper-V network adapter, which means it is VPN virtual network adapter, choose the second prioritized adapter/interface based on route metric
# tested with Cloudflare WARP, Wintun, OpenVPN and has been always successful in detecting the correct network adapter/interface         
              else {

                write-host "detected active network adapter is virtual but not virtual Hyper-V adapter, choosing the second prioritized adapter/interface based on route metric" -ForegroundColor Yellow


                $ActiveNetworkInterface = Get-NetRoute -DestinationPrefix '0.0.0.0/0', '::/0' |
          Sort-Object -Property { $_.InterfaceMetric + $_.RouteMetric } -Top 2 -PipelineVariable ActiveAdapter |
           Get-NetAdapter | Where-Object {$_.ifIndex -eq $ActiveAdapter.ifIndex}
            }

          

        }

       
        write-host "final correct adapter" -ForegroundColor Magenta
        $ActiveNetworkInterface


        # luckily, it's not normally possible to change description of network interfaces/adapters
        # so it is a solid criteria for choosing our network adapter/interface
        # https://serverfault.com/questions/862065/changing-nic-interface-descriptions-in-windows#:~:text=You%20can%27t%20change%20the%20name%20of%20the%20NICs,you%27ll%20have%20to%20do%20lots%20of%20name%20swapping


  












# check if there is any IP address already associated with "$DoHTemplate" template
$oldIPs = (Get-DnsClientDohServerAddress | Where-Object {$_.dohTemplate -eq $DoHTemplate}).serveraddress

# if there is, remove them
if ($oldIPs)
{

$oldIPs | ForEach-Object {

    remove-DnsClientDohServerAddress -ServerAddress $_

}
}

# reset the network adapter's DNS servers back to default to take care of any IPv6 strays
Set-DnsClientServerAddress -InterfaceIndex $ActiveNetworkInterface.ifIndex -ResetServerAddresses -ErrorAction Stop


# only uncomment for debugging purposes
# Write-Host "info about the selected network interface/adapter" -ForegroundColor Magenta

# $ActiveNetworkInterface.Name
# $ActiveNetworkInterface.InterfaceGuid
# $ActiveNetworkInterface.ifIndex






# delete all other previous DoH settings for ALL Interface - Windows behavior in settings when changing DoH settings is to delete all DoH settings for the interface we are modifying 
# but we need to delete all DoH settings for ALL interfaces in here because every time we virtualize a network adapter with external switch of Hyper-V,
# Hyper-V assigns a new GUID to it, so it's better not to leave any leftover in the registry and clean up after ourselves

remove-item "HKLM:System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\*" -Recurse




# get the new IPv4s for $DoHDomain
try {
  Write-Host "Using System DNS to get IPv4s for $DoHDomain" -ForegroundColor Magenta;
  $NewIPsV4 = (Resolve-DnsName -Name $DoHDomain -Type A -ErrorAction Stop).ipaddress 
}
catch {
  Write-Host "System DNS failed, using 1.1.1.1 from Cloudflare to to get IPv4s for $DoHDomain" -ForegroundColor Magenta;
  $NewIPsV4 = (Resolve-DnsName -Name $DoHDomain -Server 1.1.1.1 -Type A).ipaddress
} 





# loop through each IPv4
$NewIPsV4 | foreach-Object {


# defining registry path for DoH settings of the $ActiveNetworkInterface based on its GUID for IPv4
$Path = "HKLM:System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$($ActiveNetworkInterface.InterfaceGuid)\DohInterfaceSettings\Doh\$_"

# associating the new IPv4s with our DoH template in Windows DoH template predefined list
Add-DnsClientDohServerAddress -ServerAddress $_ -DohTemplate $DoHTemplate -AllowFallbackToUdp $False -AutoUpgrade $True


# add DoH settings for the specified Network adapter based on its GUID in registry
# value 1 for DohFlags key means use automatic template for DoH, 2 means manual template, since we add our template to Windows, it's predefined so we use value 1
New-Item -Path $Path -Force | Out-Null  
New-ItemProperty -Path $Path -Name "DohFlags" -Value 1 -PropertyType Qword -Force


 
}




# get the new IPv6s for $DoHDomain
try {
    Write-Host "Using System DNS to get IPv6s for $DoHDomain" -ForegroundColor Magenta;
    $NewIPsV6 = (Resolve-DnsName -Name $DoHDomain -Type AAAA -ErrorAction Stop).ipaddress 
  }
  catch {
    Write-Host "System DNS failed, using 1.1.1.1 from Cloudflare to get IPv6s for $DoHDomain" -ForegroundColor Magenta;
    $NewIPsV6 = (Resolve-DnsName -Name $DoHDomain -Server 1.1.1.1 -Type AAAA).ipaddress
  } 

# loop through each IPv6
$NewIPsV6 | foreach-Object {


# defining registry path for DoH settings of the $ActiveNetworkInterface based on its GUID for IPv6
$Path = "HKLM:System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$($ActiveNetworkInterface.InterfaceGuid)\DohInterfaceSettings\Doh6\$_"


# associating the new IPv6s with our DoH template in Windows DoH template predefined list
Add-DnsClientDohServerAddress -ServerAddress $_ -DohTemplate $DoHTemplate -AllowFallbackToUdp $False -AutoUpgrade $True


# add DoH settings for the specified Network adapter based on its GUID in registry
# value 1 for DohFlags key means use automatic template for DoH, 2 means manual template, since we already added our template to Windows, it's considered predefined, so we use value 1
New-Item -Path $Path -Force | Out-Null  
New-ItemProperty -Path $Path -Name "DohFlags" -Value 1 -PropertyType Qword -Force


 
}





# gather IPv4s and IPv6s all in one place
$NewIPs = $NewIPsV4 + $NewIPsV6


# $NewIPs = $NewIPs -join ','
# apparently that wasn't needed and it already works


# this is responsible for making the changes in Windows settings UI > Network and internet > $ActiveNetworkInterface.Name
Set-DnsClientServerAddress -ServerAddresses $NewIPs -InterfaceIndex $ActiveNetworkInterface.ifIndex -ErrorAction Stop


# clear DNS client Cache
Clear-DnsClientCache




   }
catch { write-host "these errors occured after running the module" -ForegroundColor white
   
      $_

      $ModuleErrors = $_
    
    }


if (!$ModuleErrors) {
  
   write-host "No errors occured when running the module, creating the scheduled task now if it's not already been created" -ForegroundColor green 







# create a scheduled task
if (-NOT (Get-ScheduledTask -TaskName "Dynamic DoH Server IP check" -ErrorAction SilentlyContinue))
{
    
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-executionPolicy bypass -command `"set-ddoh -DoHTemplate '$DoHTemplate' -DoHDomain '$DoHDomain'`""

$TaskPrincipal = New-ScheduledTaskPrincipal -LogonType S4U -UserId $env:USERNAME -RunLevel Highest

$trigger = 
  New-ScheduledTaskTrigger `
    -Once -At (Get-Date).AddSeconds(50) `
    -RandomDelay (New-TimeSpan -Seconds 30) `
    -RepetitionInterval (New-TimeSpan -Minutes 5)

Register-ScheduledTask -Action $action -Trigger $trigger -Principal $TaskPrincipal -TaskPath "DDoH" -TaskName "Dynamic DoH Server IP check" -Description "Checks for New IPs of our Dynamic DoH server"

$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility Win8 -StartWhenAvailable

Set-ScheduledTask -TaskPath "DDoH" -TaskName "Dynamic DoH Server IP check" -Settings $TaskSettings 

}



}




} # end of main function


