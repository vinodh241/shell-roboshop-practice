#!/bin/bash

USERID=$( id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop.logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
mkdir -p $LOG_FOLDER
SCRIPT_DIR=$PWD
echo -e "script started exuction time : $( date)" | tee -a $LOG_FILE    

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

dnf module disable nodejs -y &>>$LOG_FILE
validate $? "Nodejs module disable" 

dnf module enable nodejs:20 -y  &>>$LOG_FILE
validate $? "Nodejs module enable"

dnf install nodejs -y &>>$LOG_FILE
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
curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
validate $? "cart code download"

rm -rf /app/*
cd /app
unzip /tmp/cart.zip &>>$LOG_FILE
validate $? "cart code unzip"  

cd /app
npm install &>>$LOG_FILE
validate $? "cart npm dependencies installation"

cp $SCRIPT_DIR/systemd/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
validate $? "cart systemd service file copy"        

systemctl daemon-reload &>>$LOG_FILE
validate $? "systemd daemon reload"         

systemctl enable cart &>>$LOG_FILE
validate $? "cart enable service"
systemctl start cart &>>$LOG_FILE
validate $? "cart start service"

echo -e "script ended exuction time : $( date)" | tee -a $LOG_FILE
echo -e "$G INFO :: cart setup completed successfully $N" | tee -a $LOG_FILE



