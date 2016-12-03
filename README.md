# toolisk

First make sure you do not have your SECRET set up in the lisk configuration (config.json).<br>

#Installation
`bash install.sh` <br>
It will ask you for mailgun account to handle your notifications. After you install you will have the choose to run 2 scripts:<br>
<br>
`bash blockheight.sh` This script will watch and compare your blockheight against top height.<br>
<br>
`bash consensus.sh` This script will watch for your consensus, if its Inadequate it will automatically do failover.<br>
<br>
`bash manager.sh` Use this script only in one of your servers. This script will control forging status.<br>
<br>

###Disclaimer
Use at your own risk. Read the code and if it suits your need you can use it.
