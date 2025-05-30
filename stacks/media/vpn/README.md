# VPN Kurulum Rehberi (Custom OVPN)

Bu VPN yapılandırması, VPN sağlayıcınızın verdiği OVPN dosyasını kullanır.

## Kurulum Adımları

### 1. OVPN Dosyasını Yerleştirme

VPN sağlayıcınızdan aldığınız OVPN dosyasını aşağıdaki konuma kopyalayın:

```bash
# VPN dizinini oluşturun
sudo mkdir -p /mnt/internal-ssd/apps/vpn

# OVPN dosyanızı custom.ovpn olarak kopyalayın
sudo cp /path/to/your/vpn-config.ovpn /mnt/internal-ssd/apps/vpn/custom.ovpn

# İzinleri ayarlayın
sudo chown -R $USER:$USER /mnt/internal-ssd/apps/vpn
```

### 2. Kullanıcı Bilgilerini Güncelleme

`vpn.yml` dosyasındaki kullanıcı bilgilerini güncelleyin:

```yaml
- OPENVPN_USER=YOUR_VPN_USERNAME    # VPN kullanıcı adınız
- OPENVPN_PASSWORD=YOUR_VPN_PASSWORD # VPN şifreniz
```

**Not:** Eğer OVPN dosyanızda kullanıcı bilgileri varsa, bu satırları silebilirsiniz.

### 3. Container'ları Başlatma

```bash
# Container'ları başlat
docker-compose -f mediatools.yml up -d

# VPN bağlantısını kontrol et
docker logs vpn

# IP adresinizi kontrol edin (VPN IP'sini görmeli)
docker exec vpn curl -s ifconfig.me
```

### 4. Bağlantı Kontrolü

VPN'in düzgün çalıştığını kontrol etmek için:

```bash
# VPN container'ının loglarını kontrol et
docker logs vpn -f

# Excludarr'ın VPN üzerinden çalıştığını kontrol et
docker exec excludarr curl -s ifconfig.me
```

## Dosya Yapısı

```
/mnt/internal-ssd/apps/vpn/
├── custom.ovpn          # VPN sağlayıcınızın OVPN dosyası
└── gluetun/            # Gluetun container'ının verileri
```

## Sorun Giderme

### OVPN Dosyası Hataları

Eğer OVPN dosyanızda sorun varsa:

1. Dosyanın doğru formatta olduğunu kontrol edin
2. Dosya izinlerini kontrol edin
3. Container'ı yeniden başlatın: `docker restart vpn`

### Bağlantı Sorunları

```bash
# Container'ın durumunu kontrol et
docker ps | grep vpn

# Detaylı logları görüntüle
docker logs vpn --details

# Container'ı yeniden başlat
docker restart vpn
```

### IP Sızıntısı Kontrolü

```bash
# Gerçek IP'nizi kontrol edin (VPN kapalıyken)
curl -s ifconfig.me

# VPN IP'sini kontrol edin
docker exec vpn curl -s ifconfig.me

# Bu iki IP farklı olmalı!
```
