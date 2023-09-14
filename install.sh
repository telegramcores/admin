WIDTH=78
HEIGHT=20

# Exit codes.
SUCCESS=0
FAILURE=1
PACKAGES_NOT_AVAILABLE=2

X11VNC_install(){
wget -c https://security.debian.org/debian-security/pool/updates/main/x/x11vnc/x11vnc_0.9.13-6+deb10u1_amd64.deb 
wget -c https://security.debian.org/debian-security/pool/updates/main/x/x11vnc/x11vnc-data_0.9.13-6+deb10u1_all.deb
apt install ./x11vnc*.deb -y && dpkg -i ./x11vnc*.deb
PASSWORD=$(whiptail --title  "Пароль для X11VNC" --passwordbox  "Введите пароль X11VNC и выберите ОК для продолжения" 10 60 3>&1 1>&2 2>&3)
 
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
systemctl enable ntp
systemctl start ntp
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

#установливаем сертификаты
wget -qO- --no-check-certificate "https://roskazna.gov.ru/upload/iblock/992/Sertifikat-udostoveryayushchego-tsentra-Federalnogo-kaznacheystva-2023.CER"|/opt/cprocsp/bin/amd64/certmgr -inst -store mRoot -stdin
wget -qO- --no-check-certificate "https://roskazna.gov.ru/upload/iblock/f5e/Kornevoy-sertifikat-GUTS-2022.CER"|/opt/cprocsp/bin/amd64/certmgr -inst -store mRoot -stdin
wget -qO- --no-check-certificate "https://roskazna.gov.ru/upload/iblock/1af/Kaznacheystvo-Rossii.CER"| /opt/cprocsp/bin/amd64/certmgr -inst -store mca -stdin
wget -qO- --no-check-certificate "https://roskazna.gov.ru/upload/iblock/7e3/guts_2012.cer"| /opt/cprocsp/bin/amd64/certmgr -inst -store mRoot -stdin
wget -qO- --no-check-certificate "https://roskazna.gov.ru/upload/iblock/c8c/UTS-FK_2021.CER"| /opt/cprocsp/bin/amd64/certmgr -inst -store mca -stdin
wget -qO- --no-check-certificate "https://roskazna.gov.ru/upload/iblock/024/uts-fk_2020.cer"| /opt/cprocsp/bin/amd64/certmgr -inst -store mca -stdin
wget -qO- --no-check-certificate "https://roskazna.gov.ru/upload/iblock/acb/fk_2012.cer"| /opt/cprocsp/bin/amd64/certmgr -inst -store mca -stdin
wget -qO- --no-check-certificate "http://rostelecom.ru/cdp/guc_gost12.crl"| /opt/cprocsp/bin/amd64/certmgr -inst -crl -stdin
wget -qO- --no-check-certificate "http://rostelecom.ru/cdp/guc.crl"| /opt/cprocsp/bin/amd64/certmgr -inst -crl -stdin
wget -qO- --no-check-certificate "http://crl.roskazna.ru/crl/ucfk_2021.crl"| /opt/cprocsp/bin/amd64/certmgr -inst -crl -stdin
wget -qO- --no-check-certificate "http://crl.roskazna.ru/crl/ucfk_2020.crl"| /opt/cprocsp/bin/amd64/certmgr -inst -crl -stdin
wget -qO- --no-check-certificate "http://crl.roskazna.ru/crl/ucfk_gost12.crl"| /opt/cprocsp/bin/amd64/certmgr -inst -crl -stdin
wget -qO- --no-check-certificate "http://crl.roskazna.ru/crl/ucfk.crl"| /opt/cprocsp/bin/amd64/certmgr -inst -crl -stdin
wget -qO- --no-check-certificate "https://adm44.ru/i/u/uc_korn_sert.cer"| /opt/cprocsp/bin/amd64/certmgr -inst -store mRoot -stdin
wget -qO- --no-check-certificate "https://adm44.ru/i/u/ca_ako.cer"| /opt/cprocsp/bin/amd64/certmgr -inst -store mRoot -stdin
wget -qO- --no-check-certificate "https://adm44.ru/i/cert/262BF15DDCDC3BE3ECB0.crl"| /opt/cprocsp/bin/amd64/certmgr -inst -store mca -crl -stdin 
wget -qO- --no-check-certificate "https://adm44.ru/i/cert/D19AD678765F765838D4.crl"| /opt/cprocsp/bin/amd64/certmgr -inst -store mca -crl -stdin
# Новый сертификат https://www.gosuslugi.ru/crt
wget -qO- --no-check-certificate "https://gu-st.ru/content/Other/doc/russian_trusted_root_ca.cer"|/opt/cprocsp/bin/amd64/certmgr -inst -store mRoot -stdin
wget -qO- --no-check-certificate "https://gu-st.ru/content/Other/doc/russian_trusted_sub_ca.cer"|/opt/cprocsp/bin/amd64/certmgr -inst -stdin
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
#rm /etc/apt/sources.list.d/drweb.list
#apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8C42FC58D8752769
#echo "deb http://repo.drweb.com/drweb/debian 11.1 non-free" >> /etc/apt/sources.list.d/drweb.list
#apt-get update
#apt-get install drweb-workstations -y
wget https://192.168.10.248:9081/install/unix/workstation/drweb-11.1.4-av-linux-amd64.run --no-check-certificate -P antivir/
wget https://192.168.10.248:9081/install/unix/workstation/drwcsd-certificate.pem --no-check-certificate -P antivir/
cd antivir
chmod +x drweb-11.1.4-av-linux-amd64.run
./drweb-11.1.4-av-linux-amd64.run -- --non-interactive
cd ..

}


system_update(){
#полное обновление системы
apt update 
apt upgrade
}

installing_the_required_packages(){
system_update
#библиотека SASL для Psi+
apt install libsasl2-modules -y
# установка пакетов, необходимых для работы
apt install screen htop smartmontools ntp nfs-common rsync util-linux printer-driver-gutenprint printer-driver-splix printer-driver-cups-pdf chromium xrdp simple-scan -y
# установка дополнительных пакетов для КриптоПроCSP
apt install libccid pcscd libgost-astra -y
#драйвера для принтера и сканера Samsung
wget -c https://archive.org/download/uld_V1.00.39_01.17.tar/uld_V1.00.39_01.17.tar.gz
tar -xzf uld_V1.00.39_01.17.tar.gz
cd uld 
./install.sh
cd ..
restart_service
#Включить TRIM, если в системе установлен SSD
ssd=`cat /sys/block/sda/queue/rotational`
if [$ssd=0]; then
    cp /usr/share/doc/util-linux/examples/fstrim.service /etc/systemd/system 
    cp /usr/share/doc/util-linux/examples/fstrim.timer /etc/systemd/system 
    systemctl enable fstrim.timer
    sed -i 's/issue_discards = 0/issue_discards = 1/' /etc/lvm/lvm.conf
fi

#установка audit
systemctl is-active --quiet auditd || {
apt install audispd-plugins auditd -y
echo '*.*@10.0.4.67:514' >> /etc/rsyslog.conf && sed -i 's/.*active.*/active\ =\ yes/g' /etc/audisp/plugins.d/syslog.conf
systemctl restart rsyslog auditd
}
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

}

install15(){
installing_the_required_packages
remove_unnecessary_packages
exact_time
install_DrWeb
X11VNC_install
}   

installas(){
wget https://мойассистент.рф/%D1%81%D0%BA%D0%B0%D1%87%D0%B0%D1%82%D1%8C/Download/617
dpkg -i 617
}

full_menu(){
OPTION=$(whiptail --title  "Настройка клиента Astra Linux CE" --menu  "Выберите пункт:" "${HEIGHT}" "${WIDTH}" 9 \
"1" "Установка требуемых пакетов\Обновление системы" \
"2" "Удаление нетребуемых пакетов\Обновление системы" \
"3" "Настройка точного времени" \
"4" "Настройка сервиса X11VNC" \
"5" "Установка антивируса Dr.Web" \
"6" "Автоматическая установка пунктов 1-5" \
"7" "Установка Ассистент" \
"8" "Установка и\или обновление КриптоПроCSP+Cades+токены " \
"9" "Установка и\или обновление плагина Госуслуги" 3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ];  then
     echo "Вы выбрали:" $OPTION
else
     echo "Вы выбрали Cancel."
fi

case $OPTION in
   "1") installing_the_required_packages;operation_success;full_menu;;
   "2") remove_unnecessary_packages;operation_success;full_menu;;
   "3") exact_time;operation_success;full_menu;;
   "4") X11VNC_install;operation_success;full_menu;;
   "5") install_DrWeb;operation_success;full_menu;;
   "6") install15;operation_success;full_menu;;
   "7") installas;operation_success;full_menu;;
   "8") install_CryptoPro;operation_success;full_menu;;
   "9") install_Gosuslugi;operation_success;full_menu;;
esac    

clear
}


main_menu() {
    whiptail --title "Настройка клиента Astra Linux CE" \
        --yesno "Быстрая настройка нескольких пунктов Astra Linux
        
Этот скрипт позволяет: 
* выполнить обновление системы
* добавить/удалить необходимые пакеты
* установить сервис точного времени
* удаленный доступ к АРМ X11VNC
* установить и/или обновить КриптоПроCSP
* обновление плагинов для браузера
* установка антивируса DrWeb


Нажмите Next для вызова меню или Exit, если хотите выйти из скрипта  " \
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
