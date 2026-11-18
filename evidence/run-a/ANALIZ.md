# Run A (baseline-2) Analizi

Kaynak: `../baseline-2/` (değiştirilmedi), `a-run-2.json` (kopyası bu klasörde). Test çıktısı: `ruby-test-output.txt` (Ruby 3.4.7, gerçek çalıştırma, 2026-11-18).
`a-run.json` (ilk deneme, `baseline/`) yalnızca ön kanıttır: `a-run-preliminary.json`.

## Ölçümler (JSON'dan)
| Metrik | Değer |
|---|---|
| Model | claude-sonnet-5-5 |
| Tur (num_turns) | 6 |
| Maliyet (total_cost_usd) | 0.1153485 |
| Output token | 3205 |
| Direct input token | 4 |
| Cache creation token | 19689 |
| Cache read token | 45345 |
| duration_ms | 26929 |

## Doğrulanmış bulgular
**Onaylanmış uygulama hataları / eksik gereksinimler**
1. Sınıf/dosya adları yanlış: `Student`, `AttendanceChecker` (`lib/student.rb`, `lib/attendance_checker.rb`); beklenen `Ogrenci`, `DevamsizlikKontrol`.
2. Öznitelikler uyumsuz: `number, name, total_hours, absent_hours`; beklenen `ad, durum, devamsizlik`.
3. `durum` (`:aktif/:donduruldu/:mezun`) hiç yok.
4. 0–10 oturum sözleşmesi yok; devamsızlık saat bazlı, üst sınırı toplam saat.
5. `define_method` kullanılmamış; `aktif?/donduruldu?/mezun?` yok.
6. Ayrı `:riskli` ve `:kaldi` kuralları yok; yalnızca `failed?` (yüzde > 30).
7. Tam 3 devamsızlığın `:riskli` olması yok (3/10 saat "geçiyor" ama risk kavramı yok).
8. Özel kural `:telafi_gerekir` (==2) yok.
9. Kurallar Hash+lambda ile tutulmamış.
10. Testler gereksinimi doğrulamıyor: 6 test yalnızca kendi `Student/AttendanceChecker` API'sini ölçer.

**Doğru davranış**
- `method_missing` ve monkey patch yok.
- Kod Ruby 3.4.7 altında çalışıyor; 6 test, 0 hata (bağımsız doğrulandı).
- `>%30` eşiği tek başına hata sayılmaz: 10 saatte 4 saat gerçekten `kaldi` ile aynı sonucu verir; sorun eşik değil, kuralların hiç modellenmemesi.

**Doğrulanmamış kaygılar**
- Oturum başına 10 toplam saat varsayımı gerçek kullanımda geçerli mi, belirsiz.
- Tanımsız metotlarda `NoMethodError` Ruby'nin varsayılan davranışıdır; kasıtlı bir tasarım kanıtı yok.
- Claude'un "6 test geçti" iddiası doğrulandı ama gereksinim karşılandığını göstermez.
