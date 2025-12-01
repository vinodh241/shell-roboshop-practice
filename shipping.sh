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

      dnf install maven -y  &>> $LOG_FILE
        validate $? "Maven installed sccessfully"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop 
    validate $? "roboshop user creation"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi  

mkdir -p /app  
validate $? "app directory creation"     
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip
cd /app 
unzip /tmp/shipping.zip  | tee -a $LOG_FILE
validate $? "shipping code download and extract"

   
cd /app
mvn clean package &>> $LOG_FILE
mv target/shipping-1.0.jar shipping.jar  &&>> LOG_FILE


cp SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service  &&>> LOG_FILE
validate $? "shipping systemd file copy"

systemctl daemon-reload
systemctl enable shipping  | tee -a $LOG_FILE
validate $? "shipping enable service"
systemctl start shipping | tee -a $LOG_FILE
validate $? "shipping start service"


dnf install mysql -y &>> $LOG_FILE
validate $? "Mysql client installation"


mysql -h mysql.vinodh.site -uroot -pRoboShop@1 < /app/db/schema.sql
mysql -h mysql.vinodh.site -uroot -pRoboShop@1 < /app/db/app-user.sql 
mysql -h mysql.vinodh.site -uroot -pRoboShop@1 < /app/db/master-data.sql
validate $? "shipping mysql schema load"


systemctl restart shipping | tee -a $LOG_FILE
validate $? "shipping restart service"

echo -e "script ended exuction time : $(date)" | tee -a $LOG_FILE
echo -e "$G INFO :: shipping setup completed successfully $N" | tee -a $LOG_FILE



