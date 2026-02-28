import 'dart:math';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/market.dart';
import '../models/address.dart';
import '../../core/regions/provinces.dart';

abstract class MarketRepository {
  /// Returns a list of nearby markets based on a location
  Future<List<Market>> fetchNearbyMarkets({required Address forAddress});

  /// Returns a list of markets matching the given IDs
  Future<List<Market>> fetchMarketsByIds(List<String> ids);

  /// Returns all markets
  Future<List<Market>> fetchAllMarkets();
}

class MockMarketRepository implements MarketRepository {
  // Mock verileri tekrar kullanmak için private bir getter
  List<Market> get _allMockMarkets {
    return [
      // Bosphorus / Beyoğlu area
      _createMarket(
        'm1',
        'Taksim Semt Pazarı',
        'Taksim çevresinde taze ürünler',
        41.0369,
        28.9858,
        'Taksim',
        'Beyoğlu',
        ['Cumartesi', 'Pazar'],
      ),
      _createMarket(
        'm2',
        'Beyoğlu Pazarı',
        'Beyoğlu semt pazarı',
        41.0317,
        28.9760,
        'Karaköy',
        'Beyoğlu',
        ['Çarşamba'],
      ),
      // Fatih / Eminönü
      _createMarket(
        'm3',
        'Eminönü Pazarı',
        'Denize yakın semt pazarı',
        41.0134,
        28.9713,
        'Eminönü',
        'Fatih',
        ['Cumartesi'],
      ),
      _createMarket(
        'm4',
        'Fatih Mahalle Pazarı',
        'Fatih semt pazarı',
        41.0151,
        28.9550,
        'Fatih',
        'Fatih',
        ['Perşembe'],
      ),
      // Beşiktaş / Ortaköy / Kabataş
      _createMarket(
        'm5',
        'Beşiktaş Semt Pazarı',
        'Balık ve meyve-sebze',
        41.0430,
        29.0000,
        'Beşiktaş',
        'Beşiktaş',
        ['Cuma'],
      ),
      _createMarket(
        'm6',
        'Ortaköy Pazarı',
        'Hafta sonu pazar',
        41.0475,
        29.0239,
        'Ortaköy',
        'Beşiktaş',
        ['Cumartesi', 'Pazar'],
      ),
      // Kadıköy / Moda
      _createMarket(
        'm7',
        'Kadıköy Pazarı',
        'Taze meyve ve sebze',
        40.9860,
        29.0259,
        'Kadıköy',
        'Kadıköy',
        ['Pazar'],
      ),
      _createMarket(
        'm8',
        'Moda Semt Pazarı',
        'Organik ve yerel',
        40.9865,
        29.0241,
        'Moda',
        'Kadıköy',
        ['Cumartesi'],
      ),
      // Üsküdar
      _createMarket(
        'm9',
        'Üsküdar Pazarı',
        'Geleneksel semt pazarı',
        41.0210,
        29.0040,
        'Üsküdar',
        'Üsküdar',
        ['Cuma'],
      ),
      // Şişli / Mecidiyeköy
      _createMarket(
        'm10',
        'Şişli Semt Pazarı',
        'Meyve, sebze ve günlük ihtiyaç',
        41.0623,
        28.9916,
        'Nişantaşı',
        'Şişli',
        ['Cumartesi'],
      ),
      // Bakırköy
      _createMarket(
        'm11',
        'Bakırköy Semt Pazarı',
        'Hafta sonu pazarı',
        40.9821,
        28.8727,
        'Bakırköy',
        'Bakırköy',
        ['Cumartesi'],
      ),
      // Ataşehir
      _createMarket(
        'm12',
        'Ataşehir Pazarı',
        'İçiçe semt pazarı',
        40.9920,
        29.1220,
        'Ataşehir',
        'Ataşehir',
        ['Pazar'],
      ),
      // Ümraniye
      _createMarket(
        'm13',
        'Ümraniye Pazarı',
        'Geniş ürün yelpazesi',
        41.0210,
        29.0730,
        'Ümraniye',
        'Ümraniye',
        ['Cumartesi'],
      ),
      // Maltepe
      _createMarket(
        'm14',
        'Maltepe Pazarı',
        'Sahil kenarı pazar',
        40.9209,
        29.1236,
        'Maltepe',
        'Maltepe',
        ['Pazar'],
      ),
      // Kartal
      _createMarket(
        'm15',
        'Kartal Pazarı',
        'Semt pazarı',
        40.8800,
        29.2050,
        'Kartal',
        'Kartal',
        ['Cumartesi'],
      ),
      // Pendik
      _createMarket(
        'm16',
        'Pendik Pazarı',
        'Büyük semt pazarı',
        40.8710,
        29.2357,
        'Pendik',
        'Pendik',
        ['Cumartesi'],
      ),
      // Sultangazi
      _createMarket(
        'm17',
        'Sultangazi Semt Pazarı',
        'Geniş pazar',
        41.1600,
        28.8580,
        'Sultangazi',
        'Sultangazi',
        ['Cumartesi'],
      ),
      // Güngören
      _createMarket(
        'm18',
        'Güngören Pazarı',
        'Mahalle pazarı',
        41.0113,
        28.8592,
        'Güngören',
        'Güngören',
        ['Cuma'],
      ),
      // Bağcılar
      _createMarket(
        'm19',
        'Bağcılar Pazarı',
        'Günün taze ürünleri',
        41.0355,
        28.8552,
        'Bağcılar',
        'Bağcılar',
        ['Cumartesi'],
      ),
      // Avcılar
      _createMarket(
        'm20',
        'Avcılar Pazarı',
        'Merkezi pazaryeri',
        40.9923,
        28.7049,
        'Avcılar',
        'Avcılar',
        ['Pazar'],
      ),
      // Sarıyer
      _createMarket(
        'm21',
        'Sarıyer Pazarı',
        'Karadeniz kıyısı pazar',
        41.1886,
        29.0496,
        'Sarıyer',
        'Sarıyer',
        ['Pazar'],
      ),
      // Eyüpsultan
      _createMarket(
        'm22',
        'Eyüpsultan Pazarı',
        'Tarihi mahallesiyle bilinir',
        41.0486,
        28.9293,
        'Eyüp',
        'Eyüpsultan',
        ['Cumartesi'],
      ),
      // Arnavutköy
      _createMarket(
        'm23',
        'Arnavutköy Pazarı',
        'Yeni gelişen semt pazarı',
        41.1439,
        28.7240,
        'Arnavutköy',
        'Arnavutköy',
        ['Cumartesi'],
      ),
      // Büyükçekmece
      _createMarket(
        'm24',
        'Büyükçekmece Pazarı',
        'Batı istanbul pazar',
        41.0030,
        28.5432,
        'Büyükçekmece',
        'Büyükçekmece',
        ['Cumartesi'],
      ),
      // Çekmeköy
      _createMarket(
        'm25',
        'Çekmeköy Pazarı',
        'Doğa kenarı pazar',
        41.0618,
        29.1280,
        'Çekmeköy',
        'Çekmeköy',
        ['Pazar'],
      ),
      // Kağıthane
      _createMarket(
        'm26',
        'Kağıthane Pazarı',
        'Sanayi ve semt pazarı',
        41.0684,
        28.9705,
        'Kağıthane',
        'Kağıthane',
        ['Cuma'],
      ),
      // Zeytinburnu
      _createMarket(
        'm27',
        'Zeytinburnu Pazarı',
        'Sahil semt pazarı',
        41.0021,
        28.9024,
        'Zeytinburnu',
        'Zeytinburnu',
        ['Cumartesi'],
      ),
      // --- Şanlıurfa / Karaköprü Pazarları ---
      // PAZARTESİ
      _createMarket(
        'kp_pzt1',
        'Karşıyaka Kapalı Semt Pazarı',
        '4002. Sk., Çevik Kuvvet Bölgesi (Kazancı Bedih Parkı Yanı)',
        37.1800,
        38.8000,
        'Karşıyaka',
        'Karaköprü',
        ['Pazartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'kp_pzt2',
        'Atakent Kapalı Semt Pazarı',
        '6089. Sk., Mehmet Güneş Arkası',
        37.1680,
        38.7920,
        'Atakent',
        'Karaköprü',
        ['Pazartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'kp_pzt3',
        'Güllübağ Çadırlı Semt Pazarı',
        '3011. Sk., 603. Cad. Yolu Üzeri',
        37.1900,
        38.7800,
        'Güllübağ',
        'Karaköprü',
        ['Pazartesi'],
        city: 'Şanlıurfa',
      ),
      // SALI
      _createMarket(
        'kp_sal1',
        'Akbayır Açık Semt Pazarı',
        '1019. Sk., Çırağan Sitesi Önü',
        37.1850,
        38.7850,
        'Akbayır',
        'Karaköprü',
        ['Salı'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'kp_sal2',
        'Doğukent Kapalı Semt Pazarı',
        '1237. Sk., Gençlik Spor Müdürlüğü Arkası',
        37.1820,
        38.8050,
        'Doğukent',
        'Karaköprü',
        ['Salı'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'kp_sal3',
        'Batıkent Açık Semt Pazarı',
        '4230. Sk. (Kooperatif-2)',
        37.1950,
        38.8100,
        'Batıkent',
        'Karaköprü',
        ['Salı'],
        city: 'Şanlıurfa',
      ),
      // ÇARŞAMBA
      _createMarket(
        'kp_car1',
        'Akpiyar Kapalı Semt Pazarı',
        '4052. Sk.',
        37.1750,
        38.7950,
        'Akpiyar',
        'Karaköprü',
        ['Çarşamba'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'kp_car2',
        'Seyrantepe Semt Pazarı',
        '8129. Sk., Sağlık Ocağı Altı',
        37.2000,
        38.8200,
        'Seyrantepe',
        'Karaköprü',
        ['Çarşamba'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'kp_car3',
        'Atakent Açık Semt Pazarı',
        '6092. Sk., 2. Etap Faruk Çelik Kompleksi Arkası',
        37.1690,
        38.7930,
        'Atakent',
        'Karaköprü',
        ['Çarşamba'],
        city: 'Şanlıurfa',
      ),
      // PERŞEMBE
      _createMarket(
        'kp_per1',
        'Seyrantepe Açık Semt Pazarı',
        '8275. Sk. (Yol üzerine kuruluyor)',
        37.2010,
        38.8210,
        'Seyrantepe',
        'Karaköprü',
        ['Perşembe'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'kp_per2',
        'Narlıkuyu Kapalı Semt Pazarı',
        '1142. Sk.',
        37.1750,
        38.8100,
        'Narlıkuyu',
        'Karaköprü',
        ['Perşembe'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'kp_per3',
        'Narlıkuyu (Koop-2) Semt Pazarı',
        '1308. Sk.',
        37.1760,
        38.8110,
        'Narlıkuyu',
        'Karaköprü',
        ['Perşembe'],
        city: 'Şanlıurfa',
      ),
      // CUMA
      _createMarket(
        'kp_cum1',
        'Şenevler Kapalı Semt Pazarı',
        '6129-6132. Sk.',
        37.1720,
        38.7950,
        'Şenevler',
        'Karaköprü',
        ['Cuma'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'kp_cum2',
        'Şenevler (Cuma 2) Semt Pazarı',
        '6132. Sk.',
        37.1730,
        38.7960,
        'Şenevler',
        'Karaköprü',
        ['Cuma'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'kp_cum3',
        'Çankaya Küçük Cuma Pazarı',
        '2007. Sk., 35 Metrelik Yol Üzeri',
        37.1780,
        38.7900,
        'Çankaya',
        'Karaköprü',
        ['Cuma'],
        city: 'Şanlıurfa',
      ),
      // CUMARTESİ
      _createMarket(
        'kp_cmt1',
        'Akpiyar (Cmt) Kapalı Semt Pazarı',
        '4003. Cad.',
        37.1760,
        38.7960,
        'Akpiyar',
        'Karaköprü',
        ['Cumartesi'],
        city: 'Şanlıurfa',
      ),
      // --- Haliliye Pazarları ---
      // PAZARTESİ
      _createMarket(
        'hl_pzt1',
        'Ulubatlı Semt Pazarı',
        'Prof. A. Karahan Cd. Turgut Özal Parkı Yanı',
        37.1660,
        38.7920,
        'Ulubatlı',
        'Haliliye',
        ['Pazartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_pzt2',
        'Ertuğrul Gazi Semt Pazarı',
        '323. Sokak Resul Allah Camii Yanı',
        37.1720,
        38.8050,
        'Ertuğrul Gazi',
        'Haliliye',
        ['Pazartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_pzt3',
        'Devteyşti (Pzt) Semt Pazarı',
        '9615. Sokak',
        37.1350,
        38.8250,
        'Devteyşti',
        'Haliliye',
        ['Pazartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_pzt4',
        'Sancaktar Semt Pazarı',
        '1133. Sokak',
        37.1580,
        38.8150,
        'Sancaktar',
        'Haliliye',
        ['Pazartesi'],
        city: 'Şanlıurfa',
      ),
      // SALI
      _createMarket(
        'hl_sal1',
        'Yenişehir Semt Pazarı',
        '235. Sokak',
        37.1550,
        38.7850,
        'Yenişehir',
        'Haliliye',
        ['Salı'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_sal2',
        'İmam Bakır Semt Pazarı',
        'Veteriner Cd. GAP Araştırma Enstitüsü Yanı',
        37.1850,
        38.7750,
        'İmam Bakır',
        'Haliliye',
        ['Salı'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_sal3',
        'Bamyasuyu Semt Pazarı',
        '142. Sokak',
        37.1620,
        38.7900,
        'Bamyasuyu',
        'Haliliye',
        ['Salı'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_sal4',
        'Konuklu Semt Pazarı',
        '5030. Sokak',
        37.1100,
        38.8600,
        'Konuklu',
        'Haliliye',
        ['Salı'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_sal5',
        'Hızmalı Semt Pazarı',
        '49. ve 56. Sokak Hz. Ayşe Camii Yanı',
        37.1580,
        38.7820,
        'Hızmalı',
        'Haliliye',
        ['Salı'],
        city: 'Şanlıurfa',
      ),
      // ÇARŞAMBA & CUMARTESİ (Mimar Sinan aynı yer)
      _createMarket(
        'hl_car1',
        'Mimar Sinan Semt Pazarı',
        'Cengiz Topel Caddesi',
        37.1680,
        38.7880,
        'Mimar Sinan',
        'Haliliye',
        ['Çarşamba', 'Cumartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_car2',
        'Devteyşti (Çar) Semt Pazarı',
        'Salih Özcan Bulvarı',
        37.1360,
        38.8210,
        'Devteyşti',
        'Haliliye',
        ['Çarşamba'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_car3',
        'Sırrın Semt Pazarı',
        'Köylükent Sitesi',
        37.1450,
        38.8100,
        'Sırrın',
        'Haliliye',
        ['Çarşamba'],
        city: 'Şanlıurfa',
      ),
      // PERŞEMBE
      _createMarket(
        'hl_per1',
        'Yeşildirek Semt Pazarı',
        '424. Sokak Yunus Emre Cd. Üzeri',
        37.1750,
        38.8000,
        'Yeşildirek',
        'Haliliye',
        ['Perşembe'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_per2',
        'Ahmet Yesevi (Per) Semt Pazarı',
        '2243. Sokak',
        37.1250,
        38.8050,
        'Ahmet Yesevi',
        'Haliliye',
        ['Perşembe'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_per3',
        'İpekyol Semt Pazarı',
        '1911. Sokak',
        37.1520,
        38.7780,
        'İpekyol',
        'Haliliye',
        ['Perşembe'],
        city: 'Şanlıurfa',
      ),
      // CUMA
      _createMarket(
        'hl_cum1',
        'Karşıyaka Semt Pazarı',
        '590. Sokak',
        37.1650,
        38.8080,
        'Karşıyaka',
        'Haliliye',
        ['Cuma'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_cum2',
        'Yavuz Selim Semt Pazarı',
        '2104. Sokak',
        37.1420,
        38.7950,
        'Yavuz Selim',
        'Haliliye',
        ['Cuma'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_cum3',
        'Şair Nabi Semt Pazarı',
        'Buluntu Hoca Parkı yanı',
        37.1610,
        38.7860,
        'Şair Nabi',
        'Haliliye',
        ['Cuma'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'hl_cum4',
        'Ahmet Yesevi (Cum) Semt Pazarı',
        'Sultan Abdulhamid Bulvarı',
        37.1260,
        38.8060,
        'Ahmet Yesevi',
        'Haliliye',
        ['Cuma'],
        city: 'Şanlıurfa',
      ),
      // CUMARTESİ
      _createMarket(
        'hl_cmt2',
        'Selahaddin Eyyubi Semt Pazarı',
        '219. Sokak',
        37.1560,
        38.8020,
        'Selahaddin Eyyubi',
        'Haliliye',
        ['Cumartesi'],
        city: 'Şanlıurfa',
      ),
      // --- Eyyübiye Pazarları ---
      // PAZARTESİ
      _createMarket(
        'ey_pzt1',
        'Yenice Kapalı Semt Pazarı',
        '3991. Sokak, Yenice Mah.',
        37.1250,
        38.7950,
        'Yenice',
        'Eyyübiye',
        ['Pazartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_pzt2',
        'Nenehatun Semt Pazarı',
        '3630. Sokak, Osmanlı Mah.',
        37.1320,
        38.8050,
        'Osmanlı',
        'Eyyübiye',
        ['Pazartesi', 'Cuma'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_pzt3',
        'Dereboyu Semt Pazarı',
        'Dereboyu, Direkli Mah.',
        37.1450,
        38.7750,
        'Direkli',
        'Eyyübiye',
        ['Pazartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_pzt4',
        'Toki Emekliler Pazarı',
        'Toki Emekliler Sitesi',
        37.1550,
        38.7650,
        'Batıkent',
        'Eyyübiye',
        ['Pazartesi'],
        city: 'Şanlıurfa',
      ),
      // SALI
      _createMarket(
        'ey_sal1',
        'Onikiler Kapalı Semt Pazarı',
        'Harrankapı Cad.',
        37.1380,
        38.7920,
        'Onikiler',
        'Eyyübiye',
        ['Salı', 'Cuma'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_sal2',
        'Muradiye Semt Pazarı',
        'Eyüp Petrol Üstü 3432. Sokak',
        37.1350,
        38.7850,
        'Muradiye',
        'Eyyübiye',
        ['Salı'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_sal3',
        'Hayati Harrani (Salı) Pazarı',
        'Oruç Camii Yanı 3956. Sokak',
        37.1180,
        38.7950,
        'Hayati Harrani',
        'Eyyübiye',
        ['Salı'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_sal4',
        'H. Harrani (Vet) Pazarı',
        'Veterinerlik Fakülte Karşısı',
        37.1200,
        38.7980,
        'Hayati Harrani',
        'Eyyübiye',
        ['Salı'],
        city: 'Şanlıurfa',
      ),
      // ÇARŞAMBA
      _createMarket(
        'ey_car1',
        'Eyüpnabi Semt Pazarı',
        'Akçakale Cad., Hyundai Yanı',
        37.1280,
        38.7880,
        'Eyüpnabi',
        'Eyyübiye',
        ['Çarşamba'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_car2',
        'Beykapısı Semt Pazarı',
        'Mahmutoğlu Bedendibi Cad.',
        37.1520,
        38.7950,
        'Beykapısı',
        'Eyyübiye',
        ['Çarşamba'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_car3',
        'Direkli (Çar) Semt Pazarı',
        'Yıldız Plaza Önü',
        37.1460,
        38.7760,
        'Direkli',
        'Eyyübiye',
        ['Çarşamba'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_car4',
        'Toki Kapalı Semt Pazarı',
        '15 Temmuz Batıkent',
        37.1560,
        38.7660,
        'Batıkent',
        'Eyyübiye',
        ['Çarşamba', 'Cumartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_car5',
        'Şıhmaksut Semt Pazarı',
        'Ceylan Cad.',
        37.1420,
        38.7880,
        'Şıhmaksut',
        'Eyyübiye',
        ['Çarşamba'],
        city: 'Şanlıurfa',
      ),
      // PERŞEMBE
      _createMarket(
        'ey_per1',
        'Yenice (Per) Semt Pazarı',
        '5019. Sokak, Sağlık Ocağı Yanı',
        37.1260,
        38.7960,
        'Yenice',
        'Eyyübiye',
        ['Perşembe'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_per2',
        'Süleymansah Semt Pazarı',
        '3826. Sokak, M. Akif İnan Okulu Yanı',
        37.1350,
        38.7750,
        'Süleymansah',
        'Eyyübiye',
        ['Perşembe'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_per3',
        'Eyüpnabi (Per) Semt Pazarı',
        '3589. Sokak, Erenoğlu Market Yanı',
        37.1290,
        38.7890,
        'Eyüpnabi',
        'Eyyübiye',
        ['Perşembe'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_per4',
        'Dedeosman Semt Pazarı',
        'Zeytinlik Mance',
        37.1480,
        38.7850,
        'Dedeosman',
        'Eyyübiye',
        ['Perşembe'],
        city: 'Şanlıurfa',
      ),
      // CUMA (Onikiler ve Nenehatun yukarıda eklendi)
      _createMarket(
        'ey_cum1',
        'Eyüpkent Kapalı Semt Pazarı',
        '3962. Sokak, Borsa Arkası',
        37.1350,
        38.7800,
        'Eyyüpkent',
        'Eyyübiye',
        ['Cuma'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_cum2',
        'Topdağı Semt Pazarı',
        'Topdağı Mahallesi',
        37.1450,
        38.8020,
        'Topdağı',
        'Eyyübiye',
        ['Cuma'],
        city: 'Şanlıurfa',
      ),
      // CUMARTESİ (Toki Kapalı yukarıda eklendi)
      _createMarket(
        'ey_cmt1',
        'Hacıbayram Semt Pazarı',
        'Umut Sokak',
        37.1420,
        38.7980,
        'Hacıbayram',
        'Eyyübiye',
        ['Cumartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_cmt2',
        'Selçuklu Semt Pazarı',
        'Sokak Açık Semt Pazarı',
        37.1320,
        38.7720,
        'Selçuklu',
        'Eyyübiye',
        ['Cumartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_cmt3',
        'Osmanlı Deresi Semt Pazarı',
        '3725. Sokak',
        37.1330,
        38.8060,
        'Osmanlı',
        'Eyyübiye',
        ['Cumartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_cmt4',
        'Akşemsettin Semt Pazarı',
        'Trafo Yanı',
        37.1380,
        38.7680,
        'Akşemsettin',
        'Eyyübiye',
        ['Cumartesi'],
        city: 'Şanlıurfa',
      ),
      _createMarket(
        'ey_cmt5',
        'Kadıoğlu Semt Pazarı',
        'Tılfindir Parkı Önü',
        37.1550,
        38.7920,
        'Kadıoğlu',
        'Eyyübiye',
        ['Cumartesi'],
        city: 'Şanlıurfa',
      ),
    ];
  }

  @override
  Future<List<Market>> fetchNearbyMarkets({required Address forAddress}) async {
    // Expand mock markets across Istanbul districts with a proper distance calculation
    // so we can sort markets by distance.
    final markets = _allMockMarkets;

    // Filter markets by city to ensure we only show relevant markets
    List<Market> filteredMarkets = markets;
    if (forAddress.city.isNotEmpty) {
      String normalize(String s) {
        var t = s.toLowerCase();
        t = t
            .replaceAll('ş', 's')
            .replaceAll('ı', 'i')
            .replaceAll('ğ', 'g')
            .replaceAll('ü', 'u')
            .replaceAll('ö', 'o')
            .replaceAll('ç', 'c')
            .replaceAll('İ', 'i');
        return t;
      }

      final normalizedUserCity = normalize(forAddress.city);
      filteredMarkets = markets
          .where((m) => normalize(m.address.city) == normalizedUserCity)
          .toList();
    }

    // compute distance for each market
    final lat1 = forAddress.latitude;
    final lon1 = forAddress.longitude;
    final marketsWithDistance = filteredMarkets.map((m) {
      final lat2 = m.address.latitude;
      final lon2 = m.address.longitude;
      final dist = _haversineDistance(lat1, lon1, lat2, lon2);
      // return a new Market instance with distance filled
      return Market(
        id: m.id,
        name: m.name,
        description: m.description,
        address: m.address,
        distanceInMeters: dist,
      );
    }).toList();

    // sort by distance
    marketsWithDistance.sort(
      (a, b) => a.distanceInMeters.compareTo(b.distanceInMeters),
    );

    return marketsWithDistance;
  }

  @override
  Future<List<Market>> fetchMarketsByIds(List<String> ids) async {
    final all = _allMockMarkets;
    return all.where((m) => ids.contains(m.id)).toList();
  }

  @override
  Future<List<Market>> fetchAllMarkets() async {
    return _allMockMarkets;
  }

  Market _createMarket(
    String id,
    String name,
    String desc,
    double lat,
    double lng,
    String neighborhood,
    String district,
    List<String> openDays, {
    String city = 'Şanlıurfa',
  }) {
    return Market(
      id: id,
      name: name,
      description: desc,
      address: Address(
        latitude: lat,
        longitude: lng,
        street: '',
        streetNumber: '',
        neighborhood: neighborhood,
        district: district,
        city: city,
      ),
      distanceInMeters: 0,
      openDays: openDays,
    );
  }

  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Haversine formula to compute distance in meters
    const earthRadius = 6371000.0; // meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * pow(sin(dLon / 2), 2);
    final c = 2 * asin(min(1, sqrt(a)));
    return earthRadius * c;
  }

  double _degToRad(double degree) => degree * pi / 180;
}

/// Fetches market data from Firebase Firestore
class FirestoreMarketRepository implements MarketRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Market>> fetchNearbyMarkets({required Address forAddress}) async {
    try {
      // Şehir bazlı filtreleme (Firestore okuma maliyetini düşürmek için)
      // Not: Firestore'da 'markets' koleksiyonunuzda 'city' alanı olmalıdır.
      Query query = _firestore.collection('markets');

      if (forAddress.city.isNotEmpty) {
        query = query.where('city', isEqualTo: forAddress.city);
      }

      final snapshot = await query.get();

      final markets = snapshot.docs.map((doc) {
        return _mapDocumentToMarket(doc, userLocation: forAddress);
      }).toList();

      // İstemci tarafında mesafeye göre sıralama
      markets.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));

      return markets;
    } catch (e) {
      print('FirestoreMarketRepository error: $e');
      return [];
    }
  }

  @override
  Future<List<Market>> fetchMarketsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Firestore 'whereIn' en fazla 10 eleman kabul eder, bu yüzden parçalıyoruz.
    List<Market> allMarkets = [];

    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);

      try {
        final snapshot = await _firestore
            .collection('markets')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        allMarkets
            .addAll(snapshot.docs.map((doc) => _mapDocumentToMarket(doc)));
      } catch (e) {
        print('Error fetching markets by IDs: $e');
      }
    }
    return allMarkets;
  }

  @override
  Future<List<Market>> fetchAllMarkets() async {
    try {
      final snapshot = await _firestore.collection('markets').get();
      return snapshot.docs.map((doc) => _mapDocumentToMarket(doc)).toList();
    } catch (e) {
      print('Error fetching all markets: $e');
      return [];
    }
  }

  Market _mapDocumentToMarket(DocumentSnapshot doc, {Address? userLocation}) {
    final data = doc.data() as Map<String, dynamic>;
    final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;

    final address = Address(
      latitude: lat,
      longitude: lng,
      street: data['street'] ?? '',
      streetNumber: data['streetNumber'] ?? '',
      neighborhood: data['neighborhood'] ?? '',
      district: data['district'] ?? '',
      city: data['city'] ?? '',
    );

    double dist = 0;
    if (userLocation != null) {
      dist = _haversineDistance(
          userLocation.latitude, userLocation.longitude, lat, lng);
    }

    return Market(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: address,
      distanceInMeters: dist,
      openDays: List<String>.from(data['openDays'] ?? []),
    );
  }

  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * pow(sin(dLon / 2), 2);
    final c = 2 * asin(min(1, sqrt(a)));
    return earthRadius * c;
  }

  double _degToRad(double degree) => degree * pi / 180;
}

/// Loads market data from a JSON asset and returns markets sorted by distance.
class JsonMarketRepository implements MarketRepository {
  final String assetPath;

  JsonMarketRepository({this.assetPath = 'assets/data/markets.json'});

  // Helper to parse all markets without distance calculation
  Future<List<Market>> _loadAllMarkets() async {
    final jsonString = await rootBundle.loadString(assetPath);
    final list = json.decode(jsonString) as List<dynamic>;

    return list.map((e) {
      final id = e['id'] as String? ?? '';
      final name = e['name'] as String? ?? '';
      final description = e['description'] as String? ?? '';
      final lat = (e['latitude'] as num).toDouble();
      final lon = (e['longitude'] as num).toDouble();
      final street = e['street'] as String? ?? '';
      final streetNumber = e['streetNumber'] as String? ?? '';
      final neighborhood = e['neighborhood'] as String? ?? '';
      final district = e['district'] as String? ?? '';
      final city = e['city'] as String? ?? '';
      final openDays = (e['openDays'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toList() ??
          [];

      final address = Address(
        latitude: lat,
        longitude: lon,
        street: street,
        streetNumber: streetNumber,
        neighborhood: neighborhood,
        district: district,
        city: city,
      );

      return Market(
        id: id,
        name: name,
        description: description,
        address: address,
        distanceInMeters: 0, // Distance not calculated here
        openDays: openDays,
      );
    }).toList();
  }

  @override
  Future<List<Market>> fetchNearbyMarkets({required Address forAddress}) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final list = json.decode(jsonString) as List<dynamic>;
      final lat1 = forAddress.latitude;
      final lon1 = forAddress.longitude;

      final markets = list.map((e) {
        final id = e['id'] as String? ?? '';
        final name = e['name'] as String? ?? '';
        final description = e['description'] as String? ?? '';
        final lat = (e['latitude'] as num).toDouble();
        final lon = (e['longitude'] as num).toDouble();
        final street = e['street'] as String? ?? '';
        final streetNumber = e['streetNumber'] as String? ?? '';
        final neighborhood = e['neighborhood'] as String? ?? '';
        final district = e['district'] as String? ?? '';
        final city = e['city'] as String? ?? '';
        final openDays = (e['openDays'] as List<dynamic>?)
                ?.map((d) => d.toString())
                .toList() ??
            [];

        final address = Address(
          latitude: lat,
          longitude: lon,
          street: street,
          streetNumber: streetNumber,
          neighborhood: neighborhood,
          district: district,
          city: city,
        );

        final dist = _haversineDistance(lat1, lon1, lat, lon);

        return Market(
          id: id,
          name: name,
          description: description,
          address: address,
          distanceInMeters: dist,
          openDays: openDays,
        );
      }).toList();

      // Filter markets by province (city) to only those matching requested address city
      final city = forAddress.city;
      String _normalize(String s) {
        var t = s.toLowerCase();
        t = t
            .replaceAll('ş', 's')
            .replaceAll('ı', 'i')
            .replaceAll('ğ', 'g')
            .replaceAll('ü', 'u')
            .replaceAll('ö', 'o')
            .replaceAll('ç', 'c')
            .replaceAll('İ', 'i');
        t = t.replaceAll(RegExp(r'\s+il$'), ''); // strip trailing ' il'
        t = t.replaceAll(RegExp(r'\s+ili$'), ''); // strip trailing ' ili'
        return t;
      }

      final normalizedCity = _normalize(city);
      final filtered = markets
          .where(
            (m) => (m.address.city.isNotEmpty
                ? _normalize(m.address.city) == normalizedCity
                : true),
          )
          .toList();
      print(
        'JsonMarketRepository: requested city="$city", normalized="$normalizedCity"; found ${filtered.length} asset markets matching.',
      );
      if (filtered.isNotEmpty) {
        filtered.sort(
          (a, b) => a.distanceInMeters.compareTo(b.distanceInMeters),
        );
        return filtered;
      }

      // If no market found for this city in the asset, try to generate mock markets for the city
      // Check if the requested city is one of the turkish provinces (normalizing strings)
      final provincesNormalized =
          kTurkishProvinces.map((p) => _normalize(p)).toList();
      final normalizedCityIndex = provincesNormalized.indexOf(normalizedCity);
      if (normalizedCityIndex != -1) {
        final canonicalCity = kTurkishProvinces[normalizedCityIndex];
        print(
          'JsonMarketRepository: generating mock markets for canonicalCity="$canonicalCity"',
        );
        final coords = kProvinceCoords[canonicalCity] ??
            [forAddress.latitude, forAddress.longitude];
        final genMarkets = <Market>[];
        for (var i = 0; i < 2; i++) {
          final lat = coords[0] + (i * 0.005);
          final lon = coords[1] + (i * 0.006);
          genMarkets.add(
            Market(
              id: 'gen_${city}_${i + 1}',
              name: '$city Semt Pazarı ${i + 1}',
              description: '$city belediyesi semt pazarı',
              address: Address(
                latitude: lat,
                longitude: lon,
                street: '',
                streetNumber: '',
                neighborhood: city,
                district: city,
                city: city,
              ),
              distanceInMeters: _haversineDistance(
                forAddress.latitude,
                forAddress.longitude,
                lat,
                lon,
              ),
              openDays: ['Cumartesi'],
            ),
          );
        }
        genMarkets.sort(
          (a, b) => a.distanceInMeters.compareTo(b.distanceInMeters),
        );
        return genMarkets;
      }

      markets.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      return markets;
    } catch (e, st) {
      // Log the error so we can debug
      print('JsonMarketRepository error: $e');
      print(st);
      // Fallback to mock repository data so the app has markets to show
      final fallback = MockMarketRepository();
      final fallbackMarkets = await fallback.fetchNearbyMarkets(
        forAddress: forAddress,
      );
      if (fallbackMarkets.isNotEmpty) {
        print(
          'JsonMarketRepository: falling back to MockMarketRepository with ${fallbackMarkets.length} items',
        );
        return fallbackMarkets;
      }
      // Otherwise return empty
      return [];
    }
  }

  @override
  Future<List<Market>> fetchMarketsByIds(List<String> ids) async {
    try {
      final allMarkets = await _loadAllMarkets();
      return allMarkets.where((m) => ids.contains(m.id)).toList();
    } catch (e) {
      print('JsonMarketRepository fetchMarketsByIds error: $e');
      return [];
    }
  }

  @override
  Future<List<Market>> fetchAllMarkets() async {
    return _loadAllMarkets();
  }

  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * pow(sin(dLon / 2), 2);
    final c = 2 * asin(min(1, sqrt(a)));
    return earthRadius * c;
  }

  double _degToRad(double degree) => degree * pi / 180;
}
