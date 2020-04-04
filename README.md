# ZELNODE MULTITOOLBOX

<b>1) How run script</b>  
```bash -i <(curl -s https://raw.githubusercontent.com/XK4MiLX/zelnode/master/multitoolbox.sh)```  

if this way not working you can try:  
```wget https://raw.githubusercontent.com/XK4MiLX/zelnode/master/multitoolbox.sh && chmod +x multitoolbox.sh && ./multitoolbox.sh```   

<b>1) Menu:</b>    
![screen1](https://raw.githubusercontent.com/XK4MiLX/zelnode/master/image/picm1.jpg) 

<b>2) HOW USE MULTITOOLBOX TO SETUP ZELNODE:</b>    
 
* <b>Step 1</b>  
1 - Log to your root accont  
2 - Select option "Install docker on VPS/Inside LXC continer" nr 1  
3 - When u will see window put your username  and hit enter  

![screen2](https://raw.githubusercontent.com/XK4MiLX/zelnode/master/image/picm2.jpg)

If everything goes well you will see  
![screen3](https://raw.githubusercontent.com/XK4MiLX/zelnode/master/image/picm3.png)

* <b>Step 2</b>  
1 - Reboot pc and log to your user accont or switch user to user accont  ( scripts will ask about it on end of first steps )  
2 - Run scripts again and select option "Install ZelNode" nr 3  

If everything goes well you will see  
![screen4](https://raw.githubusercontent.com/XK4MiLX/zelnode/master/image/picm6.jpg)  
![screen5](https://raw.githubusercontent.com/XK4MiLX/zelnode/master/image/picm7.jpg) 

* <b>Step 3</b>  
1 - Visit http://your_node_ip:16126  

If everything goes well you will see  
![screen6](https://raw.githubusercontent.com/XK4MiLX/zelnode/master/image/picm8.jpg)  

# Troubleshooting

* Step 1  
1 - If node not working first run script again and select option "ZelNode analizer and fixer" nr 4  

 - Data mismatch is a common case  
![screen7](https://raw.githubusercontent.com/XK4MiLX/zelnode/master/image/picm9.jpg) 

# WHY ZELNODE MULTITOOLBOX?  
  
* <b>Docker installation</b>  
1) You need put username only  
2) Error controls  
  
* <b>Node installation</b>  
1) Ability to disable firewall diuring installation  
2) Zel ID veryfication  
3) Supporting installation in LXC continer  
4) Auto-detection bootstrap archive if is in  home user directory   
5) Ability to download bootstrap from own source  
6) Auto-update via CronTab
7) Error controls 
6) Supporting NAT configuration
  
* <b>ZelNode analizer and fixer</b>  
1) Veryfication errors  
2) Fix build in script 


