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

  def test_lesson
    new_lesson = Lesson.create(
           course_id: 101,
           name: "Psych 101",
           description: "Introduction to Psychology"
            )

    new_reading1 = Reading.create( lesson_id: new_lesson.id,
                    caption: "Freud Theory",
                    url: "http://www.iep.utm.edu/freud/" )

    assert  new_lesson.respond_to?("id?")
    refute  new_lesson.respond_to?("count")
  #----------------------------------
    assert new_lesson.reading.count > 0

    # if lesson doesn't have a "has_many :readings" you'll get an error on the assert
    # below - NoMethodError: undefined method `reading' for #<Lesson:0x007fa1fe3ae308>    assert Lesson.respond_to?("count")
  #----------------------------------
    assert new_reading1.lesson
    # if reading doesn't have a "belongs_to lesson" you receive NoMethodError:
    # undefined method `lesson' for #<Reading:0x007ff374c9f198>
  #----------------------------------

    Lesson.destroy(new_lesson.id)
    assert new_lesson.reading.count == 0
    # This will be false if lesson doesn't have   has_many :reading, dependent: :destroy
    #   1) Failure: ApplicationTest#test_lessonx - Expected false to be truthy.
  #----------------------------------

  end
end
