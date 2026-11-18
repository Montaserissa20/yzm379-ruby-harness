# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/attendance_checker'

class TestAttendance < Minitest::Test
  def setup
    @checker = AttendanceChecker.new
  end

  def test_absence_rate
    assert_equal 25.0, Student.new('1', 'Ali', 40, 10).absence_rate
  end

  def test_below_limit_passes
    refute @checker.failed?(Student.new('1', 'Ali', 40, 10))
  end

  def test_exactly_at_limit_passes
    refute @checker.failed?(Student.new('2', 'Ayşe', 10, 3))
  end

  def test_above_limit_fails
    assert @checker.failed?(Student.new('3', 'Can', 10, 4))
  end

  def test_remaining_hours
    assert_equal 2, @checker.remaining_hours(Student.new('4', 'Deniz', 40, 10))
    assert_equal 0, @checker.remaining_hours(Student.new('5', 'Ece', 10, 5))
  end

  def test_invalid_input
    assert_raises(ArgumentError) { Student.new('6', 'X', 0, 0) }
    assert_raises(ArgumentError) { Student.new('7', 'Y', 10, 11) }
    assert_raises(ArgumentError) { Student.new('8', 'Z', 10, -1) }
  end
end
