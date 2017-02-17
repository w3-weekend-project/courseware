# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'

# Include both the migration and the app itself
require './migration'
require './application'
require_relative 'school'
require_relative 'term'
require_relative 'course'
require_relative 'course_student'
require_relative 'assignment'

# Overwrite the development database connection with a test connection.
ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.sqlite3'
)

# Gotta run migrations before we can run tests.  Down will fail the first time,
# so we wrap it in a begin/rescue.
begin ApplicationMigration.migrate(:down); rescue; end
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

  def test_truth
    assert true
  end

  def test_school_has_terms
    school = School.new
    assert school.respond_to?(:terms)
  end

  def test_term_can_be_added
    school = School.create(name: "TEST")
    Term.create(name: "Fall Term", school_id: school.id)
    assert school.terms.count != 0
  end

  def test_term_has_courses
    term = Term.new
    assert term.respond_to?(:courses)
  end

  def test_course_can_be_added_to_term
    term = Term.create(name: "Fall Term")
    Course.create(name: "Coding 101", term_id: term.id)
    assert term.courses != 0
  end

  def test_term_cannot_be_deleted_with_courses
    term = Term.create(name: "Fall Term")
    Course.create(name: "Coding 101", term_id: term.id)
    refute term.destroy
    assert term.errors.full_messages.include? "Cannot delete record because dependent courses exist"
  end

  def test_course_has_students
    course = Course.create(name: "Class")
    CourseStudent.create(course_id: course.id)
    assert course.course_students != 0
  end

  def test_courses_cannot_be_deleted_with_students_in_them
    course = Course.create(name: "Test Class")
    CourseStudent.create(course_id: course.id)
    refute course.destroy
    assert course.errors.full_messages.include? "Cannot delete record because dependent course students exist"
  end

  def test_courses_has_assignments
    course = Course.create(name:"Test Class")
    Assignment.create(name: "SQL", course_id: course.id)
    assert course.assignments != 0
  end

  def test_assignment_deleted_with_courses
    course = Course.create(name: "Tested Class")
    Assignment.create(name: "Bullshit", course_id: course.id)
    course.destroy
    refute Assignment.exists?(name: "Bullshit")
  end

  def test_lesson_can_have_pre_class_assignments
    hw = Assignment.create(name: "validation")
    lesson = Lesson.create(name: "Validating", pre_class_assignment_id: hw.id)
    assert lesson.pre_class_assignment != 0
  end

  def test_assignment_responds_to_lesson
    assign = Assignment.create(name: "validation")
    lesson = Lesson.create(name: "Ruby", pre_class_assignment_id: assign.id)
    assert_equal "Ruby", assign.lessons.first.name
  end

  def test_school_can_have_many_terms
    tiy = School.create(name: "TIY")
    fall = Term.create(name: "Fall", starts_on: 20160901, ends_on: 20161231, school_id: tiy.id)
    winter = Term.create(name: "Winter", starts_on: 20160101, ends_on: 20160331, school_id: tiy.id)
    ruby = Course.create(name: "Course", term_id: fall.id)
    js = Course.create(name: "JavaScript", term_id: fall.id)
    c = Course.create(name: "C", term_id: winter.id)
    rails = Course.create(name: "Rails", term_id: winter.id)
    assert tiy.terms.count > 1
    assert fall.courses.count > 1
    assert winter.courses.count > 1
  end

  def test_terms_can_have_multiple_courses

  end





end
