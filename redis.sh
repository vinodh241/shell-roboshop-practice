#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"   

LOG_FOLDER="/var/log/shell-roboshop.logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
mkdir -p $LOG_FOLDER
SCRIPT_DIR=$PWD
echo -e "script started exuction time : $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: pleae run this script with root access $N" | tee -a $LOG_FILE
    exit 1 # we can give other than zero upto 127
else
    echo -e "$G Success:: you are running with root access $N" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install

        validate () {
            if [ $1 -eq 0 ]
            then
                echo -e " $2 is .... $G SUCCESS $N" | tee -a $LOG_FILE
            else 
                echo -e " $2 is .... $R FAILED $N" | tee -a $LOG_FILE
            fi
        }  

dnf module disable redis -y    | tee -a $LOG_FILE
validate $? "Redis module disable"

dnf module enable redis:7 -y  | tee -a $LOG_FILE
validate $? "Redis module enable"

dnf install redis -y  &>>$LOG_FILE
validate $? "Redis installation"


sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
validate $? "Edited redis.conf to accept remote connections"

systemctl enable redis  | tee -a $LOG_FILE
validate $? "Redis enable service"  
systemctl start redis  | tee -a $LOG_FILE
validate $? "Redis start service"       

echo -e "script ended exuction time : $(date)" | tee -a $LOG_FILE
echo -e "$G INFO :: Redis setup completed successfully $N" | tee -a $LOG_FILE


