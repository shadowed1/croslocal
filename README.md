## Persistent Local Account for ChromeOS!

### How to Install for ChromeOS:

1) Enable Developer Mode <br>

*To make local account owner, install this script during OOBE (ChromeOS Setup)!* <br>
T*o do this, enable debugging features during OOBE, it will reboot, and then proceed to install during OOBE* <br>

2) Open VT-2, log in as `root` and run: <br>
<pre>curl -s "https://raw.githubusercontent.com/shadowed1/croslocal/main/croslocal.sh" | bash
</pre>

<br>

```
curl -fsSL "https://raw.githubusercontent.com/shadowed1/croslocal/main/croslocal.sh" -o "/usr/local/croslocal"
cd /usr/local
chmod +x croslocal
./croslocal
```
<br>

Created by https://github.com/justaguy <br>
Prompts by https://github.com/shadowed1 <br>
