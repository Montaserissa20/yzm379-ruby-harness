# frozen_string_literal: true

# Bir öğrencinin tek bir dersteki devamsızlık bilgisini tutar.
class Student
  attr_reader :number, :name, :total_hours, :absent_hours

  def initialize(number, name, total_hours, absent_hours)
    raise ArgumentError, "Toplam ders saati 0'dan büyük olmalı" unless total_hours.positive?
    raise ArgumentError, 'Devamsızlık saati negatif olamaz' if absent_hours.negative?
    raise ArgumentError, 'Devamsızlık, toplam ders saatini aşamaz' if absent_hours > total_hours

    @number = number
    @name = name
    @total_hours = total_hours
    @absent_hours = absent_hours
  end

  # Devamsızlık yüzdesi (0-100)
  def absence_rate
    (absent_hours.to_f / total_hours * 100).round(2)
  end
end
