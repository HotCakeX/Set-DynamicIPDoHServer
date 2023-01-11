#
# Module manifest for module 'Set-DynamicIPDoHServer' or 'set-ddoh'
#
# Generated by: HotCakeX
#
# Generated on: 1/5/2023
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'Set-DynamicIPDoHServer.psm1'

# Version number of this module.
ModuleVersion = '0.1.1'

# Supported PSEditions
CompatiblePSEditions = @("Desktop","Core")

# ID used to uniquely identify this module
GUID = '85d391d8-097a-4394-b8b7-6eb98eeabb0e'

# Author of this module
Author = 'HotCakeX'

# Company or vendor of this module
CompanyName = 'HotCakeX Inc'

# Copyright statement for this module
Copyright = '(c)2023'

# Description of the functionality provided by this module
Description = @"


💎 Use a DNS over HTTPS server that doesn't have a stable IP address, on Windows 11 💎

This module will automatically identify the correct and active network adapter/interface and set the Secure DNS settings for it based on parameters supplied by user.
That means it will detect the correct network adapter/interface even if you are using:

1. Windows built-in VPN connections (PPTP, L2TP, SSTP etc.)
2. OpenVPN
3. TUN/TAP virtual adapters (a lot of programs use them, including WireGuard)
4. Hyper-V virtual switches (Internal, Private, External, all at the same time)
5. Cloudflare WARP client


You can create a self-hosted DoH servers for free on Cloudflare or other providers, with custom domain name and dynamic IP addresses, which are hard or costly for ISPs, governments etc. to block

please refer to the GitHub repository of serverless-dns for more info: https://GitHub.com/serverless-dns/serverless-dns


Example usage:

using module's alias: set-ddoh -DoHTemplate "https://example.com/" -DoHDomain "example.com"
using module's name:  set-dynamicIPDoHServer -DoHTemplate "https://example.com/" -DoHDomain "example.com"


✅ Created, targeted and tested on the latest version of Windows 11, on physical hardware and Virtual Machines

✅ Once you run this module for the first time and supply it with your DoH template and DoH domain, it will create a scheduled task that will run the module automatically based on 2 distinct criteria:

    1) as soon as Windows detects the current DNS servers are unreachable
    2) every 2 hours in order to check for new IP changes for the dynamic DoH server.

You can fine-tune the interval in Task Scheduler GUI if you like. I haven't had any downtimes in my tests because the module runs milliseconds after Windows detects DNS servers are unreachable, and even then, Windows still maintains the current active connections using the DNS cache. if your experience is different, please let me know on GitHub.

✅ the module and the scheduled task will use both IPv4s and IPv6s of the dynamic DoH server. the task will run whether or not any user is logged on.

✅ in order to make sure the module will always be able to acquire the IP addresses of the dynamic DoH server, even when the currently set IPv4s and IPv6s are outdated, it will first attempt to use the DNS servers set on the system (DNSSEC-aware query), if it fails to resolve the DoH domain, it will then use Cloudflare's Encrypted API using TLS 1.3 and TLS_CHACHA20_POLY1305_SHA256 cipher suite, which are the best encryption algorithms available.

🛑 Make sure you have the latest stable PowerShell installed from GitHub before running this module: https://GitHub.com/PowerShell/PowerShell/releases/latest
(Store installed version currently not supported, but soon will be)

🏴 I'm not the developer of Serverless-dns, however, since it's a great product and I personally use it, I decided to share this module so that Windows users can easily use it.


🔷 if you have any feedback about this module, please open a new issue or discussion on GitHub:
https://GitHub.com/HotCakeX/Set-DynamicIPDoHServer

"@

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.3'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @("Set-DynamicIPDoHServer")

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @("Set-DynamicIPDoHServer")

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @("set-ddoh")

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = @("Set-DynamicIPDoHServer.psd1","Set-DynamicIPDoHServer.psm1")

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Security', 'DNS', 'Windows', 'HTTPS', 'DynamicIP', 'DoH')

        # A URL to the license for this module.
        LicenseUri = 'https://GitHub.com/HotCakeX/Set-DynamicIPDoHServer'

        # A URL to the main website for this project.
        ProjectUri = 'https://GitHub.com/HotCakeX/Set-DynamicIPDoHServer'

        # A URL to an icon representing this module.
        IconUri = 'https://raw.githubusercontent.com/HotCakeX/Set-DynamicIPDoHServer/main/PowerShellGalleryIcon.png'

        # ReleaseNotes of this module
        ReleaseNotes = @"

## Version 
* 0.0.1 First release
* 0.0.2 added new parameter to ask user for DoH domain, also it can now choose the correct network adapter if both virtual VPN adapters and Hyper-V virtual switches are being used, all at the time time
* 0.0.3 added more details for the PowerShell Gallery's page
* 0.0.4 fixed some typos in PowerShell Gallery's description page
* 0.0.5 added an icon for the module
* 0.0.6 again fixed the PowerShell description text in PowerShell Gallery
* 0.0.7 modified the scheduled task trigger to run every 2 hours and added a 2nd trigger so the module will run the moment system detects DNS failure
* 0.0.8 fixed the typo in the line above, literally, improved PowerShell Gallery description, and set the scheduled task to end if it runs continiously longer than 1 minute
* 0.0.9 improved active network adapter detection logic to support Windows built-in VPN client connections, improved the description text and added new icon
* 0.1.0 Now when system DNS is unavailable, the module will use Encrypted Cloudflare API using TLS 1.3 and TLS_CHACHA20_POLY1305_SHA256 cipher suite, so everything is end-to-end encrypted. also made the system DNS query DNSSEC-aware.
* 0.1.1 Fixed a typo in the description of PowerShell gallery ¯\_(ツ)_/¯
"@

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://GitHub.com/HotCakeX/Set-DynamicIPDoHServer'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
