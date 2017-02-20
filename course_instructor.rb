class CourseInstructor < ActiveRecord::Base
    belongs_to :course
    belongs_to :instructors,  class_name:   "User",
                              foreign_key: "instructor_id"
    belongs_to :primary_instructors,  class_name:   "User",
                                      foreign_key: "instructor_id"
#maybe ask Chris tomorrow I'm stuck on how to get the primary instructor...
#    where primary: true

end
