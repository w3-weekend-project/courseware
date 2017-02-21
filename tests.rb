# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'
require 'pry'

# Include both the migration and the app itself
require './migration'
require './application'
require_relative 'school'
require_relative 'term'
require_relative 'course'
require_relative 'course_student'
require_relative 'assignment'

#nancy insert, delete on merge, just for testing
#ActiveRecord::Base.logger = Logger.new(STDOUT)

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

  def test_school_has_terms
    school = School.new
    assert school.respond_to?(:terms)
  end


#Nancy note, added required fields to terms
# #name: , starts_on: , ends_on: , school_id:
# so added the starts_on and end on dates


  def test_term_can_be_added_to_school
    school = School.create(name: "PHS")
    Term.create(name: "Fall Term", starts_on: 20160901, ends_on: 20161231, school_id: school.id)
    assert school.terms.count != 0
  end

  def test_term_has_courses
    term = Term.new
    assert term.respond_to?(:courses)
  end

  def test_course_can_be_added_to_term
    term = Term.create(name: "Fall Term", starts_on: 20160902, ends_on: 20161201)
    Course.create(name: "Coding 101", term_id: term.id)
    assert term.courses != 0
  end

  def test_term_cannot_be_deleted_with_courses
    tiy = School.create(name: "The Iron-Yard")
    term = Term.create(name: "Fall Term", school_id: tiy.id, starts_on: 20160903, ends_on: 20161202)
    Course.create(name: "Coding 101", term_id: term.id, course_code: "ABC123")
    refute term.destroy
    assert term.errors.full_messages.include? "Cannot delete record because dependent courses exist"
  end

  def test_course_has_students
    course = Course.create(name: "Financial Math", course_code: "MAT373")
    CourseStudent.create(course_id: course.id)
    assert course.course_students != 0
  end

  def test_courses_cannot_be_deleted_with_students_in_them
    course = Course.create(name: "Time Series", course_code: "MAT420")
    CourseStudent.create(course_id: course.id)
    refute course.destroy
    assert course.errors.full_messages.include? "Cannot delete record because dependent course students exist"
  end

  def test_courses_has_assignments
    course = Course.create(name:"Linear Regression Analysis", course_code: "MAT512")
    Assignment.create(name: "SQL", course_id: course.id, percent_of_grade: 0.40)
    assert course.assignments != 0
  end

  def test_assignment_deleted_with_courses
    tc = Course.create(name: "Linear Algebra", course_code: "MAT351")
    bs = Assignment.create(name: "Matrix Multiplication", course_id: tc.id, percent_of_grade: 0.15)
    tc.destroy
    refute Assignment.exists?(id: bs.id)
  end

  def test_lesson_can_have_pre_class_assignments
    valid = Course.create(name: "Validating stuff", course_code: "VAL111")
    hw = Assignment.create(name: "validation", course_id: valid.id, percent_of_grade: 0.20)
    val = Lesson.create(name: "Validating", pre_class_assignment_id: hw.id)
    assert val.pre_class_assignment != 0
  end

  def test_assignment_responds_to_lesson
    ry = Course.create(name: "Ruby stuff", course_code: "RBY666")
    assign = Assignment.create(name: "validation", course_id: ry.id, percent_of_grade: 0.25)
    rb = Lesson.create(name: "Ruby", pre_class_assignment_id: assign.id)
    assert Lesson.find_by(id: rb.id)
  end

  def test_school_can_have_many_courses_through_terms
    tiy = School.create(name: "TIY")
    fall = Term.create(name: "Fall", starts_on: 20160901, ends_on: 20161231, school_id: tiy.id)
    winter = Term.create(name: "Winter", starts_on: 20160101, ends_on: 20160331, school_id: tiy.id)
    ruby = Course.create(name: "Course", term_id: fall.id, course_code: "CAD202")
    js = Course.create(name: "JavaScript", term_id: fall.id, course_code: "FEE192")
    c = Course.create(name: "C", term_id: winter.id, course_code: "CEE104")
    rails = Course.create(name: "Rails", term_id: winter.id, course_code: "BEE837")
    assert tiy.terms.count > 1
    assert tiy.courses.count > 1
    assert_equal "TIY", rails.schools.first.name
  end

  def test_school_name_is_required
    school = School.new
    refute school.save
    assert school.errors.full_messages.include? "Name can't be blank"
  end

  def test_lessons_name_is_required
    l = Lesson.new
    refute l.save
    assert l.errors.full_messages.include? "Name can't be blank"
  end

  def test_reading_requires_stuff
    read = Reading.new
    refute read.save
    assert read.errors.full_messages.include? "Order number can't be blank"
  end

  def test_reading_url_starts_with_http
    read = Reading.new(url: "www.google.com")
    refute read.save
    assert read.errors.full_messages.include? "Url is invalid"
  end

  def test_course_requires_code_and_name
    course = Course.new
    refute course.save
    assert course.errors.full_messages.include? "Name can't be blank"
    assert course.errors.full_messages.include? "Course code can't be blank"

  end

  def test_course_code_is_unique_in_term
    tiy = School.create(name: "TIY")
    fall = Term.create(name: "Fall", starts_on: 20160901, ends_on: 20161231, school_id: tiy.id)
    ruby = Course.create(name: "Course", term_id: fall.id, course_code: "FEE101")
    assert ruby.persisted?
    js = Course.create(name: "JavaScript", term_id: fall.id, course_code: "FEE101")
    refute js.persisted?
  end

  def test_course_code_has_letters_and_numbers
    wrigley = School.create(name: "Wrigley Field")
    spring = Term.create(name: "Spring", starts_on: 20160301, ends_on: 20160501, school_id: wrigley.id)
    cubs = Course.create(name: "Baseball", term_id: spring.id)
    refute cubs.persisted?
    assert cubs.errors.full_messages.include? "Course code can't be blank"
  end

  def test_course_instructors_are_instructors_which_are_users
    phil = User.create(first_name: "Phil", last_name: "Nye", email: "philnye@science.edu")
    science = CourseInstructor.create(instructor_id: phil.id)
    assert science.instructor_id == phil.id
  end

  def test_assignments_have_grades
    hw2 = Assignment.new
    assert hw2.respond_to?(:assignment_grades)
  end

  def test_assignment_grades_are_associated_with_assignments
    mutant = Course.create(name: "X-men Origins", course_code: "XMN123")
    hw3 = Assignment.create(name: "Creating Weapon X", course_id: mutant.id, percent_of_grade: 0.90)
    hw3_grade = AssignmentGrade.create(assignment_id: hw3.id)
    assert hw3.id == hw3_grade.assignment_id
  end

  def test_courses_can_have_many_instructors
    science = Course.create(name: "Advanced Science Methodology For The Smart Kids", course_code: "SCI420")
    nye = User.create(first_name: "Phil", last_name: "Adelphia", email: "philadelphia@edu.edu")
    sci = User.create(first_name: "Phil", last_name: "Lanthropy", email: "philanthropy@charity.com")
    CourseInstructor.create(course_id: science.id, instructor_id: nye.id)
    CourseInstructor.create(course_id: science.id, instructor_id: sci.id)
    assert science.course_instructors.length > 1
  end

  def test_assignment_due_at_date_is_not_before_active_at_date
    muggle = Course.create(name: "Killing muggles for beginners", course_code: "MUG333")
    homework = Assignment.create(name: "First assassination", course_id: muggle.id, percent_of_grade: 0.50, due_at: 20160101, active_at: 20160101)
    take_home = Assignment.create(name: "Kidnapping babies", course_id: muggle.id, percent_of_grade: 0.49, due_at: 20160304, active_at: 20160306)
    refute homework.persisted?
    refute take_home.persisted?
    assert homework.errors.full_messages.include? "Due at must be after active date"
    assert take_home.errors.full_messages.include? "Due at must be after active date"
  end

  def test_that_assignments_are_ordered_correctly
    trump = Course.create(name: "How to destroy a country", course_code: "USA420")
    win = Assignment.create(name: "Win an election with Russia's help", course_id: trump.id, percent_of_grade: 0.25, due_at: 20161108, active_at: 20160101)
    swamp = Assignment.create(name: "Fill entire cabinet with CEO's", course_id: trump.id, percent_of_grade: 0.25, due_at: 20170120, active_at: 20160101)
    news = Assignment.create(name: "Denouncing all free press as fake news", course_id: trump.id, percent_of_grade: 0.25, due_at: 20161108, active_at: 20160501)
    assert trump.assignments.first == win
    assert trump.assignments.second == news
    assert trump.assignments.last == swamp
  end



#Start of Nancy's code
#-------------------------------------------------------------
# Explorer Player B Step 1 - Associate lessons with readings (both directions).
# When a lesson is destroyed, its readings should be automatically destroyed
# Note:  readings table has a course_id
#-------------------------------------------------------------

def test_lesson_has_table_column_methods
  new_lesson = Lesson.create!(course_id: 101, name: "Psych 101", description: "Introduction to Psychology")
  assert  new_lesson.respond_to?("id?")
  assert  Lesson.find_by(name: new_lesson.name)
  refute  new_lesson.respond_to?("count")
  new_lesson.destroy
end

def test_lesson_has_many_readings
  # if lesson doesn't have a "has_many :readings" you'll get an error on the assert
  # below - NoMethodError: undefined method `reading' for #<Lesson:0x007fa1fe3ae308>    assert Lesson.respond_to?("count")
  new_lesson = Lesson.create!(course_id: 101, name: "Psych 101", description: "Introduction to Psychology")
  new_reading1 = Reading.create!(order_number: 1, lesson_id: new_lesson.id, caption: "Freud Theory", url: "http://www.iep.utm.edu/freud/" )
  new_reading2 = Reading.create!(order_number: 2, lesson_id: new_lesson.id, caption: "Jung", url: "http://www.iep.utm.edu/freud/" )
  assert new_lesson.readings.count == 2
  assert new_lesson.readings.first == new_reading1
  new_lesson.destroy
  new_reading1.destroy
  new_reading2.destroy
end

def test_reading_belongs_to_lesson
  # if reading doesn't have a "belongs_to lesson" you receive NoMethodError:
  # undefined method `lesson' for #<Reading:0x007ff374c9f198>
  new_lesson = Lesson.create!(course_id: 101, name: "Psych 101", description: "Introduction to Psychology")
  new_reading = Reading.create!(order_number: 1, lesson_id: new_lesson.id, caption: "Freud Theory", url: "http://www.iep.utm.edu/freud/" )
  assert new_reading.lesson
  new_lesson.destroy
  new_reading.destroy
end

def test_delete_lesson_deletes_associated_readings
  new_lesson = Lesson.create!(course_id: 101, name: "Psych 101", description: "Introduction to Psychology")
  Reading.create!(order_number: 1, lesson_id: new_lesson.id, caption: "Freud Theory", url: "http://www.iep.utm.edu/freud/" )
  assert Lesson.find(new_lesson.id)
  new_lesson.destroy
  assert new_lesson.readings.count == 0
  refute Lesson.find_by id: new_lesson.id
  new_lesson.destroy
end #end test_lesson

#-------------------------------------------------------------
# Explorer Player B Step 2 - Associate lessons with courses (both directions).
# When a course is destroyed, its lessons should be automatically destroyed
# Note:  lessons table has a course_id
#-------------------------------------------------------------
  def test_course_has_table_columns
    new_course = Course.create!(name: "Course B21", course_code: "BBB021" )
    assert new_course.respond_to?("id?")
    assert new_course.respond_to?("term_id")
    new_course.destroy
  end

  def test_course_has_many_lessons
    new_course = Course.create!( name: "Course1", course_code: "COO100" )
    l1 = Lesson.create!(course_id: new_course.id, name: "Lesson 1")
    l2 = Lesson.create!(course_id: new_course.id, name: "Lesson 2")
    assert new_course.lessons.count == 2
    new_course.destroy
  end

  def test_lesson_belongs_to_course
    # Fails with message NoMethodError: undefined method `course
    # if this is missing:
    new_course2 = Course.create!(name: "Course B23", course_code: "BBB023" )
    le = Lesson.create!(course_id: new_course2.id, name: "Lesson 1")
    assert new_course2.lessons.first == le
    new_course2.destroy
  end

  def test_delete_lesson_deletes_associated_courses
    new_course = Course.create!( name: "Course B24", course_code: "BBB024" )
    less = Lesson.create!(course_id: new_course.id, name: "Lesson B24")
    assert new_course.destroy
    refute Course.exists?(name: new_course.name)
    refute Lesson.exists?(name: less.name)
    new_course.destroy
  end

#-------------------------------------------------------------
# Explorer Player B Step 3:  Associate courses with course_instructors
# (both directions).
# If the course has any instructors associated with it, the course should
# not be deletable.
# Note:  course_instructors table has a course_id
#-------------------------------------------------------------
def test_course_instructors_has_table_columns
  new_course_instructor = CourseInstructor.create!( course_id: 1, instructor_id: 1 )
  assert new_course_instructor.respond_to?("id?")
  assert new_course_instructor.respond_to?("course_id")
  new_course_instructor.destroy
end

def test_courses_has_many_course_instructors
  # no instructor table?
  new_course = Course.create!(name: "Course", course_code: "COO101")
  CourseInstructor.create!( course_id: new_course.id, instructor_id: 500 )
  CourseInstructor.create!( course_id: new_course.id, instructor_id: 600 )
  assert new_course.course_instructors.count > 1
  new_course.destroy
end

def test_course_instructor_belongs_to_course
  new_course = Course.create!( name: "Course77", course_code: "COO770" )
  new_course_instructor = CourseInstructor.create!( course_id: new_course.id, instructor_id: 800 )
  assert new_course_instructor.course
    new_course.destroy
    new_course_instructor.destroy
end

def test_cant_delete_course_if_instructor_has_course
  new_course = Course.create!( name: "Course88", course_code: "COO808" )
  CourseInstructor.create!(course_id: new_course.id, instructor_id: 99)
  assert Course.find(new_course.id)
  new_course.destroy     # keep this, it is part of test, other destroys can be cleaned up refractor
  assert Course.find(new_course.id)
end

#-------------------------------------------------------------
# Explorer Player B Step 4 - Associate lessons with their in_class_assignments
# (both directions)
# Note:  lessons table has an in_class_assignments_id
#        and a pre_class_assignment_id.  Both are foreign key relationships
#        with a non-standard name
#
# Web Example:
# belongs_to :author, class_name: "Patron",
#                        foreign_key: "patron_id"
#-------------------------------------------------------------

def test_lessons_foreign_key_in_class_assignment
  new_course = Course.create!(name: "CourseB4", course_code: "BBB004")
  new_assignment = Assignment.create!( name: "Assignment Blach", course_id: new_course.id, percent_of_grade: 80.5)
  new_lesson = Lesson.create!(in_class_assignment_id:  new_assignment.id, name: "New Lesson" )
  assert new_lesson.in_class_assignment
  new_course.destroy
  new_lesson.destroy
  new_assignment.destroy
end

#------------------------------------------------------------
# Explorer Player B Step 5 - Set up a Course to have many readings
# through the Course's lessons

 def test_course_has_many_readings_through_lessons
   new_course = Course.create!( name: "CourseB5", course_code: "BBB005" )
   new_lesson = Lesson.create!( course_id: new_course.id, name: "lesson5" )
   Reading.create!( order_number: 5, lesson_id: new_lesson.id, url: "https://www.theironyard.com" )
   assert new_course.readings
   new_course.destroy
   new_lesson.destroy
 end

 #------------------------------------------------------------
  # Explorer Player B Step 6 - Validate that Schools must have names
  #    Kendrick already did this above

  def test_school_name_is_required
    school = School.new
    refute school.save
    assert school.errors.full_messages.include? "Name can't be blank"
  end

 #------------------------------------------------------------
 # Explorer Player B Step 7 - Validate that Terms must have name,
 # starts_on, ends_on, and school_id.
 #------------------------------------------------------------
 def test_terms_require_name_startson_endson_schoolid
   new_term = Term.new
   refute new_term.save
   assert new_term.errors.full_messages.include? "Name can't be blank"
   assert new_term.errors.full_messages.include? "Starts on can't be blank"
   assert new_term.errors.full_messages.include? "Ends on can't be blank"
   assert new_term.errors.full_messages.include? "School can't be blank"
   new_term.destroy
 end

 #------------------------------------------------------------
 # Explorer Player B Step 8 - Validate that the User has a first_name,
 # a last_name, and an email.
 #------------------------------------------------------------
 def test_users_require_firstname_lastname_email
   new_user = User.new
   refute new_user.save
   assert new_user.errors.full_messages.include? "First name can't be blank"
   assert new_user.errors.full_messages.include? "Last name can't be blank"
   assert new_user.errors.full_messages.include? "Email can't be blank"
   new_user.destroy
 end

 #------------------------------------------------------------
 # Explorer Player B Step 9 - Validate that the User's email is unique.
  def test_user_email_is_unique
    new_user = User.new(first_name: "Izzy", last_name: "Belly", email: "izzy@gmail.com")
    if new_user.save == false
       #that is ok, test just happened to supply an existing email
    end
    new_user = User.new(first_name: "Leo", last_name: "Nardo", email: "izzy@gmail.com")
    refute new_user.save
    new_user.destroy
  end

 #------------------------------------------------------------
 # Explorer Player B Step 10 - Validate that the User's email has the
 # appropriate form for an e-mail address. Use a regular expression.
 #------------------------------------------------------------
  def test_user_email_proper_format
    new_user = User.new(first_name: "Itty", last_name: "Bitty", email: "@hot@")
    refute new_user.save
    new_user.destroy
  end

 #------------------------------------------------------------
 # Explorer Player B Step 11 - Validate that the User's photo_url
 # must start with http:// or https://. Use a regular expression.
 #------------------------------------------------------------
  def test_user_photo_url_starts_with_http_or_https
    new_user = User.new(first_name: "Leo", last_name: "Pold", email: "kitty@gmail.com", photo_url: ".org")
    refute new_user.save
    new_user = User.new(first_name: "Leo", last_name: "Pold", email: "kitty@gmail.com", photo_url: "https://pinboard.in")
    assert new_user.save
    new_user.destroy
  end
  #------------------------------------------------------------
  # Explorer Player B Step 12	Validate that Assignments have
  # a course_id, name, and percent_of_grade.
  #------------------------------------------------------------
  def test_assignments_require_courseid_name_percentofgrade
    new_assignment = Assignment.new
    refute new_assignment.save
    assert new_assignment.errors.full_messages.include? "Course can't be blank"
    assert new_assignment.errors.full_messages.include? "Name can't be blank"
    assert new_assignment.errors.full_messages.include? "Percent of grade can't be blank"
    new_assignment.destroy
  end

  #------------------------------------------------------------
  # Explorer Player B Step 13 - Validate that the Assignment name
  # is unique within a given course_id.
  #------------------------------------------------------------
  def test_assignment_unique_for_course
    new_course = Course.create!(name: "Course E-B-13", course_code: "EPB013")
    new_assignment = Assignment.new
    new_assignment.name = "Explorer E-B-13"
    new_assignment.course_id = new_course.id
    new_assignment.percent_of_grade = 10.00
    new_assignment.save
    assert new_assignment.persisted?
    new_assignment = Assignment.create(name: "Explorer E-B-13", course_id: new_course.id, percent_of_grade: 15.00)
    refute new_assignment.persisted?
    new_course.destroy
    new_assignment.destroy
  end

  #------------------------------------------------------------
  # Adventure Player B Step 1 - Associate CourseStudents with students
  # (who happen to be users)
  #
  # The course_students table is a join table between student and course (therefore
  # the table has a student_id and a course_id).  It can answer what courses a student
  # is taking and which students are taking a given course.
  #
  # The first assert tests that in CourseStudent we've defined that the foreign key
  # student_id is the way to access the user table
  # The second assert tests that in User we've defined that we can get the course_ids
  # that student is taking
  #------------------------------------------------------------
  def test_student_id_in_courses_is_foreign_key_to_users

    new_student = User.create!(first_name: "Izzy", last_name: "Bella", email: "izzybella@gmail.com")
    new_course1 = Course.create!(name: "CourseAB101", course_code: "CAB101")
    new_course2 = Course.create!(name: "CourseAB102", course_code: "CAB102")
    new_course_student = CourseStudent.create!(student_id: new_student.id, course_id: new_course1.id)
    new_course_student = CourseStudent.create!(student_id: new_student.id, course_id: new_course2.id)
    assert new_course_student.students
    assert new_student.courses
    new_student.destroy
    new_course1.destroy
    new_course2.destroy
    new_course_student.destroy
  end

  #------------------------------------------------------------
  # Adventure Player B Step 2 - Associate CourseStudents with
  # assignment_grades (both directions)
  #-------------------------------------------------------------
  def test_AssignmentGrade_has_foreign_key_to_CourseStudent
    new_course1 = Course.create!(name: "Course 1", course_code: "ABZ002")
    new_assignment1 = Assignment.create!(name: "Course1 Assignment 1", course_id: new_course1.id, percent_of_grade: 50.00)
    new_student1 = User.create!(first_name: "Izzy", last_name: "Bella", email: "izzybella@gmail.com")
    new_course_student1 = CourseStudent.create!(student_id: new_student1.id, course_id: new_course1.id)
    new_assignment_grade1 = AssignmentGrade.create!(assignment_id: new_assignment1.id, course_student_id: new_course_student1.id)
    assert new_assignment_grade1.course_student
    assert new_course_student1.assignment_grades
    new_course1.destroy
    new_assignment1.destroy
    new_student1.destroy
    new_course_student1.destroy
    new_assignment_grade1.destroy
  end

  #------------------------------------------------------------
  # Adventure Player B Step 3 - Set up a Course to have many students
  # through the course's course_students.
  #-------------------------------------------------------------
  def test_Course_has_many_students_through_CourseStudent
    new_course = Course.create!(name: "Course 1", course_code: "CAB003")
    new_student1 = User.create!(first_name: "Izzy", last_name: "Bella", email: "izzybella@gmail.com")
    new_student2 = User.create!(first_name: "Itty", last_name: "Bitty", email: "ittybitty@gmail.com")
    new_student3 = User.create!(first_name: "Leo", last_name: "Pold", email: "leo@gmail.com")
    new_student4 = User.create!(first_name: "Leo", last_name: "Nardo", email: "nardo@gmail.com")
    CourseStudent.create!(student_id: new_student1.id, course_id: new_course.id)
    CourseStudent.create!(student_id: new_student2.id, course_id: new_course.id)
    CourseStudent.create!(student_id: new_student3.id, course_id: new_course.id)
    CourseStudent.create!(student_id: new_student4.id, course_id: new_course.id)
    assert new_course.students
    new_course.destroy
    new_student1.destroy
    new_student2.destroy
    new_student3.destroy
    new_student4.destroy
  end

  #------------------------------------------------------------
  # Adventure Player B Step 4 - Associate a Course with its ONE
  # primary_instructor. This primary instructor is the one who
  # is referenced by a course_instructor which has its primary flag set to true.
  #-------------------------------------------------------------
  def test_Course_has_primary_instructor_in_CourseInstructor

    new_course = Course.create!(name: "Course 1", course_code: "AAA000")
    new_instructor1 = User.create!(first_name: "Mr.", last_name: "Freeman", email: "freeman@gmail.com")
    new_instructor2 = User.create(first_name: "Mrs.", last_name: "Inman", email: "inman@gmail.com")
    new_instructor3 = User.create(first_name: "Mr.", last_name: "Loser", email: "loser@gmail.com")
    CourseInstructor.create!(course_id: new_course.id, instructor_id: new_instructor1.id)
    CourseInstructor.create(course_id: new_course.id, instructor_id: new_instructor2.id, primary: true)
    CourseInstructor.create(course_id: new_course.id, instructor_id: new_instructor3.id)
    assert new_course.primary_instructor == new_instructor2
    assert new_instructor1.taught_courses[0] == new_course
    new_course.destroy
    new_instructor1.destroy
    new_instructor2.destroy
   new_instructor3.destroy
  end

  #------------------------------------------------------------
  # Epic Player B Step 1 - A Course's students should be ordered
  # by last_name, then first_name.
  #-------------------------------------------------------------


  def test_sort_courses_students

    new_course = Course.find_or_create_by(course_code: 'AAA232') do |x|
       x.name = "Course Epic B1"
    end

    assert new_course.persisted?
    new_student1 = User.create(first_name: "Izzy", last_name: "Bella", email: "izzybella@gmail.com", photo_url: "https://newline.com")
    assert new_student1.persisted?
    new_student2 = User.create!(first_name: "Itty", last_name: "Bitty", email: "ittybitty@gmail.com", photo_url: "https://newline.com")
    new_student3 = User.create!(first_name: "Leo", last_name: "Pold", email: "leo@gmail.com", photo_url: "https://newline.com")
    new_student4 = User.create!(first_name: "Leo", last_name: "Nardo", email: "nardo@gmail.com", photo_url: "https://newline.com")
    new_course.students
    p new_course.students
    new_student1.destroy
    new_student2.destroy
    new_student3.destroy
    new_student4.destroy
  end


end # end ApplicationTest < Minitest::Test
