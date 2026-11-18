# AGENTS.md — Proje Anayasası

Bu dosya kısa ve bağlayıcıdır. Kurallara uymayan kod teslim edilmez.

## Teknoloji
- Yalnızca **Ruby 3.4** (`.ruby-version`).
- Yalnızca Ruby standart kütüphanesi ve **Minitest**. Harici gem yok.

## Dosyalar
- `lib/ogrenci.rb` → `Ogrenci`
- `lib/devamsizlik_kontrol.rb` → `DevamsizlikKontrol`
- Testler `test/ogrenci_test.rb` içindedir. **Testleri zayıflatma, silme veya atlama.**
- Sınıf, dosya ve sembol adları tam olarak yukarıdaki gibi olmalıdır (İngilizce takma ad yok).

## Ogrenci sözleşmesi
Oluşturma: `Ogrenci.new(ad: "Ali", durum: :aktif, devamsizlik: 3)`
- `ad`: `String`. Değilse `ArgumentError`.
- `durum`: yalnızca `:aktif`, `:donduruldu`, `:mezun`. Başka değer (String dahil) → `ArgumentError`.
- `devamsizlik`: `Integer`, **0..10** (oturum sayısı). Integer değilse (nil, "3", 2.5) veya aralık dışıysa (-1, 11) → `ArgumentError`.
- Okuyucular: `ad`, `durum`, `devamsizlik`.
- `aktif?`, `donduruldu?`, `mezun?` metotları **`define_method` ile açıkça üretilir** (durum listesi üzerinde döngü). Gerçekten tanımlı olmalı: `respond_to?` doğru döner.
- Tanımsız metot çağrısı `NoMethodError` fırlatır.

## DevamsizlikKontrol sözleşmesi
Kurallar okunaklı bir **Hash** içinde, değerleri **lambda** olarak tutulur:

| Kural | Koşul |
|---|---|
| `:riskli` | `devamsizlik >= 3` |
| `:kaldi` | `devamsizlik >= 4` |
| `:telafi_gerekir` | `devamsizlik == 2` (özel kural) |

Sınırlar (kesin):
- 2 → yalnızca `:telafi_gerekir`
- **3 → `:riskli` evet, `:kaldi` HAYIR**
- **4 → `:riskli` ve `:kaldi` ikisi de**
- 0 → hiçbir kural; 10 → `:riskli` ve `:kaldi`

Arayüz:
- `DevamsizlikKontrol.new.degerlendir(ogrenci)` → uygulanan kural sembollerinin `Array`'i (Hash sırasıyla: `:riskli`, `:kaldi`, `:telafi_gerekir`).
- `DevamsizlikKontrol.new.uygulanir?(ogrenci, kural)` → `true/false`; bilinmeyen kural → `ArgumentError`.
- Yüzde hesabı kullanma; kurallar oturum sayısı üzerinden çalışır.

## Yasaklar
- `method_missing` / `respond_to_missing?` **yasak**.
- Standart sınıflara monkey patch (`class String`, `class Integer`, refinements dahil) **yasak**.
- `instance_eval`, `class_eval`, `eval`, gizli DSL ve gereksiz metaprogramlama **yasak**. `define_method` yalnızca durum metotları için.
- Harici gem **yasak**.

## Doğrulama (zorunlu)
Her kod değişikliğinden sonra çalıştır:

```
ruby bin/kontrol
```
- Çıkış kodu `0` = testler geçti, `2` = başarısız.
- Başarısızsa hatayı oku, kodu düzelt, tekrar çalıştır.
- **`ruby bin/kontrol` 0 dönmeden "tamamlandı" deme.** Çalıştırmadığın testi geçti diye raporlama.
