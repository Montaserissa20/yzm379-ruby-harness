# RATCHET_LOG — Hatadan Kalıcı Korumaya

Kanıt: `evidence/run-a/ANALIZ.md`, `evidence/run-a/ruby-test-output.txt`.
Katmanlar: **Rehber** = `AGENTS.md`, **Sensör** = Minitest (`test/ogrenci_test.rb`), **Hook** = `.claude/settings.json` + `bin/kontrol`.

## 1. Gözlenen Run A hataları (tarihsel)
| Tarih | Gözlenen Run A Hatası | Kalıcı Kural/Test | Harness Katmanı | Doğrulama |
|---|---|---|---|---|
| 2026-11-18 | `Ogrenci`/`DevamsizlikKontrol` yerine `Student`/`AttendanceChecker` kullanıldı | AGENTS.md "Dosyalar"; testler bu sınıfları `require_relative` ile yükler (yoksa LoadError) | Rehber + Sensör + Hook | Run B'de doğru adlar (`Ogrenci`, `DevamsizlikKontrol`) üretildi; hook ilk yazımda LoadError ile uyardı (`evidence/run-b/hook-kontrol.log`) |
| 2026-11-18 | Öznitelikler `ad/durum/devamsizlik` değil | AGENTS.md "Ogrenci sözleşmesi"; `test_olusturma_ozellikleri_okunur` | Rehber + Sensör | Run B: doğru öznitelikler ve doğrulama üretildi, 23/23 test geçti |
| 2026-11-18 | `durum` (3 değer) yok | AGENTS.md; `test_gecerli_durumlar_*`, `test_gecersiz_durum_reddedilir` | Rehber + Sensör | Run B: ilgili testler geçti (23/23) |
| 2026-11-18 | 0–10 sözleşmesi yok | `test_sinir_degerleri_0_ve_10_*`, negatif, >10, tip testleri | Rehber + Sensör | Run B: ilgili testler geçti (23/23) |
| 2026-11-18 | `define_method` ile durum sorguları yok | AGENTS.md; `test_durum_sorgulari`, `test_durum_metotlari_gercekten_tanimli` (`instance_methods(false)`, `respond_to?`) | Rehber + Sensör | Run B: ilgili testler geçti (23/23) |
| 2026-11-18 | Ayrı `:riskli` / `:kaldi` kuralları yok | `test_riskli_esigi_3te_baslar`, `test_kaldi_esigi_4te_baslar` | Rehber + Sensör | Run B: ilgili testler geçti (23/23) |
| 2026-11-18 | Tam 3 devamsızlık riskli sayılmadı (kavram yok) | `test_tam_3_devamsizlik_riskli_ama_kalmaz` | Rehber + Sensör | Run B: ilgili testler geçti (23/23) |
| 2026-11-18 | `:telafi_gerekir` (==2) yok | `test_tam_2_*`, `test_telafi_gerekir_yalnizca_2de_uygulanir` | Rehber + Sensör | Run B: ilgili testler geçti (23/23) |
| 2026-11-18 | Testler gereksinimi ölçmüyordu | Gereksinim bazlı test paketi + `bin/kontrol` zorunluluğu + PostToolUse hook | Sensör + Hook | Gerçek Claude Code hook'u B sırasında çalıştı: 1. yazımda çıkış 2, 2. yazımda 0 (`evidence/run-b/run-b-stream.jsonl`) |
| 2026-11-18 | Hash+lambda kural yapısı yok | AGENTS.md "DevamsizlikKontrol sözleşmesi" (yalnızca Rehber; testle zorlanamaz) | Rehber | Run B'de elle incelendi: `KURALLAR` donmuş Hash + lambda (`lib/devamsizlik_kontrol.rb`); `method_missing`, `eval`, monkey patch yok (grep) |

## 2. Önleyici kurallar (A'da gözlenmedi)
A'da `method_missing` veya monkey patch **kullanılmadı**; aşağıdakiler hata olarak kaydedilmez, yalnızca hoca gereği önleyicidir.
| Kural | Katman | Not |
|---|---|---|
| `method_missing` yasak | Rehber; `test_tanimsiz_metot_no_method_error_verir` dolaylı | Test kaynak taraması yapmaz |
| Monkey patch / `eval` / `instance_eval` yasak | Rehber | Otomatik denetim yok |
| Tamamlandı demeden önce `ruby bin/kontrol` | Rehber + Hook | |

## 3. Run B sonuçları (ölçülen)
- Orijinal B: 23/23 test geçti; `ruby bin/kontrol` bağımsız çalıştırıldı, çıkış kodu 0. Düzeltme gerekmedi.
- Hook gerçekten çalıştı: `PostToolUse:Write` iki kez. İlk çağrı, `lib/devamsizlik_kontrol.rb` henüz yokken `LoadError` ile çıkış 2 verdi; ajan ikinci dosyayı yazdı, ikinci çağrı çıkış 0 verdi.
- Bu ilk hook hatası model hatası değil, iki dosyanın sırayla yazılmasının beklenen sonucudur. Gerçek bir regresyon yakalanmadı; bu yüzden yeni kalıcı test eklenmedi.
- B ajanı yüzde yerine oturum sayısı kullandı ve bunu açıkça belirtti (`AGENTS.md` bağlamı `CLAUDE.md` içindeki `@AGENTS.md` ile yüklendi; ajan dosyayı ayrıca okumadı).
- Gözlem: B'nin 3 komutu (`ruby bin/kontrol; echo ...` ve iki PowerShell çağrısı) izin kuralları nedeniyle reddedildi (`permission_denials`); sonra `ruby bin/kontrol` Bash ile çalıştı. Bu ek turlar B'nin tur sayısına dahildir.

## 4. Harness Notları
- `CLAUDE.md` gerçek sembolik bağ **değildir**: Windows'ta yönetici yetkisi/Developer Mode yok (`ln -s` "Operation not permitted", `New-Item -SymbolicLink` "Administrator privilege required"). Dersteki alternatif uygulandı: içeriği `@AGENTS.md` olan düz dosya.
- Hook yalnızca `lib/**/*.rb`, `test/**/*.rb`, `main.rb`, `bin/kontrol` düzenlemelerinde test çalıştırır; hata çıkış kodu 2 ile stderr'e yazılır. Düzenleme geri alınmaz.
