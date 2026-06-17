### How to Install for ChromeOS:


1) Enable Developer Mode <br>

*To make local account owner, install this script during OOBE (ChromeOS Setup)!* <br>
T*o do this, enable debugging features during OOBE, it will reboot, and then proceed to install during OOBE* <br>

2) Open VT-2, log in as `chronos` and run: <br>
<pre>bash <(curl -s "https://raw.githubusercontent.com/shadowed1/croslocal/main/croslocal.sh?$(date +%s)")</pre>
