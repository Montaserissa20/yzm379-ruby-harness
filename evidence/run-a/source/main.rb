# frozen_string_literal: true

require_relative 'lib/attendance_checker'

checker = AttendanceChecker.new
students = []

def ask(prompt)
  print prompt
  $stdin.gets&.strip
end

def ask_int(prompt)
  Integer(ask(prompt))
rescue ArgumentError, TypeError
  puts 'Lütfen geçerli bir tam sayı girin.'
  retry
end

loop do
  puts "\n=== Öğrenci Devamsızlık Kontrolü (Sınır: %#{AttendanceChecker::ABSENCE_LIMIT.to_i}) ==="
  puts '1) Öğrenci ekle'
  puts '2) Tüm öğrencileri listele'
  puts '3) Devamsızlıktan kalanları listele'
  puts '4) Çıkış'

  case ask('Seçiminiz: ')
  when '1'
    number = ask('Öğrenci no: ')
    name = ask('Ad Soyad: ')
    total = ask_int('Toplam ders saati: ')
    absent = ask_int('Devamsızlık saati: ')
    begin
      student = Student.new(number, name, total, absent)
      students << student
      puts checker.report(student)
      puts "Kalan devamsızlık hakkı: #{checker.remaining_hours(student)} saat" unless checker.failed?(student)
    rescue ArgumentError => e
      puts "Hata: #{e.message}"
    end
  when '2'
    puts students.empty? ? 'Kayıtlı öğrenci yok.' : students.map { |s| checker.report(s) }
  when '3'
    failed = checker.failed_students(students)
    puts failed.empty? ? 'Devamsızlıktan kalan öğrenci yok.' : failed.map { |s| checker.report(s) }
  when '4', nil
    puts 'Çıkılıyor.'
    break
  else
    puts 'Geçersiz seçim.'
  end
end
