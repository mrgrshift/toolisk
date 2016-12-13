# toolisk

This script works for 1 or 2 servers. But preferably it is recommended to have 2 servers.<br>
First make sure you do not have your SECRET set up in the lisk configuration (config.json).<br>

#Requisites

	- You need to have jq installed. If you are in Ubuntu: sudo apt-get install jq
	- You need to have an account in mailgun.com, and have authorized recipients.
	- If you want failover you need to have an extra synchronized server. 
		- In this extra synchronized server go to config.json and enter in whitelist (api & forging) the IP of the node you are backing up.
		- In this extra synchronized server after you edit config.json please reload your node lisk node to activate the edited config.json
		- Do the same in your main node, edit the config.json and reload your server.

#Installation
Execute the following commands on your delegate node server:
```
cd ~/
git clone https://github.com/mrgrshift/toolisk
cd toolisk/
bash install.sh
```
install.sh will ask you for everything it needs from you to start to operate.<br>
Also it will ask you for mailgun account to handle your notifications.<br>
If you dont want notifications please execute: `bash install.sh --alerts-off`<br>
After you complete the installation make sure you are not running other scripts.<br>
All this scripts must be running in the folder `~/toolisk/`<br>

<i>Before running the following scripts make sure your forging status, wait for you have forged and then start to run the scripts, this way you will have a window of time of approximately 16 minutes in case something unforeseen happens you can return to your previous scripts Before you re-forge (this way we prevent you from losing blocks)</i><br>

#Localsnapshots
In order to reduce the time for downloading snapshots, this script will be looking for new versions and will download them in a separate process. This is the first process after install.sh you need to run:<br>
`bash localsnapshots.sh`<br>
You can leave this script running forever, it is independent and will not affect any other script
<br>
#Scripts
After you install it you can run the following scripts:<br>
<br>
###sync_manager.sh
`bash sync_manager.sh` This script will watch and compare your blockheight against top height. Also this script is responsible for all reload/rebuild processes. This script must be running in all your servers.<br>
<br>
###forging_manager.sh
`bash forging_manager.sh` <b>Use this script only in one of your servers</b>. This script will control forging status.<br>
This is very important, do not run forging_manager.sh in two separate servers because you will be ending forging in two servers and will be bad for the network and your delegate.
<br>
###monitor.js
`node monitor.js` This script will take logs/forging_manager.log and publish it in http://yournodeip:9100/ (default port 9100), this way you can monitor the status of your servers in any phone/tablet/browser.
<br>
#SSL Instalation
If you want to enable SSL (recommendable) in every one of your servers run the following script:<br>
`bash localssl.sh`<br>
It will ask you for the name of your delegate and an email.<br>
After the process finish the script will tell you what to add/change and where.<br>
You will need to reload lisk for this changes take effect (Remember to wait for you to forge before reload).
<br>
#Important warning
If you are doing manual reload/rebuild, please stop sync_manager.sh first if not the script will cause you a mess (because it will detect that you are not in the right block and will perform a rebuild).<br>
And if you do, wait for lisk is synced again at the right blockheight before you run again sync_manager.sh
<br>
<br>
###Disclaimer
Use at your own risk. Read the code and if it suits your needs you can use it.
