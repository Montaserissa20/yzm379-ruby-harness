# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/ogrenci"
require_relative "../lib/devamsizlik_kontrol"

class OgrenciTest < Minitest::Test
  def ogrenci(durum: :aktif, devamsizlik: 0, ad: "Ali")
    Ogrenci.new(ad: ad, durum: durum, devamsizlik: devamsizlik)
  end

  def test_olusturma_ozellikleri_okunur
    o = Ogrenci.new(ad: "Ayse", durum: :mezun, devamsizlik: 5)
    assert_equal "Ayse", o.ad
    assert_equal :mezun, o.durum
    assert_equal 5, o.devamsizlik
  end

  def test_gecerli_durumlar_kabul_edilir
    %i[aktif donduruldu mezun].each do |durum|
      assert_equal durum, ogrenci(durum: durum).durum
    end
  end

  def test_durum_sorgulari
    assert ogrenci(durum: :aktif).aktif?
    refute ogrenci(durum: :aktif).donduruldu?
    refute ogrenci(durum: :aktif).mezun?

    assert ogrenci(durum: :donduruldu).donduruldu?
    refute ogrenci(durum: :donduruldu).aktif?
    refute ogrenci(durum: :donduruldu).mezun?

    assert ogrenci(durum: :mezun).mezun?
    refute ogrenci(durum: :mezun).aktif?
    refute ogrenci(durum: :mezun).donduruldu?
  end

  def test_durum_metotlari_gercekten_tanimli
    o = ogrenci
    %i[aktif? donduruldu? mezun?].each do |metot|
      assert o.respond_to?(metot), "#{metot} tanımlı olmalı"
      assert_includes Ogrenci.instance_methods(false), metot
    end
  end

  def test_tanimsiz_metot_no_method_error_verir
    o = ogrenci
    refute o.respond_to?(:uyuyor?)
    assert_raises(NoMethodError) { o.uyuyor? }
    assert_raises(NoMethodError) { o.kayboldu? }
  end

  def test_gecersiz_durum_reddedilir
    [:bilinmeyen, "aktif", nil, 1].each do |durum|
      assert_raises(ArgumentError, "durum #{durum.inspect} reddedilmeli") do
        ogrenci(durum: durum)
      end
    end
  end

  def test_gecersiz_ad_reddedilir
    [nil, :ali, 42].each do |ad|
      assert_raises(ArgumentError) { ogrenci(ad: ad) }
    end
  end

  def test_sinir_degerleri_0_ve_10_kabul_edilir
    assert_equal 0, ogrenci(devamsizlik: 0).devamsizlik
    assert_equal 10, ogrenci(devamsizlik: 10).devamsizlik
  end

  def test_negatif_devamsizlik_reddedilir
    assert_raises(ArgumentError) { ogrenci(devamsizlik: -1) }
  end

  def test_10dan_fazla_devamsizlik_reddedilir
    assert_raises(ArgumentError) { ogrenci(devamsizlik: 11) }
  end

  def test_gecersiz_devamsizlik_tipi_reddedilir
    [nil, "3", 2.5, 3.0, :uc, [3]].each do |deger|
      assert_raises(ArgumentError, "devamsizlik #{deger.inspect} reddedilmeli") do
        ogrenci(devamsizlik: deger)
      end
    end
  end
end

class DevamsizlikKontrolTest < Minitest::Test
  def setup
    @kontrol = DevamsizlikKontrol.new
  end

  def kurallar(devamsizlik)
    @kontrol.degerlendir(Ogrenci.new(ad: "Ali", durum: :aktif, devamsizlik: devamsizlik)).sort
  end

  def ogrenci(devamsizlik)
    Ogrenci.new(ad: "Ali", durum: :aktif, devamsizlik: devamsizlik)
  end

  def test_0_devamsizlikta_hicbir_kural_uygulanmaz
    assert_equal [], kurallar(0)
  end

  def test_1_devamsizlikta_hicbir_kural_uygulanmaz
    assert_equal [], kurallar(1)
  end

  def test_tam_2_devamsizlikta_yalnizca_telafi_gerekir
    assert_equal [:telafi_gerekir], kurallar(2)
  end

  def test_tam_3_devamsizlik_riskli_ama_kalmaz
    assert_equal [:riskli], kurallar(3)
    assert @kontrol.uygulanir?(ogrenci(3), :riskli)
    refute @kontrol.uygulanir?(ogrenci(3), :kaldi)
    refute @kontrol.uygulanir?(ogrenci(3), :telafi_gerekir)
  end

  def test_tam_4_devamsizlik_hem_riskli_hem_kaldi
    assert_equal %i[kaldi riskli], kurallar(4)
    assert @kontrol.uygulanir?(ogrenci(4), :riskli)
    assert @kontrol.uygulanir?(ogrenci(4), :kaldi)
    refute @kontrol.uygulanir?(ogrenci(4), :telafi_gerekir)
  end

  def test_10_devamsizlikta_riskli_ve_kaldi
    assert_equal %i[kaldi riskli], kurallar(10)
  end

  def test_telafi_gerekir_yalnizca_2de_uygulanir
    (0..10).each do |d|
      assert_equal (d == 2), @kontrol.uygulanir?(ogrenci(d), :telafi_gerekir), "devamsizlik=#{d}"
    end
  end

  def test_riskli_esigi_3te_baslar
    (0..10).each do |d|
      assert_equal (d >= 3), @kontrol.uygulanir?(ogrenci(d), :riskli), "devamsizlik=#{d}"
    end
  end

  def test_kaldi_esigi_4te_baslar
    (0..10).each do |d|
      assert_equal (d >= 4), @kontrol.uygulanir?(ogrenci(d), :kaldi), "devamsizlik=#{d}"
    end
  end

  def test_degerlendir_dizi_dondurur
    assert_kind_of Array, @kontrol.degerlendir(ogrenci(4))
  end

  def test_bilinmeyen_kural_reddedilir
    assert_raises(ArgumentError) { @kontrol.uygulanir?(ogrenci(3), :yok_boyle_kural) }
  end

  def test_durumdan_bagimsiz_calisir
    %i[aktif donduruldu mezun].each do |durum|
      o = Ogrenci.new(ad: "Ali", durum: durum, devamsizlik: 3)
      assert_equal [:riskli], @kontrol.degerlendir(o)
    end
  end
end
