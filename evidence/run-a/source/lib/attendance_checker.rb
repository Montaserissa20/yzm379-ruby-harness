# frozen_string_literal: true

require_relative 'student'

# Öğrencilerin devamsızlık durumunu sınıra göre değerlendirir.
class AttendanceChecker
  ABSENCE_LIMIT = 30.0 # yüzde

  def initialize(limit = ABSENCE_LIMIT)
    @limit = limit
  end

  # Devamsızlık oranı sınırı aşarsa öğrenci kalır (sınırın tam üstü %30 geçerli sayılır).
  def failed?(student)
    student.absence_rate > @limit
  end

  def status(student)
    failed?(student) ? 'DEVAMSIZLIKTAN KALDI' : 'Devam şartını sağlıyor'
  end

  # Bir öğrencinin sınıra ulaşmadan önce kaç saat daha devamsızlık hakkı kaldığını verir.
  def remaining_hours(student)
    max_absent = (student.total_hours * @limit / 100).floor
    [max_absent - student.absent_hours, 0].max
  end

  def failed_students(students)
    students.select { |s| failed?(s) }
  end

  def report(student)
    format('%-8s %-20s %3d/%-3d saat  %%%-6.2f  %s',
           student.number, student.name, student.absent_hours,
           student.total_hours, student.absence_rate, status(student))
  end
end
