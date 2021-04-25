WIDTH=78
HEIGHT=20

# Exit codes.
SUCCESS=0
FAILURE=1
PACKAGES_NOT_AVAILABLE=2

X11VNC_install(){
wget -c http://security.debian.org/debian-security/pool/updates/main/x/x11vnc/x11vnc_0.9.13-2+deb9u2_amd64.deb 
wget -c http://security.debian.org/debian-security/pool/updates/main/x/x11vnc/x11vnc-data_0.9.13-2+deb9u2_all.deb
apt install ./x11vnc*.deb -y && dpkg -i ./x11vnc*.deb
PASSWORD=$(whiptail --title  "Test Password Box" --passwordbox  "Введите пароль X11VNC и выберите ОК для продолжения" 10 60 3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ];  then
     echo "Ваш пароль:" $PASSWORD
     x11vnc -storepasswd $PASSWORD /etc/x11vnc.pass
     
     #получаем IP-адрес  клиента
        ip=`hostname -I | awk ' {print substr($1, 1)}'`
        echo $ip
cat > /etc/systemd/system/x11vnc.service <<X-service
[Unit]
Description=x11vnc
After=multi-user.target
[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -env FD_KDM=1 -auth guess -listen $ip -noipv6 -rfbport 5900 -rfbauth /etc/x11vnc.pass -notruecolor -ultrafilexfer -shared -dontdisconnect -many -noxrecord -noxfixes -noxdamage -nodpms -loop -o /var/log/x11vnc.log
[Install]
WantedBy=multi-user.target
X-service
systemctl daemon-reload
systemctl enable x11vnc.service
systemctl start x11vnc.service

#operation_success
#full_menu
else
     full_menu
fi

}

operation_success(){
clear
TERM=ansi whiptail --backtitle "" --title "Успех!" --infobox "Операция выполнена успешно!" 15 60
sleep 2
clear
}

exact_time(){
systemctl stop ntp
cat > /etc/ntp.conf <<NTP
#российские сервера точного времени
server 0.ru.pool.ntp.org iburst dynamic
server 1.ru.pool.ntp.org iburst dynamic
server 2.ru.pool.ntp.org iburst dynamic
server 3.ru.pool.ntp.org iburst dynamic

#сервера организации
server 192.168.10.8 iburst prefer
server 192.168.10.6 iburst
server 127.127.1.0
fudge 127.127.1.0 stratum 10
NTP
if !(/lib/systemd/systemd-sysv-install is-enabled ntp)
then
    /lib/systemd/systemd-sysv-install enable ntp 
fi    
systemctl start ntp
#operation_success
}

install_CryptoPro(){
#предусмотреть загрузку через git

tar -xzf linux-amd64_deb.tgz
cd linux-amd64_deb
./uninstall.sh
apt autoremove -y
./install_gui.sh
#Options
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\parameters\Crypto-Pro Enhanced RSA and AES CSP' -add long ControlKeyTimeValidity 0x00
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\parameters\Crypto-Pro Enhanced RSA and AES CSP' -add long KeyTimeValidityControlMode 0x00
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\parameters\Crypto-Pro HSM CSP' -add long ControlKeyTimeValidity 0x00
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\parameters\Crypto-Pro HSM CSP' -add long KeyTimeValidityControlMode 0x00
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\parameters\Crypto-Pro GOST R 34.10-2012 HSM CSP' -add long ControlKeyTimeValidity 0x00
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\parameters\Crypto-Pro GOST R 34.10-2012 HSM CSP' -add long KeyTimeValidityControlMode 0x00
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\parameters\Crypto-Pro GOST R 34.10-2012 Strong HSM CSP' -add long ControlKeyTimeValidity 0x00
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\parameters\Crypto-Pro GOST R 34.10-2012 Strong HSM CSP' -add long KeyTimeValidityControlMode 0x00
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\parameters\Crypto-Pro GOST R 34.10-2012 KC1 CSP' -add long ControlKeyTimeValidity 0x00
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\parameters\Crypto-Pro GOST R 34.10-2012 KC1 CSP' -add long KeyTimeValidityControlMode 0x00
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\cades\trustedsites' -add multistring "TruestedSites" "https://zakupki.gov.ru" "https://lk.zakupki.gov.ru" "https://www.cryptopro.ru"
cd ..
rm -rf linux-amd64_deb

#Устанавливаем плагин Cades

apt install libwebkitgtk-1.0-0 -y
tar -xzf cades_linux_amd64.tar.gz
cd cades_linux_amd64
dpkg -i *.deb
cd ..
rm -rf cades_linux_amd64

#Устанавливаем дополнительные пакеты
unzip thirdparty_Astra-1.6-amd64.zip
cd Astra-1.6-amd64
dpkg -i *.deb
cd ..
rm -rf Astra-1.6-amd64

#Устанавливаем токены
apt --fix-broken install -y
apt install libccid pcscd libgost-astra -y
unzip token_libs_Astra-1.6-amd64.zip
cd Astra-1.6-amd64
dpkg -i *.deb
cd ..
rm -rf Astra-1.6-amd64
}

install_Gosuslugi(){
wget -c "https://ds-plugin.gosuslugi.ru/plugin/upload/assets/distrib/IFCPlugin-x86_64.deb"
dpkg -i IFCPlugin-x86_64.deb
#Options
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\PKCS11\slot17' -add string "ProvGOST" "Crypto-Pro GOST R 34.10-2012 Cryptographic Service Provider"
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\PKCS11\slot17' -add string "Firefox" "1"
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\PKCS11\slot17' -add string "Chromium" "1"
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\PKCS11\slot17' -add string "Reader" ""
wget -c https://www.cryptopro.ru/sites/default/files/public/faq/ifcx64.cfg
rm /etc/ifc.cfg && cp ifcx64.cfg /etc/ifc.cfg
/opt/cprocsp/bin/amd64/csptestf -absorb -certs -autoprov
}

install_DrWeb(){
rm /etc/apt/sources.list.d/drweb.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8C42FC58D8752769
echo "deb http://repo.drweb.com/drweb/debian 11.1 non-free" >> /etc/apt/sources.list.d/drweb.list
apt-get update
apt-get install drweb-workstations -y

}


system_update(){
#полное обновление системы
apt update 
apt upgrade
}

installing_the_required_packages(){
system_update
# установка пакетов, необходимых для работы
apt install screen htop smartmontools ntp nfs-common rsync util-linux printer-driver-gutenprint printer-driver-splix printer-driver-cups-pdf chromium xrdp simple-scan -y
# установка дополнительных пакетов для КриптоПроCSP
apt install libccid pcscd libgost-astra -y
restart_service
#operation_success
full_menu
}

restart_service(){
systemctl enable smartd 
/lib/systemd/systemd-sysv-install disable rsync
}


remove_unnecessary_packages(){
#здесь в список можно добавить пакеты, которые не нужны в системе
apt remove qbittorrent blender jag -y
# автоочистка
apt autoremove -y
system_update
operation_success
full_menu
}


full_menu(){
OPTION=$(whiptail --title  "Настройка клиента Astra Linux CE" --menu  "Выберите пункт:" "${HEIGHT}" "${WIDTH}" 8 \
"1" "Установка требуемых пакетов\Обновление системы" \
"2" "Удаление нетребуемых пакетов\Обновление системы" \
"3" "Настройка точного времени" \
"4" "Настройка сервиса X11VNC" \
"5" "Установка и\или обновление КриптоПроCSP+Cades+токены " \
"6" "Установка и\или обновление плагина Госуслуги" \
"7" "Установка Dr.Web" \
"8" "..."  3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ];  then
     echo "Вы выбрали:" $OPTION
else
     echo "Вы выбрали Cancel."
fi

case $OPTION in
   "1") installing_the_required_packages;;
   "2") remove_unnecessary_packages;;
   "3") exact_time;;
   "4") X11VNC_install;;
   "5") install_CryptoPro;;
   "6") install_Gosuslugi;;
   "7") install_DrWeb
   
esac    

#clear
}


main_menu() {
    whiptail --title "Настройка клиента Astra Linux CE" \
        --yesno "Быстрая настройка нескольких пунктов Astra Linux

Этот скрипт позволяет настроить обновление системы, время, удаленный доступ X11VNC, установить или обновить КриптоПроCSP, обновление плагинов для браузеров. Нажмите Next для вызова меню или Exit, если хотите выйти из скрипта  " \
        --yes-button "Next" --no-button "Exit" \
        "${HEIGHT}" "${WIDTH}" 
    if [ "$?" -ne "${SUCCESS}" ] ; then
        exit "${SUCCESS}"
    fi
    full_menu
}

main() {
    if [ "$(id -u)" -ne 0 ] ; then
        echo "Ошибка, скрипт должен запускаться с правами администратора"
        exit "${FAILURE}"
    fi
   main_menu
}

main "$@"