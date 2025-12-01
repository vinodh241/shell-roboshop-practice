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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
validate $? "Rabbitmq repo file copy"

dnf install rabbitmq-server -y &>>$LOG_FILE
validate $? "Rabbitmq installation"

systemctl enable rabbitmq-server    | tee -a $LOG_FILE
validate $? "Rabbitmq enable service"
systemctl start rabbitmq-server  | tee -a $LOG_FILE 
validate $? "Rabbitmq start service"

rabbitmqctl add_user roboshop roboshop123 | tee -a $LOG_FILE
validate $? "Rabbitmq application user creation"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE

echo -e "script ended exuction time : $(date)" | tee -a $LOG_FILE
echo -e "$G INFO :: Rabbitmq setup completed successfully $N" | tee -a $LOG_FILE

