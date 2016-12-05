# toolisk

First make sure you do not have your SECRET set up in the lisk configuration (config.json).<br>

#Installation
Execute the following commands on your delegate node server:
```
cd ~/
git clone https://github.com/mrgrshift/toolisk
cd toolisk/
bash install.sh
```
<br>
It will ask you for mailgun account to handle your notifications.<br>
After you install it you con run the following scripts:<br>
`bash startTool.sh` Will automaticly start 'screen' sessions to run blockheight.sh and consensus.sh scripts.<br>
<br>
`bash blockheight.sh` This script will watch and compare your blockheight against top height.<br>
<br>
`bash consensus.sh` This script will watch for your consensus, if its Inadequate it will automatically do failover.<br>
<br>
`bash manager.sh` Use this script only in one of your servers. This script will control forging status.<br>
<br>

###Disclaimer
Use at your own risk. Read the code and if it suits your needs you can use it.
