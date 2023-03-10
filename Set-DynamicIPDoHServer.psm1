# test if the session has administrator privileges
# https://devblogs.microsoft.com/scripting/check-for-admin-credentials-in-a-powershell-script/
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
      [Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
  Break
}
function Set-DynamicIPDoHServer {
  [Alias("set-ddoh")]
  [CmdletBinding(
    HelpURI = "https://github.com/HotCakeX/Set-DynamicIPDoHServer"
  )
  ]
  param (
    [Parameter(Mandatory = $true)][String]$DoHTemplate,
    [Parameter(Mandatory = $true)][String]$DoHDomain
  ) 
  # DoH template must start with "HTTPS:// and needs a / after the TLD. the Add-DnsClientDohServerAddress cmdlet will fail if there is no / after the TLD"
  if ($dohTemplate -notmatch '^https\:\/\/.+\..+\/.*') {
    write-host "DNS over HTTPS (DoH) template starts with HTTPS:// and needs a / after the TLD" -ForegroundColor Magenta 
    Break
  }
  # DoH domain must have a proper TLD
  if ($DohDomain -notmatch '^.+\..+') {
    write-host "DoH Domain isn't right" -ForegroundColor Magenta
    Break
  }
  # error handling for the entire function - to make sure there is no error before attempting to create the scheduled task
  try {
    # get the currently active network interface/adapter that is being used for Internet access
    # This gets the top most active adapter based on route metric
    $ActiveNetworkInterface = Get-NetRoute -DestinationPrefix '0.0.0.0/0', '::/0' |
    Sort-Object -Property { $_.InterfaceMetric + $_.RouteMetric } -Top 1 -PipelineVariable ActiveAdapter |
    Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.ifIndex -eq $ActiveAdapter.ifIndex }
    
    # check if the top most active adapter that we got has an interface index
    # Windows built-in VPN client connections don't have interface index and don't appear in Get-Netadapter results
    if (!$ActiveNetworkInterface) {             
      Write-Host "This adapter doesn't even exist in get-Netadapter results and doesn't have interface index, must be built-in Windows VPN client adapter" -ForegroundColor Blue         
      # then we get the 2nd adapter from the top
      $ActiveNetworkInterface = Get-NetRoute -DestinationPrefix '0.0.0.0/0', '::/0' |
      Sort-Object -Property { $_.InterfaceMetric + $_.RouteMetric } -Top 2 |
      select-Object -skip 1 | select-Object -first 1 -PipelineVariable ActiveAdapter | 
      Get-NetAdapter | Where-Object { $_.ifIndex -eq $ActiveAdapter.ifIndex }
    }
    # if the top most adapter that we got has an interface index
    else {
      # check if the detected active interface from the previous step is virtual, if it is, checks if it's an external virtual Hyper-V network adapter or VPN virtual network adapter
      if ((Get-NetAdapter | Where-Object { $_.InterfaceGuid -eq $ActiveNetworkInterface.InterfaceGuid }).Virtual) {
        Write-Host "Interface is virtual, trying to find out if it's a VPN virtual adapter or Hyper-V External virtual switch" -ForegroundColor DarkYellow

        # if it's an external virtual Hyper-V network adapter, it must be the correct adapter
        if ($ActiveNetworkInterface.InterfaceDescription -like "*Hyper-V Virtual Ethernet Adapter*"  ) {
          Write-Host "The detected active network adapter is virtual, it's Hyper-V External switch" -ForegroundColor Blue
          $ActiveNetworkInterface = $ActiveNetworkInterface
        } 
        # if the detected active network adapter is virtual but Not virtual external Hyper-V network adapter, which means it is VPN virtual network adapter (but not Windows built-in VPN client),
        # choose the second prioritized adapter/interface based on route metric
        # tested with Cloudflare WARP (that doesn't create a separate adapter), Wintun, TAP, OpenVPN and has been always successful in detecting the correct network adapter/interface         
        else {
          write-host "Detected active network adapter is virtual but not virtual Hyper-V adapter, most likely a VPN virtual network adapter, choosing the second prioritized adapter/interface based on route metric" -ForegroundColor Cyan
          $ActiveNetworkInterface = Get-NetRoute -DestinationPrefix '0.0.0.0/0', '::/0' |
          Sort-Object -Property { $_.InterfaceMetric + $_.RouteMetric } -Top 2 |
          select-Object -skip 1 | select-Object -first 1 -PipelineVariable ActiveAdapter | 
          Get-NetAdapter | Where-Object { $_.ifIndex -eq $ActiveAdapter.ifIndex }
        }
      }
    }
    write-host "This is the final detected network adapter this module is going to set Secure DNS for" -ForegroundColor DarkMagenta
    $ActiveNetworkInterface
    # luckily, it's not normally possible to change description of network interfaces/adapters
    # so it is a solid criteria for choosing our network adapter/interface
    # https://serverfault.com/questions/862065/changing-nic-interface-descriptions-in-windows#:~:text=You%20can%27t%20change%20the%20name%20of%20the%20NICs,you%27ll%20have%20to%20do%20lots%20of%20name%20swapping

    # check if there is any IP address already associated with "$DoHTemplate" template
    $oldIPs = (Get-DnsClientDohServerAddress | Where-Object { $_.dohTemplate -eq $DoHTemplate }).serveraddress
    # if there is, remove them
    if ($oldIPs) {
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

    # Enables "TLS_CHACHA20_POLY1305_SHA256" Cipher Suite for Windows 11, if necessary, because it's disabled by default
    # cURL will need that cipher suite to perform encrypted DNS query, it uses Windows Schannel
    if (-NOT ((Get-TlsCipherSuite).name -contains "TLS_CHACHA20_POLY1305_SHA256"))
    { Enable-TlsCipherSuite -Name "TLS_CHACHA20_POLY1305_SHA256" }
    # delete all other previous DoH settings for ALL Interface - Windows behavior in settings when changing DoH settings is to delete all DoH settings for the interface we are modifying 
    # but we need to delete all DoH settings for ALL interfaces in here because every time we virtualize a network adapter with external switch of Hyper-V,
    # Hyper-V assigns a new GUID to it, so it's better not to leave any leftover in the registry and clean up after ourselves
    remove-item "HKLM:System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\*" -Recurse
    # get the new IPv4s for $DoHDomain
    # we use --ssl-no-revoke because when system DNS is unreachable, CRL check will fail in cURL.
    # it is OKAY, we're using trusted Cloudflare and Google servers the certificates of which explicitly mention their IP addresses (in Subject Alternative Name) that we are using to connect to them      
    $curlcmd = { param($url)
      $IPs = curl --ssl-no-revoke --max-time 10 --tlsv1.3 --tls13-ciphers TLS_CHACHA20_POLY1305_SHA256 --http2 -H "accept: application/dns-json" $url;
      $IPs = ( $IPs | ConvertFrom-Json).answer.data
      return $IPs
    }
    Write-Host "Using the main Cloudflare Encrypted API to resolve $DoHDomain" -ForegroundColor Green;
    $NewIPsV4 = &$curlcmd "https://1.1.1.1/dns-query?name=$dohdomain&type=A"    
    if (!$NewIPsV4) {
      Write-Host "First try failed, now using the secondary Encrypted Cloudflare API to to get IPv4s for $DoHDomain" -ForegroundColor Blue;
      $NewIPsV4 = &$curlcmd "https://1.0.0.1/dns-query?name=$dohdomain&type=A"
    }
    if (!$NewIPsV4) {
      Write-Host "Second try failed, now using the main Encrypted Google API to to get IPv4s for $DoHDomain" -ForegroundColor Yellow;
      $NewIPsV4 = &$curlcmd "https://8.8.8.8/resolve?name=$dohdomain&type=A"
    }
    if (!$NewIPsV4) {
      Write-Host "Third try failed, now using the second Encrypted Google API to to get IPv4s for $DoHDomain" -ForegroundColor DarkRed;
      $NewIPsV4 = &$curlcmd "https://8.8.4.4/resolve?name=$dohdomain&type=A"
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
    # we use --ssl-no-revoke because when system DNS is unreachable, CRL check will fail in cURL.
    # it is OKAY, we're using trusted Cloudflare and Google servers the certificates of which explicitly mention their IP addresses (in Subject Alternative Name) that we are using to connect to them
    Write-Host "Using the main Cloudflare Encrypted API over $DoHTemplate to resolve $DoHDomain" -ForegroundColor Green;
    $NewIPsV6 = &$curlcmd "https://1.1.1.1/dns-query?name=$dohdomain&type=AAAA"   
    if (!$NewIPsV6) {
      Write-Host "First try failed, now using the secondary Encrypted Cloudflare API to to get IPv6s for $DoHDomain" -ForegroundColor Blue;
      $NewIPsV6 = &$curlcmd "https://1.0.0.1/dns-query?name=$dohdomain&type=AAAA"
    }
    if (!$NewIPsV6) {
      Write-Host "Second try failed, now using the main Encrypted Google API to to get IPv6s for $DoHDomain" -ForegroundColor Yellow;
      $NewIPsV6 = &$curlcmd "https://8.8.8.8/resolve?name=$dohdomain&type=AAAA"
    }
    if (!$NewIPsV6) {
      Write-Host "Third try failed, now using the second Encrypted Google API to to get IPv6s for $DoHDomain" -ForegroundColor DarkRed;
      $NewIPsV6 = &$curlcmd "https://8.8.4.4/resolve?name=$dohdomain&type=AAAA"
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
  catch {
    write-host "these errors occured after running the module" -ForegroundColor white
    $_
    $ModuleErrors = $_ 
  }
  # here we enable logging for the event log below (which is disabled by default) and set its log size from the default 1MB to 2MB
  $logName = 'Microsoft-Windows-DNS-Client/Operational'

  $log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logName
  $log.MaximumSizeInBytes = 2048000
  $log.IsEnabled = $true
  $log.SaveChanges()
  if (!$ModuleErrors) {
    write-host "No errors occured when running the module, creating the scheduled task now if it's not already been created" -ForegroundColor green 
    # create a scheduled task
    if (-NOT (Get-ScheduledTask -TaskName "Dynamic DoH Server IP check" -ErrorAction SilentlyContinue)) { 
      $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-executionPolicy bypass -command `"set-ddoh -DoHTemplate '$DoHTemplate' -DoHDomain '$DoHDomain'`""
      $TaskPrincipal = New-ScheduledTaskPrincipal -LogonType S4U -UserId $env:USERNAME -RunLevel Highest
      # trigger 1
      $CIMTriggerClass =
      Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
      $EventTrigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
      $EventTrigger.Subscription =
      @"
<QueryList><Query Id="0" Path="Microsoft-Windows-DNS-Client/Operational"><Select Path="Microsoft-Windows-DNS-Client/Operational">*[System[Provider[@Name='Microsoft-Windows-DNS-Client'] and EventID=1013]]</Select></Query></QueryList>
"@
      $EventTrigger.Enabled = $True
      $EventTrigger.ExecutionTimeLimit = "PT1M"
      # trigger 2
      $Time = 
      New-ScheduledTaskTrigger `
        -Once -At (Get-Date).AddHours(3) `
        -RandomDelay (New-TimeSpan -Seconds 30) `
        -RepetitionInterval (New-TimeSpan -Hours 6) `
        # register the task
        Register-ScheduledTask -Action $action -Trigger $EventTrigger, $Time -Principal $TaskPrincipal -TaskPath "DDoH" -TaskName "Dynamic DoH Server IP check" -Description "Checks for New IPs of our Dynamic DoH server"
      # define advanced settings for the task
      $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility Win8 -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
      # add advanced settings we defined to the task
      Set-ScheduledTask -TaskPath "DDoH" -TaskName "Dynamic DoH Server IP check" -Settings $TaskSettings 
    }
  }
}
