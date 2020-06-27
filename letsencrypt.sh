#!/bin/bash

nginx_control(){
	is_nginx_installed=$(yum list installed | grep nginx)
	if [[ -z "$is_nginx_installed" ]]; then
		nginx_install
	elif [[ -n "$is_nginx_installed" ]]; then
		echo "$nginx_name yüklü"
	fi
}

nginx_install(){
	echo "Nginx yüklü değil. Yüklemek ister misin? (y/n)"
	read selection
	if [[ "$selection" == "Y" || "$selection" == "y" || "$selection" == "E" || "$selection" == "e" ]]; then
		echo "Yükleme işlemi başlıyor" 
		yum -y update > /dev/null
		echo "Update işlemi yapıldı"
		yum -y install epel-release	> /dev/null
		echo "Epel deposu yüklendi"
		yum -y install nginx > /dev/null
		echo "Nginx yazılımı yüklendi"
		systemctl start nginx
		systemctl enable nginx
		echo "Nginx sistem tarafında açılışta çalıştırılacak şekilde etkin hale getirildi"
	elif [[ "$selection" == "N" || "$selection" == "n" || "$selection" == "H" || "$selection" == "h"  ]]; then
		echo "Scriptten çıkılıyor"
		exit 1
	else
		echo "Yanlış değer girildi."
	fi	
}

# ssl öncesi kontroller
nginx_control

#ssl işlemini yapacak tool
yum -y install certbot > /dev/null
echo "Certbot yüklendi"

#ssl işin kullanılacak şifreleme anahtarı
dhparam_key=2048
echo "Şifreleme anahtarı kaç bit olsun? Ne kadar yüksek olursa o kadar güvenli olur ancak oluşturması da o kadar uzun sürer (Varsayılan: 2048)"
read dh_answer
if [[ -z $dh_answer ]]; then
	dhparam_key=2048
elif [[ -n $dh_answer ]]; then
	dhparam_key=$dh_answer
fi

openssl dhparam -out /etc/ssl/certs/dhparam.pem $dhparam_key > /dev/null
echo "dhparam komutu ile şifreleme anahtarı oluşturuldu"

#ilgili dizinlerin oluşturulması ve yekilendirilmesi
mkdir -p /var/lib/letsencrypt/.well-known
chgrp nginx /var/lib/letsencrypt
chmod g+s /var/lib/letsencrypt
mkdir /etc/nginx/snippets
echo "Let's Encrypt tarafında yapılan işlemler için gerekli dizinler oluşturuldu ve yetkileri ayarlandı"

#bu dosya ile aynı lokasyonda bulunan dosyaların ilgili yerlere taşınması
cp conf/letsencrypt.conf /etc/nginx/snippets/
cp conf/ssl.conf /etc/nginx/snippets/
echo "Oluşturulan dizinlere ilgili konfigürasyon dosyaları kopyalandı"

#alan adı ile ilgili ayarların olduğu kısım
domain_q="SSL sertifika eklemek istediğiniz alan adınız nedir?" 
echo $domain_q
read domain_name
sed -i s/example.com/$domain_name/g conf/nginxconf1
mv conf/nginxconf1 conf/$domain_name.conf
cp conf/$domain_name.conf /etc/nginx/conf.d/
mv conf/$domain_name.conf conf/$domain_name.conf.old
echo "Alan adı ile ilgili nginx tarafındaki konfigürasyon oluşturuldu"

#nginx'in ayarlarının yeniden başlatılması
nginx -t
systemctl reload nginx

#ssl sertifikasını aldığımız bölüm
mail_q="Mail adresiniz nedir?" 
echo $mail_q
read mail_address
certbot certonly --agree-tos --email $mail_address --webroot -w /var/lib/letsencrypt/ -d $domain_name -d www.$domain_name

#nginx tarafındaki konfigürasyon dosyamızı http'den https'e www'den non-www'e yönlendiren farklı bir konfigürasyon ile değiştiriyoruz
sed -i s/example.com/$domain_name/g conf/nginxconf2
mv conf/nginxconf2 conf/$domain_name.conf
cp conf/$domain_name.conf /etc/nginx/conf.d/

systemctl reload nginx

crontab -l > mycron
echo "0 */12 * * * root test -x /usr/bin/certbot -a \! -d /run/systemd/system && perl -e 'sleep int(rand(3600))' && certbot -q renew --renew-hook "systemctl reload nginx"
" >> mycron
crontab mycron
rm mycron

certbot renew --dry-run
