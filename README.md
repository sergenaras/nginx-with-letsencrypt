# nginx-with-letsencrypt

Let's Encrypt 12 Nisan 2016 tarihinden bu yana internet üzerindeki sitelere ücretsiz olarak TLs şifreleme için sertifika dağıtan bir organizasyondur. Bilişim teknolojileri alanındaki pek çok firma tarafından desteklenmektedir. İlgili firmalar ve daha fazlasını öğrenmek için web sitelerine göz atabilirsiniz. 

Bu script, üzerinde hiçbir işlem yapılmamış bir Centos 7 makinenin içerisine Nginx kurulumu yapar ve sonrasında alan adınızla bu siteyi ilişkilendirip SSL sertifikası sağlar. Script'i makinede uygulamadan önce uygulayacağınız alan göre firewall ile ilgili ayarları yapmalı ve alan adınızı satın aldığınız yerdeki yönlendirmeleri yapmış olmalısınız. 

