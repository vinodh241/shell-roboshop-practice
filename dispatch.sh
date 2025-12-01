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
dnf install golang -y &>> $LOG_FILE
validate $? "Golang installation"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]
then    
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop    &>>$LOG_FILE
    validate $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi  
mkdir -p /app
validate $? "app directory creation"
curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip 

rm -rf /app/* 
cd /app
unzip /tmp/dispatch.zip  | tee -a $LOG_FILE
validate $? "dispatch code download and extract"

cd /app
go mod init dispatch &>> $LOG_FILE
validate $? "dispatch module init"  
go get &>> $LOG_FILE
validate $? "dispatch module get"  
go build &>> $LOG_FILE
validate $? "dispatch build"    

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>> $LOG_FILE
validate $? "dispatch systemd service file copy"  

systemctl daemon-reload  | tee -a $LOG_FILE 
validate $? "systemd daemon reload" 


systemctl enable dispatch  | tee -a $LOG_FILE
validate $? "dispatch enable service"
systemctl start dispatch    | tee -a $LOG_FILE      
validate $? "dispatch start service"    

echo -e "script ended exuction time : $(date)" | tee -a $LOG_FILE
echo -e "$G INFO :: dispatch setup completed successfully $N" | tee -a $LOG_FILE




