# frozen_string_literal: true

class DevamsizlikKontrol
  KURALLAR = {
    riskli: ->(ogrenci) { ogrenci.devamsizlik >= 3 },
    kaldi: ->(ogrenci) { ogrenci.devamsizlik >= 4 },
    telafi_gerekir: ->(ogrenci) { ogrenci.devamsizlik == 2 }
  }.freeze

  def degerlendir(ogrenci)
    KURALLAR.keys.select { |kural| uygulanir?(ogrenci, kural) }
  end

  def uygulanir?(ogrenci, kural)
    lambda = KURALLAR.fetch(kural) { raise ArgumentError, "bilinmeyen kural: #{kural.inspect}" }
    lambda.call(ogrenci)
  end
end
