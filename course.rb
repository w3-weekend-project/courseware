class Course < ActiveRecord::Base

  belongs_to :term
  has_many :schools, through: :term
  has_many :course_students, dependent: :restrict_with_error
  has_many :assignments, dependent: :destroy
  has_many :lessons, dependent: :destroy
  has_many :course_instructors, dependent: :restrict_with_error

  has_many :readings, through: :lessons
  has_many :students, through: :course_students, foreign_key: "student_id"
  has_many :instructors, through: :course_instructors, foreign_key: "instructor_id"
  has_one  :join_for_primary_instructor_course, -> {  where(primary: true) }, class_name: "CourseInstructor"
  has_one  :primary_instructor, through: :join_for_primary_instructor_course,
                                source: :instructor

  #has_many :sorted_students,  -> { order 'users.last_name, users.first_name' }
  #
  # -> { order 'users.last_name, users.first_name' }, through: :course_students, foreign_key: "student_id"


  validates :name, presence: true
  validates :course_code, presence: true, uniqueness: true, format: /\A[A-Za-z]{3}[0-9]{3}\z/



  default_scope { order("courses.term_id DESC, courses.course_code, courses.id DESC") }

  # Magic number also used in old? method below.
  scope :active, -> { includes(:term).where("terms.ends_on >= ?", Time.now - 1.month) }

  scope :for_school_id, ->(school_id) { includes(:term).where("terms.school_id = ?", school_id) }

  delegate :starts_on, to: :term, prefix: true
  delegate :ends_on, to: :term, prefix: true

#NAI insert def 1


#NAI end insert



  def self.example_courses
    self.where(public: true).order("id DESC").first(5)
  end

  # Magic number also used in :active scope above.
  def old?
    term.ends_on < Time.now - 1.month
  end

  def achievement_grading?
    grading_method == "Achievement"
  end

  def assignment_grading?
    grading_method == "Assignment"
  end

  def activity_grading?
    grading_method == "Activity"
  end

  def code_and_name
    "#{course_code}: #{name}"
  end

  def code_and_name_and_term
    "[#{term.name}] #{code_and_name}"
  end

  def instructor_names
    name_array = [primary_instructor_name]
    name_array += instructors.map{|i| i.full_name}
    name_array.uniq.join(', ')
  end

  def primary_instructor_name
    primary_instructor ? primary_instructor.full_name : nil
  end

  def assignment_statuses(user=nil)
    percents = {}
    assignments.each do |a|
      s = a.status(user).name
      percents[s] ||= 0
      percents[s] += a.percent_of_grade
    end

    statuses = AssignmentStatus.all_statuses_ordered(user && user.teaching?(self), user && user.enrolled?(self))
    statuses.each do |s|
      s.percent = percents[s.name] || 0
    end
  end

  def last_assignment
    assignments.where(["due_at <= ?", Time.now]).last
  end

  def next_assignment
    assignments.where(["due_at > ?", Time.now]).first
  end

  def root_lesson
    lessons.roots.first
  end

  def next_meeting
    meetings.where(['held_at > ?', Time.now]).first
  end

  def lesson_tree
    root_lesson.descendant_tree if root_lesson
  end

  def letter_for_grade(grade)
    threshold = grade_thresholds.where(["grade <= ?", grade]).first
    threshold ? threshold.letter : "N/A"
  end

  def meetings_after(meeting)
    meetings.where('held_at > ?', meeting.held_at)
  end

  def create_series_of_meetings(start_date, end_date, time_of_day, days_of_week)
    new_meetings = []
    Meeting.transaction do
      dates = (start_date..end_date).to_a.select {|k| days_of_week.include?(k.wday)}
      dates.each do |d|
        new_meetings << Meeting.create!(course_id: id,
          held_at: Time.zone.local(d.year, d.month, d.day,
            time_of_day.split(":")[0].to_i, time_of_day.split(":")[1].to_i)
          )
      end
    end
    new_meetings
  end

  def copy(instructor, term, include_objects)
    include_objects ||= Hash.new
    new_course = self.dup
    begin
      Course.transaction do
        new_course.term = term
        new_course.save!
        ["achievements", "policies", "grade_thresholds"].each do |a|
          if include_objects[a]
            new_course.send(a + "=", send(a).map {|i| i.dup})
          end
        end

        if include_objects["lessons"]
          lessons.roots.each {|l| l.copy_tree(new_course)}
        end

        if include_objects["assignments"]
          assignments.each {|a| a.copy_with_questions(new_course)}
        end

        CourseInstructor.create!(instructor: instructor, course: new_course, primary: true)
      end
    rescue
      return false
    end
    new_course
  end

  def open_time_cards
    time_cards = []
    course_students.each {|cs| time_cards += cs.time_cards.open}
    time_cards
  end
end
