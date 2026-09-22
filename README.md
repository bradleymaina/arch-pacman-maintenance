## `$ pac man` 
>check network

>fetch live mirror list from arch website

>filter active mirrors with 100% completion 

>rank 6 fastest mirrors

>upgrade packages

>save to a log 

>repeat every 24 hours 

# INSTALLATION

Install the script to the Downloads directory 

`curl -o ~/Downloads/pacman-maintenance.sh \
  https://raw.githubusercontent.com/bradleymaina/arch-pacman-maintenance/main/pacman-maintenance.sh`

Make the script executable 

`chmod +x ~/Downloads/pacman-mainetenance.sh`

Schedule the job as a cron job 

`sudo crontab -e`

Edit the schedule to as often as you would like , personally i prefer every 5 hours 

`0 */5 * * * ~/Downloads/pacman-maintenance.sh`

Logs are saved in your system to monitor logs for the script 

`cat /var/log/pacman-maintenance.log`

