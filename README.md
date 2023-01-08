<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>






<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/HotCakeX/Set-DynamicIPDoHServer"><img src="https://raw.githubusercontent.com/HotCakeX/Set-DynamicIPDoHServer/main/fdsf.jpg" alt="Avatar" width="200"></a>

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
even if Hyper-V virtual switches (Internal, Private, External) are being used and the physical network adapter is virtualized by Hyper-V virtual switch manager or
VPN's virtual network adapter is being used, all at the same time, the module will still find and enable DoH settings for the correct adapter.

You can create a self-hosted DoH server for free on Cloudflare or other providers, with custom domain name and dynamic IP addresses, which are hard or costly for ISPs, governments etc. to block

please refer to the Github repository of serverless-dns for more info: https://github.com/serverless-dns/serverless-dns


<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- FEATURES -->
## Features


* Created, targeted and tested on the latest version of Windows 11, on physical hardware and Virtual Machines

* Once you run this module for the first time and supply it with your DoH template and DoH domain, it will create a scheduled task that will run the module automatically based on 2 distinct criteria:
  -  as soon as Windows detects the current DNS servers are unreachable
  -  every 2 hours in order to check for new IP changes for the dynamic DoH server

You can fine-tune the interval in Task Scheduler GUI if you like. I haven't had any downtimes in my tests because the module runs miliseconds after Windows detects DNS servers are unreachable, and even then, Windows still maintains the current active connections using the DNS cache. if your experience is different, please let me know on Github.

* the module and the scheduled task will use both IPv4s and IPv6s of the dynamic DoH server. the task will run whether or not any user is logged on.

* in order to make sure the module will be able to always acquire the IP addresses of the dynamic DoH server, even when the currently set IPv4s and IPv6s are outdated,
it will first attempt to use the DNS servers set on the system, if it fails to resolve the DoH domain, it will then use Cloudflare's 1.1.1.1 to resolve the IP addresses of the dynamic DoH server.
DNS queries made to Cloudflare's 1.1.1.1 will be un-encrypted and in plain text.


<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started

if you already have the module installed, make sure it's up-to-date

```PowerShell

Update-Module -Name Set-DynamicIPDoHServer -force

```

### Prerequisites

Make sure you have the latest stable PowerShell installed from Github before running this module: https://github.com/PowerShell/PowerShell/releases/latest 

> **Note**
> store installed version currently not supported, but soon will be</h5>

### Installation

```PowerShell

Install-Module -Name Set-DynamicIPDoHServer

```

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

```PowerShell

# using module's alias
set-ddoh -DoHTemplate "https://example.com/" -DoHDomain "example.com"
# using module's name
set-dynamicIPDoHServer -DoHTemplate "https://example.com/" -DoHDomain "example.com"

```

<p align="right">(<a href="#readme-top">back to top</a>)</p>



---

🏴 Disclaimer: I'm not the developer of Serverless-dns, however, since it's a great product and I personally use it, I decided to share this module so that Windows users can easily use it.



