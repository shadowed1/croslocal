# Persistent Local Account for ChromeOS! <br>
## Use ChromeOS without an internet connected account! <br>

### How to Install for ChromeOS:

1) Enable Developer Mode <br>

*To make local account owner, install this script during OOBE (ChromeOS Setup)!* <br>
*Enable debugging features during OOBE, open guest mode to install during OOBE* <br>

2a) Creating a local account on a fresh ChromeOS install (enable Chromebook plus features), Open VT-2, log in as `root` and manually type: <br>
<pre>bash <(curl -s "https://raw.githubusercontent.com/shadowed1/croslocal/main/localoobe.sh")</pre>

### OR

2b) Creating a local account on an existing ChromeOS install, Open VT-2, log in as `root` and manually type: <br>
<pre>bash <(curl -s "https://raw.githubusercontent.com/shadowed1/croslocal/main/local.sh")</pre>

<br>

Local User Account Script created: https://github.com/justaguy <br>
Setup Prompts and ARM64 research: https://github.com/shadowed1 <br>
