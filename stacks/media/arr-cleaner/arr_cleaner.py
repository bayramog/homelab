#!/usr/bin/env python3
"""
ARR Cleaner - Radarr ve Sonarr için unmonitored içerik temizleyici
Bu script her saat çalışarak unmonitored olan indirilmiş dosyaları siler.
"""

import os
import sys
import time
import json
import logging
import requests
import schedule
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

# Logging ayarları
logging.basicConfig(
    level=getattr(logging, os.getenv('LOG_LEVEL', 'INFO')),
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

class ArrCleaner:
    def __init__(self):
        self.radarr_url = os.getenv('RADARR_URL', 'http://192.168.4.110:7878')
        self.radarr_api_key = os.getenv('RADARR_API_KEY')
        self.sonarr_url = os.getenv('SONARR_URL', 'http://192.168.4.110:8989')
        self.sonarr_api_key = os.getenv('SONARR_API_KEY')
        self.dry_run = os.getenv('DRY_RUN', 'false').lower() == 'true'
        self.data_path = os.getenv('DATA_PATH', '/data')
        
        # API headers
        self.radarr_headers = {'X-Api-Key': self.radarr_api_key}
        self.sonarr_headers = {'X-Api-Key': self.sonarr_api_key}
        
        logger.info(f"ARR Cleaner başlatıldı - DRY_RUN: {self.dry_run}")
        
    def make_request(self, url: str, headers: Dict) -> Optional[List]:
        """API isteği gönder"""
        try:
            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"API isteği hatası: {url} - {e}")
            return None
    
    def delete_file_or_folder(self, path: str) -> bool:
        """Dosya veya klasörü sil"""
        try:
            file_path = Path(path)
            if not file_path.exists():
                logger.warning(f"Dosya/klasör bulunamadı: {path}")
                return False
                
            if self.dry_run:
                logger.info(f"[DRY RUN] Silinecek: {path}")
                return True
                
            if file_path.is_file():
                file_path.unlink()
                logger.info(f"Dosya silindi: {path}")
            elif file_path.is_dir():
                import shutil
                shutil.rmtree(path)
                logger.info(f"Klasör silindi: {path}")
            
            return True
        except Exception as e:
            logger.error(f"Silme hatası: {path} - {e}")
            return False
    
    def clean_radarr_unmonitored(self):
        """Radarr'da unmonitored filmleri temizle"""
        logger.info("Radarr unmonitored filmler kontrol ediliyor...")
        
        # Tüm filmleri al
        movies = self.make_request(f"{self.radarr_url}/api/v3/movie", self.radarr_headers)
        if not movies:
            logger.error("Radarr filmler alınamadı")
            return
            
        deleted_count = 0
        for movie in movies:
            if not movie.get('monitored', True):  # Unmonitored film
                if movie.get('hasFile', False):  # İndirilmiş dosyası var
                    movie_path = movie.get('path', '')
                    if movie_path and os.path.exists(movie_path):
                        logger.info(f"Unmonitored film bulundu: {movie.get('title', 'Unknown')}")
                        if self.delete_file_or_folder(movie_path):
                            deleted_count += 1
                            
                            # Radarr'da sadece dosya referansını temizle (içeriği silme)
                            if not self.dry_run:
                                try:
                                    # Refresh movie to update file status
                                    refresh_url = f"{self.radarr_url}/api/v3/command"
                                    refresh_payload = {
                                        "name": "RefreshMovie", 
                                        "movieId": movie['id']
                                    }
                                    requests.post(refresh_url, headers=self.radarr_headers, json=refresh_payload)
                                    logger.info(f"Radarr'da dosya durumu güncellendi: {movie.get('title', 'Unknown')} (unmonitored olarak kaldı)")
                                except Exception as e:
                                    logger.error(f"Radarr refresh hatası: {e}")
        
        logger.info(f"Radarr temizlik tamamlandı. Silinen film sayısı: {deleted_count}")
    
    def clean_sonarr_unmonitored(self):
        """Sonarr'da unmonitored içerikleri kademeli olarak temizle"""
        logger.info("Sonarr unmonitored içerikler kontrol ediliyor...")
        
        # Tüm dizileri al
        series = self.make_request(f"{self.sonarr_url}/api/v3/series", self.sonarr_headers)
        if not series:
            logger.error("Sonarr diziler alınamadı")
            return
            
        deleted_series = 0
        deleted_seasons = 0
        deleted_episodes = 0
        
        for show in series:
            series_id = show['id']
            series_title = show.get('title', 'Unknown')
            series_monitored = show.get('monitored', True)
            series_path = show.get('path', '')
            
            # 1. ADIM: Tüm dizi unmonitored ise
            if not series_monitored and series_path and os.path.exists(series_path):
                logger.info(f"Tamamen unmonitored dizi: {series_title}")
                if self.delete_file_or_folder(series_path):
                    deleted_series += 1
                    continue  # Bu dizi silindi, diğer kontrole gerek yok
            
            # 2. ADIM: Sezon bazında kontrol
            seasons = self.make_request(f"{self.sonarr_url}/api/v3/season?seriesId={series_id}", self.sonarr_headers)
            if not seasons:
                continue
                
            for season in seasons:
                season_number = season.get('seasonNumber', 0)
                season_monitored = season.get('monitored', True)
                
                if not season_monitored:
                    # Unmonitored sezon - sezon klasörünü sil
                    season_path = os.path.join(series_path, f"Season {season_number:02d}")
                    if os.path.exists(season_path):
                        logger.info(f"Unmonitored sezon: {series_title} - Season {season_number}")
                        if self.delete_file_or_folder(season_path):
                            deleted_seasons += 1
                    continue
                
                # 3. ADIM: Bölüm bazında kontrol (sadece monitored sezonlar için)
                episodes = self.make_request(f"{self.sonarr_url}/api/v3/episode?seriesId={series_id}&seasonNumber={season_number}", self.sonarr_headers)
                if not episodes:
                    continue
                    
                for episode in episodes:
                    episode_monitored = episode.get('monitored', True)
                    has_file = episode.get('hasFile', False)
                    
                    if not episode_monitored and has_file:
                        # Unmonitored bölüm - dosyayı sil
                        episode_file_id = episode.get('episodeFileId')
                        if episode_file_id:
                            # Episode file bilgisini al
                            file_info = self.make_request(f"{self.sonarr_url}/api/v3/episodefile/{episode_file_id}", self.sonarr_headers)
                            if file_info:
                                file_path = file_info.get('path', '')
                                if file_path and os.path.exists(file_path):
                                    episode_title = f"{series_title} S{season_number:02d}E{episode.get('episodeNumber', 0):02d}"
                                    logger.info(f"Unmonitored bölüm: {episode_title}")
                                    if self.delete_file_or_folder(file_path):
                                        deleted_episodes += 1
                                        
                                        # Sonarr'da episode file kaydını sil (episode'u değil)
                                        if not self.dry_run:
                                            try:
                                                delete_url = f"{self.sonarr_url}/api/v3/episodefile/{episode_file_id}"
                                                requests.delete(delete_url, headers=self.sonarr_headers)
                                                logger.info(f"Episode file kaydı silindi (episode unmonitored kaldı): {episode_title}")
                                            except Exception as e:
                                                logger.error(f"Episode file silme hatası: {e}")
        
        logger.info(f"Sonarr temizlik tamamlandı. Silinen: {deleted_series} dizi, {deleted_seasons} sezon, {deleted_episodes} bölüm")
    
    def run_cleanup(self):
        """Ana temizlik işlemi"""
        logger.info("=== ARR Cleaner başlatılıyor ===")
        start_time = datetime.now()
        
        try:
            # Radarr temizlik
            self.clean_radarr_unmonitored()
            
            # Sonarr temizlik
            self.clean_sonarr_unmonitored()
            
        except Exception as e:
            logger.error(f"Temizlik işlemi sırasında hata: {e}")
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        logger.info(f"=== ARR Cleaner tamamlandı - Süre: {duration:.1f} saniye ===")

def main():
    """Ana fonksiyon"""
    cleaner = ArrCleaner()
    
    # İlk çalıştırma
    cleaner.run_cleanup()
    
    # Zamanlayıcı kurulumu
    cron_schedule = os.getenv('CRON_SCHEDULE', '0 * * * *')  # Her saat
    logger.info(f"Zamanlayıcı ayarlandı: {cron_schedule}")
    
    # Basit cron parser - sadece saatlik çalışma için
    if cron_schedule == '0 * * * *':
        schedule.every().hour.at(":00").do(cleaner.run_cleanup)
    else:
        # Manuel çalışma için 1 saatte bir
        schedule.every().hour.do(cleaner.run_cleanup)
    
    logger.info("ARR Cleaner hazır - zamanlayıcı başlatıldı")
    
    # Sürekli çalış
    while True:
        schedule.run_pending()
        time.sleep(60)  # Her dakika kontrol et

if __name__ == "__main__":
    main()
