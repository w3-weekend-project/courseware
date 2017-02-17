# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'
require 'pry'

# Include both the migration and the app itself
require './migration'
require './application'

#nancy insert, delete on merge, just for testing
ActiveRecord::Base.logger = Logger.new(STDOUT)

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
# Explorer Player B Step 1 - Associate lessons with readings (both directions).
# When a lesson is destroyed, its readings should be automatically destroyed
# Note:  readings table has a course_id
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
# Explorer Player B Step 2 - Associate lessons with courses (both directions).
# When a course is destroyed, its lessons should be automatically destroyed
# Note:  lessons table has a course_id
#-------------------------------------------------------------
  def test_course_has_table_columns
    new_course = Course.create( name: "Course.1" )
    assert new_course.respond_to?("id?")
    assert new_course.respond_to?("term_id")
  end

  def test_course_has_many_lessons
    new_course = Course.create( name: "Course1" )
    Lesson.create(course_id: new_course.id, name: "Lesson 1")
    Lesson.create(course_id: new_course.id, name: "Lesson 2")
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
#-------------------------------------------------------------
# Explorer Player B Step 3:  Associate courses with course_instructors
# (both directions).
# If the course has any instructors associated with it, the course should
# not be deletable.
# Note:  course_instructors table has a course_id
#-------------------------------------------------------------
def test_course_instructors_has_table_columns
  new_course_instructor = CourseInstructor.create( course_id: 1, instructor_id: 1 )
  assert new_course_instructor.respond_to?("id?")
  assert new_course_instructor.respond_to?("course_id")
end

def test_courses_has_many_course_instructors
  # no instructor table?
  new_course = Course.create(name: "Course")
  CourseInstructor.create( course_id: new_course.id, instructor_id: 500 )
  CourseInstructor.create( course_id: new_course.id, instructor_id: 600 )
  assert new_course.course_instructors.count > 1
end

def test_course_instructor_belongs_to_course
  new_course = Course.create( name: "Course77" )
  new_course_instructor = CourseInstructor.create( course_id: new_course.id, instructor_id: 800 )
  assert new_course_instructor.course
end

def test_cant_delete_course_if_instructor_has_course
  new_course = Course.create( name: "Course88" )
  CourseInstructor.create(course_id: new_course.id, instructor_id: 99)
  assert Course.find(new_course.id)
  new_course.destroy
  assert Course.find(new_course.id)
end

#-------------------------------------------------------------
# Explorer Player B Step 4 - Associate lessons with their in_class_assignments
# (both directions)
# Note:  lessons table has an in_class_assignments_id
#        and a pre_class_assignment_id    scope?
# assignments have a course_id
# lessons have a course_id
#-------------------------------------------------------------
#  Item has_many :users, through: :orders
#  leaving with testing in lessons
#rb Try 'has_many :assignments, :through => :course, :source => <name>'. Is it one of lessons or course_instructors?
#          has_many :assignments, through: :courses
# So testing that if I create a new assignment with course id 100
# and a new lesson that has course id 100
# if I create a in_class_assignment I can
#     get to it from
#   xxx   has_many :y, through:   :z
#   assert x.y
#
def test_lessons_through_courses_get_assignment_and_vice_versa
  new_course = Course.create( name: "Course710" )
  new_assignment = Assignment.create( name: "In Class", course_id: new_course.id)
  new_lesson = Lesson.create(course_id: new_course.id, in_class_assignment_id:  new_assignment.id )
binding.pry
  assert new_lesson.assignments
end

#Try 'has_many :assignments, :through => :course, :source => <name>'. Is it one of lessons or course_instructors?


end # end ApplicationTest < Minitest::Test
