echo "Install Gitbucket"
 
CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}

. ./var.conf
 
wget https://github.com/gitbucket/gitbucket/releases/download/4.13/gitbucket.war -O ${TOMCAT_HOME}/webapps/gitbucket.war

systemctl restart tomcat8 
 
sleep 10
 
st=-1
retry=0
max=10
while true
do
  wget http://localhost:8080/gitbucket --no-check-certificate 2>&1
  if [ $? -eq 0 ]; then
     echo "ok"
     break
  else
     retry=`expr $retry + 1`
     sleep 5
  fi
 
  if [ $retry -eq $max ]; then
    echo "Erro!!, Timeout.."
    exit 1
  fi
done


### Config MySQL
sed -e "s/#GITBUCKET_DB#/$GITBUCKET_DB/" \
    -e "s/#GITBUCKET_USER#/$GITBUCKET_USER/" \
    -e "s/#GITBUCKET_PASS#/$GITBUCKET_PASS/" ./conf/create_db.sql.tmpl \
  > ./conf/create_db.sql

mysql -uroot -p${MYSQL_ROOT_PASS} < ./conf/create_db.sql

mkdir -p ${TOMCAT_HOME}/.gitbucket/
\cp -f ./conf/database.conf ${TOMCAT_HOME}/.gitbucket/

systemctl restart tomcat8
