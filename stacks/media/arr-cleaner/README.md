# ARR Cleaner - Unmonitored İçerik Temizleyici

Bu script Radarr ve Sonarr'da unmonitored olan indirilmiş dosyaları otomatik olarak siler.

## Özellikler

### Radarr Temizliği
- Unmonitored filmlerin dosyalarını siler
- ❗ **Film kaydı Radarr'da kalır** (sadece dosya referansı temizlenir)
- Film unmonitored olarak işaretli kalır

### Sonarr Temizliği (Kademeli)
1. **Dizi Seviyesi**: Tüm dizi unmonitored ise → Tüm dizi klasörünü sil
2. **Sezon Seviyesi**: Belirli sezon unmonitored ise → O sezon klasörünü sil  
3. **Bölüm Seviyesi**: Belirli bölümler unmonitored ise → Sadece o bölüm dosyalarını sil

❗ **Önemli**: Diziler, sezonlar ve bölümler unmonitored olarak Sonarr'da kalır

## Kurulum

### 1. Script Dosyalarını Yerleştirin

```bash
# Script dizinini oluşturun
sudo mkdir -p /mnt/internal-ssd/apps/arr-cleaner/scripts

# Python script'ini kopyalayın
sudo cp arr_cleaner.py /mnt/internal-ssd/apps/arr-cleaner/scripts/

# İzinleri ayarlayın
sudo chown -R $USER:$USER /mnt/internal-ssd/apps/arr-cleaner
sudo chmod +x /mnt/internal-ssd/apps/arr-cleaner/scripts/arr_cleaner.py
```

### 2. Yapılandırma

`arr-cleaner.yml` dosyasında aşağıdaki ayarları kontrol edin:

```yaml
environment:
  # Test modu (true = sadece log, false = gerçekten sil)
  - DRY_RUN=false  
  
  # Çalışma sıklığı (her saat)
  - CRON_SCHEDULE=0 * * * *
  
  # Log seviyesi
  - LOG_LEVEL=INFO
```

### 3. MediaTools'a Ekleyin

`mediatools.yml` dosyasına ekleyin:

```yaml
include:
  # ...diğer servisler...
  - ./stacks/media/arr-cleaner/arr-cleaner.yml
```

### 4. Başlatın

```bash
docker-compose -f mediatools.yml up -d arr-cleaner
```

## Güvenlik

### Test Modu
İlk çalıştırmadan önce mutlaka test modunu kullanın:

```yaml
- DRY_RUN=true  # Sadece hangi dosyaların silineceğini gösterir
```

### Log Kontrolü
```bash
# Gerçek zamanlı log izleme
docker logs arr-cleaner -f

# Son 100 log satırı
docker logs arr-cleaner --tail 100
```

## Çalışma Mantığı

### Radarr İçin:
1. Tüm filmleri API'den al
2. `monitored: false` olan filmleri bul
3. `hasFile: true` olan unmonitored filmleri sil
4. ❗ **Film kaydı Radarr'da kalır** (unmonitored olarak)

### Sonarr İçin:
1. **Dizi Kontrolü**: 
   - `monitored: false` olan dizilerin tüm klasörünü sil
   - ❗ **Dizi kaydı Sonarr'da kalır** (unmonitored olarak)
   
2. **Sezon Kontrolü**: 
   - Monitored dizilerde `monitored: false` olan sezonları sil
   - ❗ **Sezon kaydı Sonarr'da kalır** (unmonitored olarak)
   
3. **Bölüm Kontrolü**: 
   - Monitored sezonlarda `monitored: false` olan bölümleri sil
   - ❗ **Bölüm kaydı Sonarr'da kalır** (unmonitored olarak)

## Önemli Notlar

⚠️ **DİKKAT**: Bu script dosyaları kalıcı olarak siler!

✅ **Öneriler**:
- İlk çalıştırmada `DRY_RUN=true` kullanın
- Düzenli yedek alın
- Log dosyalarını kontrol edin
- Test ortamında önce deneyin

🔄 **Çalışma Sıklığı**:
- Varsayılan: Her saat başı
- Özelleştirilebilir: `CRON_SCHEDULE` değişkeni ile

📊 **Monitoring**:
- Container durumu: `docker ps | grep arr-cleaner`
- Loglar: `docker logs arr-cleaner`
- Manuel çalıştırma: `docker restart arr-cleaner`
