<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>






<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/HotCakeX/Set-DynamicIPDoHServer"><img src="https://raw.githubusercontent.com/HotCakeX/Set-DynamicIPDoHServer/main/GitHubIcon.png" alt="Avatar" width="300"></a>

  <h3 align="center">💎 Use a DNS over HTTPS server that doesn't have a stable IP address, on Windows 11 💎</h3>

  <p align="center">
    Quick and automatic way to use a dynamic IP DNS-over-HTTPS server on Windows
    <br />
    <a href="https://www.powershellgallery.com/packages/Set-DynamicIPDoHServer"><strong>PowerShell Gallery</strong></a>
    <br />
    <br />
    <a href="https://github.com/HotCakeX/Set-DynamicIPDoHServer/discussions">Discussion</a>
    ·
    <a href="https://github.com/HotCakeX/Set-DynamicIPDoHServer/issues">Report Issue</a>

  </p>
</div>

<p align="center">

	
	
  <a href="https://www.powershellgallery.com/packages/Set-DynamicIPDoHServer">
    <img src="https://img.shields.io/powershellgallery/v/Set-DynamicIPDoHServer?style=social"
         alt="PowerShell Gallery">
  </a>
	
	
  <a href="https://www.powershellgallery.com/packages/Set-DynamicIPDoHServer">
    <img src="https://img.shields.io/powershellgallery/dt/Set-DynamicIPDoHServer?style=social"
         alt="PowerShell Gallery Downloads count">
  </a>
 
</p>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
     <li><a href="#about-the-module">About The Module</a></li>
    <li><a href="#features">Features</a></li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>


  </ol>
</details>



<!-- ABOUT THE MODULE -->
## About The Module


This module will automatically identify the correct and active network adapter/interface and set the Secure DNS settings for it based on parameters supplied by user.
That means it will detect the correct network adapter/interface even if you are using:

- Windows built-in VPN connections (PPTP, L2TP, SSTP etc.)
- OpenVPN
- TUN/TAP virtual adapters (a lot of programs use them, including WireGuard)
- Hyper-V virtual switches (Internal, Private, External, all at the same time)
- Cloudflare WARP client



You can create a self-hosted DoH server for free on Cloudflare or other providers, with custom domain name and dynamic IP addresses, which are hard or costly for ISPs, governments etc. to block

please refer to the [GitHub repository of serverless-dns](https://github.com/serverless-dns/serverless-dns) for more info




<!-- FEATURES -->
## Features


* Created, targeted and tested on the latest version of Windows 11, on physical hardware and Virtual Machines

* Once you run this module for the first time and supply it with your DoH template and DoH domain, it will create a scheduled task that will run the module automatically based on 2 distinct criteria:
  -  as soon as Windows detects the current DNS servers are unreachable
  -  every 2 hours in order to check for new IP changes for the dynamic DoH server

You can fine-tune the interval in Task Scheduler GUI if you like. I haven't had any downtimes in my tests because the module runs milliseconds after Windows detects DNS servers are unreachable, and even then, Windows still maintains the current active connections using the DNS cache. if your experience is different, please let me know [on GitHub](https://github.com/HotCakeX/Set-DynamicIPDoHServer/issues).

* the module and the scheduled task will use both IPv4s and IPv6s of the dynamic DoH server. the task will run whether or not any user is logged on.

* in order to make sure the module will always be able to acquire the IP addresses of the dynamic DoH server, even when the currently set IPv4s and IPv6s are outdated, it will first attempt to use the DNS servers set on the system <a href="https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/jj200221(v=ws.11)">DNSSEC-aware query</a>, if it fails to resolve the DoH domain, it will then use [Cloudflare's Encrypted API](https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/make-api-requests/) using [`TLS 1.3`](https://curl.se/docs/manpage.html#--tls13-ciphers) and [`TLS_CHACHA20_POLY1305_SHA256`](https://curl.se/docs/ssl-ciphers.html) cipher suite, which are the best encryption algorithms available.


<p align="right"><a href="#readme-top">💡(back to top)</a></p>

<!-- GETTING STARTED -->
## Getting Started

if you already have the module installed, make sure [it's up-to-date](https://learn.microsoft.com/en-us/powershell/module/powershellget/update-module)

```PowerShell

Update-Module -Name Set-DynamicIPDoHServer -force

```

### Prerequisites

Make sure you have [the latest stable PowerShell installed from Github](https://github.com/PowerShell/PowerShell/releases/latest) before running this module. if it's your first time installing that PowerShell, restart your computer after installation so task scheduler will recognize `pwsh.exe` required for running this module.

> **Note**
> store installed version currently not supported, but soon will be</h5>

### Installation

```PowerShell

Install-Module -Name Set-DynamicIPDoHServer

```




<!-- USAGE EXAMPLES -->
## Usage

```PowerShell

# using module's alias
set-ddoh -DoHTemplate "https://example.com/" -DoHDomain "example.com"
# using module's name
set-dynamicIPDoHServer -DoHTemplate "https://example.com/" -DoHDomain "example.com"

```

<p align="right"><a href="#readme-top">💡(back to top)</a></p>



---

🏴 I'm not the developer of Serverless-dns, however, since it's a great product and I personally use it, I decided to share this module so that Windows users can easily use it.



