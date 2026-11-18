# frozen_string_literal: true

class Ogrenci
  DURUMLAR = %i[aktif donduruldu mezun].freeze
  DEVAMSIZLIK_ARALIGI = (0..10)

  attr_reader :ad, :durum, :devamsizlik

  def initialize(ad:, durum:, devamsizlik:)
    raise ArgumentError, "ad String olmalı" unless ad.is_a?(String)
    raise ArgumentError, "geçersiz durum: #{durum.inspect}" unless DURUMLAR.include?(durum)
    unless devamsizlik.is_a?(Integer) && DEVAMSIZLIK_ARALIGI.cover?(devamsizlik)
      raise ArgumentError, "devamsizlik 0..10 arasında Integer olmalı: #{devamsizlik.inspect}"
    end

    @ad = ad
    @durum = durum
    @devamsizlik = devamsizlik
  end

  DURUMLAR.each do |durum_adi|
    define_method(:"#{durum_adi}?") { durum == durum_adi }
  end
end
