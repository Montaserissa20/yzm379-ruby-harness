# Öğrenci Devamsızlık Kontrolü — Model + Harness Deneyi (YZM379)

## 1. Amaç
YZM379 ödevi: **AI Ajanı = Model + Harness**. Aynı model (Claude Sonnet 5.5) ve birebir aynı görev prompt'u iki kez çalıştırıldı:
- **Run A**: harness yok.
- **Run B**: `AGENTS.md`, Minitest, `bin/kontrol` ve otomatik PostToolUse hook'u var.

Görev prompt'u (iki koşuda da aynı):
> Ruby ile öğrenci devamsızlık kontrolü yapan bir uygulama geliştir. Devamsızlık sınırı %30'dur. Kod dosyalarını oluştur.

## 2. Model + Harness
Harness üç katmandan oluşur:
- **Rehber** — `AGENTS.md` (kısa, bağlayıcı proje anayasası).
- **Sensör** — `test/ogrenci_test.rb` (Minitest, sınır değerleri dahil 23 test).
- **Otomatik doğrulama** — `bin/kontrol` + `.claude/settings.json` hook'u.

## 3. Proje yapısı
```
lib/ogrenci.rb               # Ogrenci (Run B'de üretildi)
lib/devamsizlik_kontrol.rb   # DevamsizlikKontrol (Run B'de üretildi)
test/ogrenci_test.rb         # Harness sensörü (Run B'den önce yazıldı)
bin/kontrol                  # Doğrulama komutu
AGENTS.md / CLAUDE.md        # Rehber
.claude/settings.json        # PostToolUse hook
RATCHET_LOG.md               # Hatadan kalıcı koruma günlüğü
evidence/run-a, run-b        # Ham kanıtlar
```

## 4. Gereksinimler
- Ruby 3.4 (`.ruby-version`; denenen sürüm 3.4.7). Yalnızca standart kütüphane ve Minitest. Gem yok.

## 5. Çalıştırma
```
ruby bin/kontrol                 # testleri çalıştırır; 0 = geçti, 2 = başarısız
ruby test/ogrenci_test.rb        # testleri doğrudan çalıştırır
```
```ruby
require_relative "lib/ogrenci"
require_relative "lib/devamsizlik_kontrol"
o = Ogrenci.new(ad: "Ali", durum: :aktif, devamsizlik: 3)
DevamsizlikKontrol.new.degerlendir(o)   # => [:riskli]
```
Not: Run B'nin ürettiği uygulama bir konsol programı (`main.rb`) içermez; yalnızca iki sınıf ve testler vardır.

## 6. AGENTS.md
Ruby 3.4 / yalnızca stdlib+Minitest, `Ogrenci` sözleşmesi (`ad`, `durum`, `devamsizlik` 0–10), `define_method` ile durum sorguları, Hash+lambda kuralları (`:riskli` ≥3, `:kaldi` ≥4, `:telafi_gerekir` ==2), yasaklar (`method_missing`, monkey patch, `eval`) ve "testler geçmeden tamamlandı deme" kuralı. `CLAUDE.md` **gerçek sembolik bağ değildir** (bkz. Sınırlamalar); içeriği `@AGENTS.md`'dir.

## 7. Minitest sensörleri
`test/ogrenci_test.rb`: başlatma, geçerli/geçersiz durumlar, `aktif?/donduruldu?/mezun?`, `respond_to?`, `NoMethodError`, devamsızlık 0/2/3/4/10, negatif, >10, geçersiz tipler ve kural kombinasyonları. Kritik sınır: **3 → riskli ama kalmaz; 4 → riskli ve kaldı; 2 → telafi_gerekir**. Testler yalnızca genel arayüzü kullanır.

## 8. bin/kontrol
Ruby betiği (Windows uyumlu). Minitest'i çalıştırır, hata çıktısını gösterir, başarıda çıkış kodu 0, başarısızlıkta (yükleme hatası dahil) 2 döner. `--hook` modu hook için stdin'deki JSON'dan dosya yolunu okur ve yalnızca `lib/**/*.rb`, `test/**/*.rb`, `main.rb`, `bin/kontrol` değişikliklerinde test çalıştırır. `KONTROL_LOG` ortam değişkeni çıktıyı dosyaya ekler.

## 9. Otomatik hook
`.claude/settings.json`: `PostToolUse`, matcher `Write|Edit|MultiEdit`, komut `bin/kontrol --hook`. Hata durumunda stderr (çıkış kodu 2) Claude'a gösterilir; düzenleme geri alınmaz. Hook **gerçekten çalıştı** (bkz. §11).

## 10. Ratchet
`RATCHET_LOG.md`: Run A'da gözlenen her hata için kalıcı kural/test ve katman kaydı. Gözlenmeyen kurallar ayrı "önleyici" bölümünde.

## 11. A/B Koşusu ve Ölçüm Raporu
Her iki koşu: Claude Sonnet 5.5, Claude Code 2.1.302 (B için doğrulandı), `claude -p` ile ölçüldü.

| Metrik | Run A | Run B | Fark | Değişim |
|---|---|---|---|---|
| Tur | 6 | 10 | +4 | +66,7% |
| Direct input token | 4 | 15 | +11 | +275,0% |
| Cache creation token | 19.689 | 25.708 | +6.019 | +30,6% |
| Cache read token | 45.345 | 378.797 | +333.452 | +735,4% |
| Output token | 3.205 | 2.477 | −728 | −22,7% |
| Maliyet (USD) | 0,1153485 | 0,1655117 | +0,0501632 | +43,5% |
| Süre (duration_ms) | 26.929 | 26.567 | −362 | −1,3% |
| Test sonucu | A'nın kendi 6 testi geçti (kendi API'sini test eder) | Hazır 23 test geçti, `bin/kontrol` çıkış 0 | — | — |
| Ödev uyumu | Hayır (yanlış sınıf/öznitelik, durum, kural yok) | Evet (aşağıda) | — | — |

Yorum: **B bu deneyde daha pahalı ve daha çok turlu çıktı**; yalnızca output token azaldı, süre neredeyse aynı. Harness'in maliyeti düşürdüğü iddia edilmez. Buna karşılık yalnızca B ödevin API ve kurallarını karşıladı. Cache read farkının büyük kısmı daha fazla turdan gelir (her tur bağlamı yeniden okur). Tek koşu olduğu için sonuçlar istatistiksel değildir.

**Harness kurma emeği ayrı bir maliyettir** ve yukarıdaki B ölçümüne dahil değildir; ayrı olarak ölçülmedi (bu oturumun token/maliyet kaydı tutulmadı).

### Gözlenen hatalar ve sonuçlar
- **Run A**: `Student/AttendanceChecker`, saat bazlı yüzde, `durum` yok, `define_method` yok, `riskli/kaldi/telafi_gerekir` yok. Ayrıntı: `evidence/run-a/ANALIZ.md`.
- **Run B**: ilk `lib/ogrenci.rb` yazımında hook `LoadError` (çıkış 2) bildirdi, çünkü `lib/devamsizlik_kontrol.rb` henüz yoktu; ikinci dosya yazılınca hook çıkış 0 verdi. Orijinal B çıktısı düzeltme gerektirmedi: 23/23 test, `bin/kontrol` çıkış 0. Kaynak elle ve grep ile incelendi: `define_method` var, `KURALLAR` donmuş Hash+lambda, `method_missing`/`eval`/monkey patch yok.
- B ajanı, `AGENTS.md` yüzde hesabını yasakladığı için %30'u yüzde olarak uygulamadı ve bunu raporunda belirtti.
- B'de 3 komut izin kuralları nedeniyle reddedildi (`permission_denials`), ardından `ruby bin/kontrol` çalıştı.

## 12. Kanıt konumları
- `evidence/run-a/`: `a-run-2.json`, `a-run-preliminary.json`, `ruby-test-output.txt`, `ANALIZ.md`.
- `evidence/run-b/`: `prompt.txt`, `run-b-stream.jsonl` (ham akış + hook olayları), `run-b-result.json` (akıştaki sonuç satırı, değiştirilmedi), `run-b-transcript.jsonl`, `hook-kontrol.log`, `pre-b-harness/` ve `pre-b-harness.sha256`, `started-at.txt`, `finished-at.txt`.
- `run-b-transcript.jsonl` yayın öncesi e-posta adresi `[EMAIL-REDACTED]` ile maskelenmiştir; başka değişiklik yoktur.

## 13. Sınırlamalar
- **Gerçek symlink yok**: Windows'ta yönetici yetkisi/Developer Mode olmadığından `ln -s AGENTS.md CLAUDE.md` ("Operation not permitted") ve `New-Item -SymbolicLink` ("Administrator privilege required") başarısız. Alternatif: `CLAUDE.md` içinde `@AGENTS.md`.
- Tek koşu A, tek koşu B; varyans ölçülmedi. Ajan çıktısı koşudan koşuya değişebilir.
- A'da kullanılan izin modu JSON'da kayıtlı değil; B `acceptEdits` + `Bash(ruby:*)`/`Write`/`Edit` ile çalıştı. Araç izinleri A ile birebir aynı olmayabilir.
- Test arayüzü (`Ogrenci.new(ad:, durum:, devamsizlik:)`, `degerlendir`, `uygulanir?`) benim tarafımdan seçildi; hocanın verdiği bir arayüz değildir.
- Hash+lambda yapısı, `method_missing` ve monkey patch yasakları testle değil elle/grep ile doğrulandı.
- Windows kullanıcı adı ve yerel yollar kanıt dosyalarında yer alır.

## 14. Yapamadıklarım
- Harness kurma emeğinin token/maliyetini ayrı ölçemedim.
- Birden fazla koşu yapıp ortalama alamadım.
- CLAUDE.md için gerçek bir sembolik bağ oluşturamadım.
- `main.rb` gibi çalıştırılabilir bir konsol arayüzü yok; görev yalnızca kod dosyalarını istiyordu ve B bunu üretmedi.
- Depoyu GitHub'a yayınlayıp herkese açık olduğunu doğrulamadım (onay bekleniyor).
