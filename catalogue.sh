#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
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



 dnf module disable nodejs -y &>>$LOG_FILE
 validate $? "Disabling default nodejs"

 dnf module enable nodejs:20 -y | tee -a $LOG_FILE 
 validate $? "Nodejs module enable"

 dnf install nodejs -y &>> $LOG_FILE
 validate $? "Nodejs installation"



id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir -p /app 

validate $? "app directory creation"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
validate $? "catalogue code download"



rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip
validate $? "catalogue code unzip"

npm install  &>> $LOG_FILE
validate $? "catalogue npm package installation"


cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
validate $? "catalogue service file copy"


systemctl daemon-reload | tee -a $LOG_FILE 
validate $? "systemctl daemon reload"

systemctl enable catalogue 
validate $? "catalogue enable service"

systemctl start catalogue
validate $? "catalogue start service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongodb.repo &>> $LOG_FILE
validate $? "Mongodb repo file copy"

dnf install mongodb-mongosh -y   &>> $LOG_FILE
validate $? "Mongodb mongosh installation"

mongosh --host mongodb.vinodh.site </app/db/master-data.js
validate $? "catalogue mongodb schema load"

echo -e "script ended exuction time : $(date)" | tee -a $LOG_FILE
echo -e "$G INFO :: catalogue setup completed successfully $N" | tee -a $LOG_FILE

