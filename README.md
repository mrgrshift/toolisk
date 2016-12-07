# toolisk

This script works for 1 or 2 servers. But preferably it is recommended to have 2 servers.<br>
First make sure you do not have your SECRET set up in the lisk configuration (config.json).<br>

#Requisites

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

#Localsnapshots
In order to reduce the time for downloading snapshots, this script will be looking for new versions and will download them in a separate process. This is the first process after install.sh you need to run:<br>
`bash localsnapshots.sh`
<br>
#Scripts
After you install it you can run the following scripts:<br>
###startTool.sh
`bash startTool.sh` Will automaticly start 'screen' sessions to run blockheight.sh and consensus.sh scripts.<br>
If you don't like 'screen' sessions you can use the tool of your choice.<br>
<br>
###blockheight.sh
`bash blockheight.sh` This script will watch and compare your blockheight against top height. Also this script is responsible for all reload/rebuild processes<br>
<br>
###consensus.sh
`bash consensus.sh` This script will watch for your consensus, if its Inadequate it will automatically do failover.<br>
<br>
#Your Manager
`bash manager.sh` Use this script only in one of your servers. This script will control forging status.<br>
This is very important, do not run manager.sh in two separate servers because you will be ending forging in two servers and will be bad for your delegate.
<br>
#SSL Instalation
If you want to enable SSL in every one of your servers run the following script:<br>
`bash localssl.sh`<br>
It will ask you for the name of your delegate and an email.<br>
After the process finish you will need to add your ssl file to config.json and reload lisk.
<br>
<br>
###Disclaimer
Use at your own risk. Read the code and if it suits your needs you can use it.
