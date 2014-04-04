!/bin/bash
# Make sure you change the following values
Client_Id=yttzEwwQ5k0EEXLrI88Rq
API_Key=3dsf345llkdsas999SXserzET66fzzvEfaaeedaF
Domain_Id=18553
Record_Id=485669
 
Current_Public_Ip=`curl icanhazip.com`
curl -s "https://api.digitalocean.com/domains/$Domain_Id/records/$Record_Id/edit?client_id=$Client_Id&api_key=$API_Key&record_type=A&data=$Current_Public_Ip"