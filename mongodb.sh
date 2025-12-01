#!/bin/bash

USERID=$(id -u)
R="\e[0;31m"
G="\e[0;32m"
N="\e[0m"   

LOG_FOLDER="/var/log/shell-roboshop.logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
mkdir -p $LOG_FOLDER
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
                echo -e "$G SUCCESS:: $2 is installed successfully $N"  | tee -a $LOG_FILE
            else
                echo -e "$R ERROR:: $2 installation failed $N" | tee -a $LOG_FILE
            fi
        }   

cp mongo.repo /etc/yum.repos.d/mongodb.repo &>> $LOG_FILE
validate $? "Mongodb repo file copy"

dnf install mongodb-org -y   &>> $LOG_FILE
validate $? "Mongodb installation"

systemctl enable mongod  | tee -a $LOG_FILE
validate $? "Mongodb enable service"

systemctl start mongod  | tee -a $LOG_FILE 
validate $? "Mongodb start service"


sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf | 
validate $? "Mongodb bind address change"


systemctl restart mongod | tee -a $LOG_FILE
validate $? "Mongodb restart service"

echo -e "script ended exuction time : $(date)" | tee -a $LOG_FILE
echo -e "$G INFO :: Mongodb setup completed successfully $N" | tee -a $LOG_FILE
