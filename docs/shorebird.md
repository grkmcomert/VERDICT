# VERDICT — Codemagic ile internetten kod güncelleme

VERDICT Shorebird hesabında kayıtlı ve `shorebird.yaml`, `pubspec.yaml` içine
asset olarak eklendi. App ID: `7166add0-5cdd-49a6-9eb1-8532dc19776b`.
Bu kimliği değiştirme veya uygulamayı tekrar oluşturma.

Ana akış `codemagic.yaml` dosyasıdır. GitHub Actions kullanmak gerekmez.
Derleme Codemagic'in macOS makinesinde yapılır. İlk Shorebird sürümü yüklenip
cihaz testi yapılana kadar kullanıcılarda OTA aktif değildir.

## Oluşturulan ilk sürüm

Codemagic build 19 çıktısı (`VERDICT_19_artifacts.zip`) kontrol edildi:

- Release: `38.0.0+38` (App Store sürümü `38.0.0`, build `38`).
- Xcode: `26.4.1` / `17E202`; CocoaPods: `1.16.2`.
- Shorebird: `1.6.120`; Flutter: `3.47.2`.
- Kaynak commit: `db3dd6fe7a89d454a9dce75fb9cb82daeeb39e16`.

Bu çıktının `pubspec.lock` ve `ios/Podfile.lock` dosyaları projeye aktarıldı.
Yama hedefinin varsayılanı `38.0.0+38`; Xcode ve CocoaPods bu derlemenin
sürümlerine sabitlendi. Güncellenen dosyalar Codemagic'in kaynak deposuna da
aktarılmalı. İndirilen `shorebird.yaml` projedekiyle aynı; yeniden kurulum yok.
IPA oluşması, TestFlight yüklemesinin veya mağaza yayınının tamamlandığını
tek başına doğrulamaz; App Store Connect üzerinde kontrol et.

## Codemagic'te bir defalık ayar

1. VERDICT uygulamasının ayarlarında **Environment variables** bölümünü aç.
2. Variable name: `SHOREBIRD_TOKEN`; value: Shorebird API anahtarın;
   group: `shorebird`; **Secret / Secure: açık**. Kaydet.
   Aynı grup takımın Global variables and secrets bölümünde de oluşturulabilir.
3. Güncellenen proje dosyalarını Codemagic'in kullandığı kaynak depoya aktar.
   `codemagic.yaml`, `shorebird.yaml`, `pubspec.yaml` ve `tool/` dosyaları birlikte
   bulunmalı. YAML yapılandırmasını kullan; eski görsel Workflow Editor içindeki
   standart Flutter build komutu Shorebird release üretmez.

Mevcut `verdict-ios-release` App Store Connect entegrasyonu ve
`com.grkmcomert.unfollowerscurrent` imzalama ayarları korunmuştur.
API anahtarını kaynak dosyalara yazma.

## İlk sürüm

1. **Start new build** → **VERDICT Shorebird Release - App Store Upload** seç.
2. `build_number`: App Store'a daha önce gönderilenlerden büyük bir tam sayı gir
   (örneğin `38`). Bu alana `38.0.0` yazma; alan derleme sayacıdır.
   Sürüm adı mevcut ayarla `38.0.0` olur. Değiştirmek gerekirse YAML'daki
   `BUILD_NAME` değerini güncelle.
3. `xcode_version` mevcut sürüm için `26.4.1` olarak ayarlı. Derleme sonrasında
   `shorebird-build-info/build.txt` içindeki gerçek Xcode sürümünü kaydet;
   sonraki yamalarda aynı sürümü seç.
4. Akış Shorebird release oluşturur ve imzalı IPA'yı mevcut App Store Connect
   bağlantısıyla TestFlight'a yükler. TestFlight/mağaza dağıtımını tamamla.
5. Build artifacts içindeki `shorebird-build-info/pubspec.lock` ve
   `shorebird-build-info/ios/Podfile.lock` dosyalarını sırasıyla projenin
   `pubspec.lock` ve `ios/Podfile.lock` yollarına geri koyup kaynak depoya kaydet.
   Tam release sürümünü (örneğin `38.0.0+123`) de sakla.

## Sonraki yamalar

1. Herhangi bir Dart dosyasındaki düzeltmeyi yapıp Codemagic'in kaynak deposuna
   aktar. Yama için uygulamanın sürüm/build numarasını artırma.
2. **Start new build** → **VERDICT Shorebird Patch - Internetten Kod Guncelle** seç.
3. Mevcut sürüm için `release_version=38.0.0+38` ve `xcode_version=26.4.1`
   hazır gelir. İleride farklı release'i yamalarken o sürümün değerlerini kullan.
4. İlk kontrol için `dry_run=true` bırak: derler ve uyumluluğu kontrol eder,
   yama yayımlamaz. Yayınlamak için `dry_run=false` seç.
   Bu alan `true` / `false` seçenekli bir listedir. Eski bir build'i yeniden
   denemek yerine güncel kaynakla **Start new build** başlat; eski build eski
   YAML ve betiği kullanabilir. Ön kontrol hedefi, kanalı ve normalize edilmiş
   `dry_run` değerini logda gösterir.
5. `track=staging` test yamasıdır, normal mağaza kullanıcılarına gitmez.
   Gerçek iPhone'da Mac üzerinden
   `shorebird preview --platforms=ios --release-version=38.0.0+38 --track=staging`
   ile test edilebilir. Test edilen kaynak commit'ini sabit tut.
6. Aynı test edilmiş kodu `dry_run=false`, `track=stable` ile çalıştırınca
   kullanıcılara yama gider. Bu workflow App Store'a IPA yüklemez.

Bir yama yalnızca hedef release'e uygulanır. Birden fazla Shorebird release'i
kullanılıyorsa gerekli her release için ayrı yama üret.

## Neler güncellenir?

Uygulamaya bağlı tüm Dart dosyaları: ekranlar, servisler, Instagram istekleri,
JSON işleme, analizler ve Dart içindeki çeviriler. Shorebird tüm uygulamayı
derleyip değişen kodu gönderir; `main.dart` ile sınırlı değildir. Ham kaynak
klasörü telefona gönderilmez, kullanılmayan kod derlemede elenebilir.

Swift/Kotlin, native eklentiler, Flutter motoru, izinler ve gömülü görsel/fontlar
yama kapsamı dışındadır. Native/asset farklarını zorla kabul eden bayraklar
kullanılmaz. Bağımlılık değişikliklerini yeni release olarak ele al.

Release ve patch aynı RevenueCat ayarlarıyla derlenmelidir. Codemagic'teki
`REVENUECAT_IOS_API_KEY` / `REVENUECAT_ANDROID_API_KEY` değişkenleri mevcut `1`
grubundan her iki akışa da alınır. Shorebird anahtarı `shorebird` grubundan alınır.
Bu değerleri o release'in yamaları boyunca değiştirme.

Kullanıcı normal şekilde uygulamayı açar. Updater arka planda yamayı indirir,
sonraki uygulama başlangıcında uygular. Arka plandan öne gelmek her zaman yeni
başlangıç değildir. Çevrimdışı kullanıcı mevcut kodla devam eder.

## Doğrulama durumu

Shorebird API bağlantısı ve uygulama kaydı doğrulandı. API anahtarı proje
dosyalarında bulunmuyor. YAML ve ortak adımlar çözümlendi; kabuk sözdizimi,
release/yama komut argümanları ve hatalı giriş kontrolleri yerelde sahte
derleme araçlarıyla doğrulandı. Codemagic ekranında `SHOREBIRD_TOKEN` değişkeninin
`shorebird` grubuna eklendiği görüldü. Codemagic build 19'un release çıktıları
indirildi ve incelendi. Aktarılan iki kilit dosyasının ZIP ile SHA-256 eşleşmesi
ve gerçek proje üzerinde `38.0.0+38` için yama ön kontrolü doğrulandı.
TestFlight yüklemesi, mağaza yayını ve gerçek iPhone'da yama testi henüz doğrulanmadı.

Kaynaklar:
- https://docs.shorebird.dev/code-push/ci/codemagic/
- https://docs.codemagic.io/yaml-basic-configuration/configuring-environment-variables/
- https://docs.codemagic.io/knowledge-codemagic/build-inputs/
- https://docs.shorebird.dev/code-push/patch/
