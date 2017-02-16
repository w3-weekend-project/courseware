# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'
require 'pry'

# Include both the migration and the app itself
require './migration'
require './application'

# Overwrite the development database connection with a test connection.
ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.sqlite3'
)

 #Gotta run migrations before we can run tests.  Down will fail the first time,
 #so we wrap it in a begin/rescue.
 begin ApplicationMigration.migrate(:down); rescue; end
 ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

  def test_truth
    assert true
  end

  def test_lesson_has_methods

  end
#-------------------------------------------------------------
#Player B - Associate lessons with readings (both directions).
#When a lesson is destroyed, its readings should be automatically destroyed
#-------------------------------------------------------------

def test_lesson_has_table_column_methods
  new_lesson = Lesson.create(course_id: 101, name: "Psych 101", description: "Introduction to Psychology")
  assert  new_lesson.respond_to?("id?")
  refute  new_lesson.respond_to?("count")
end

def test_lesson_has_many_readings
  # if lesson doesn't have a "has_many :readings" you'll get an error on the assert
  # below - NoMethodError: undefined method `reading' for #<Lesson:0x007fa1fe3ae308>    assert Lesson.respond_to?("count")
  new_lesson = Lesson.create(course_id: 101, name: "Psych 101", description: "Introduction to Psychology")
  new_reading1 = Reading.create( lesson_id: new_lesson.id, caption: "Freud Theory", url: "http://www.iep.utm.edu/freud/" )
  new_lesson = Lesson.create(course_id: 101, name: "Psych 101", description: "Introduction to Psychology")
  new_reading1 = Reading.create( lesson_id: new_lesson.id, caption: "Freud Theory", url: "http://www.iep.utm.edu/freud/" )
  assert new_lesson.reading.count > 0
end

def test_reading_belongs_to_lesson
  # if reading doesn't have a "belongs_to lesson" you receive NoMethodError:
  # undefined method `lesson' for #<Reading:0x007ff374c9f198>
  new_lesson = Lesson.create(course_id: 101, name: "Psych 101", description: "Introduction to Psychology")
  new_reading1 = Reading.create( lesson_id: new_lesson.id, caption: "Freud Theory", url: "http://www.iep.utm.edu/freud/" )
  assert new_reading1.lesson
end

def test_delete_lesson_deletes_associated_readings
  new_lesson = Lesson.create(course_id: 101, name: "Psych 101", description: "Introduction to Psychology")
  Reading.create( lesson_id: new_lesson.id, caption: "Freud Theory", url: "http://www.iep.utm.edu/freud/" )
  assert Lesson.find(new_lesson.id)
  new_lesson.destroy
  assert new_lesson.reading.count == 0
  refute Lesson.find_by id: new_lesson.id
end #end test_lesson

#-------------------------------------------------------------
#Player B - Associate lessons with courses (both directions).
# When a course is destroyed, its lessons should be automatically destroyed
#-------------------------------------------------------------
  def test_course_has_table_columns
    new_course = Course.create( name: "Course.1" )
    assert new_course.respond_to?("id?")
    assert new_course.respond_to?("term_id")
  end

  def test_course_has_many_lessons
    new_course = Course.create( name: "Course1" )
    Lesson.create(course_id: new_course.id, name: "Lesson 1")
    Lesson.create(course_id: new_course.id, name: "Lesson 1")
    assert new_course.lessons.count > 1
  end

  def test_lesson_belongs_to_course
    # Fails with message NoMethodError: undefined method `course
    # if this is missing:
    new_course2 = Course.create( name: "Course1" )
    Lesson.create(course_id: new_course2.id, name: "Lesson 1")
    assert new_course2.lessons
  end

  def test_delete_lesson_deletes_associated_courses
    new_course = Course.create( name: "Course1" )
    Lesson.create(course_id: new_course.id, name: "Lesson 1")

    assert Course.find(new_course.id)
    new_course.destroy
    assert new_course.lessons.count == 0
    refute Course.find_by id: new_course.id
  end


end
