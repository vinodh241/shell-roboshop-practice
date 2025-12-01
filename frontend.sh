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

dnf module list nginx -y  &&>>$LOG_FILE
validate $? "Nginx module list"


dnf module disable nginx -y  &&>>$LOG_FILE
validate $? "Nginx module disable"

dnf module enable nginx:1.24 -y&&>>$LOG_FILE
validate $? "Nginx module enable"

dnf install nginx -y &&>>$LOG_FILE 
validate $? "Nginx installed successfully"

systemctl enable nginx  &&>>$LOG_FILE
validate $? "Nginx enable service"

systemctl start nginx  &&>>$LOG_FILE
validate $? "Nginx start service"


rm -rf /usr/share/nginx/html/*   | tee -a $LOG_FILE
validate $? "Nginx html content cleanup"


curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
validate $? "Frontend code download"

cd /usr/share/nginx/html | tee -a $LOG_FILE
validate $? "Nginx html directory change"

unzip /tmp/frontend.zip  &&>> $LOG_FILE
validate $? "Frontend code unzip"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf  | tee -a $LOG_FILE
validate $? "Nginx configuration copy"

systemctl restart nginx | tee -a $LOG_FILE
validate $? "Nginx restart service"

echo -e "script ended exuction time : $(date)" | tee -a $LOG_FILE
echo -e "$G INFO :: Frontend setup completed successfully $N" | tee -a $LOG_FILE









