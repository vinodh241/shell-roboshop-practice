#!/bin/bash

USERID=$(id -u)
R="\e[0;31m"
G="\e[0;32m"
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


dnf install python3 gcc python3-devel -y  &>> $LOG_FILE
validate $? "Python3 installation"

id  roboshop &>> $LOG_FILE
if [ $? -ne 0 ]
then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        validate $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi  

mkdir -p /app
validate $? "app directory creation"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 

rm -rf /app/* 
cd /app
unzip /tmp/payment.zip  | tee -a $LOG_FILE
validate $? "payment code download and extract"

cd /app
pip3 install -r requirements.txt  &>> $LOG_FILE

validate $? "payment dependencies installation"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service  &>> $LOG_FILE
validate $? "payment systemd service file copy"     

systemctl daemon-reload | tee -a $LOG_FILE
validate $? "systemd daemon reload"


systemctl enable payment  | tee -a $LOG_FILE
validate $? "payment enable service"

systemctl start payment | tee -a $LOG_FILE
validate $? "payment start service"


echo -e "script ended exuction time : $(date)" | tee -a $LOG_FILE
echo -e "$G INFO :: payment setup completed successfully $N" | tee -a $LOG_FILE 

