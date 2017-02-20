class CourseInstructor < ActiveRecord::Base

    belongs_to :course
    belongs_to :instructor,   class_name:   "User",
                              foreign_key: "instructor_id"
#maybe ask Chris tomorrow I'm stuck on how to get the primary instructor...
#    where primary: true

end
