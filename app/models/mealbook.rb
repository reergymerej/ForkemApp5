class Mealbook < ApplicationRecord
  has_many :meals #on_delete :cascade
  has_many :mealbook_users
  has_many :users, through: :mealbook_users
  has_many :grocery_lists

  class << self
    def find_mealbook_for_meal_id(meal_id)
      joins(:meals).
        where(meals: { id: meal_id }).
        select("mealbooks.id, meals.id as meal_id").
        first
    end
  end

  def name=(name_value)
    write_attribute(:param, name_value.parameterize)
    write_attribute(:name, name_value)
  end

  def meal_assignments
    meal_assignments_query.to_a
  end

  def meal_assignments_for_day(assignment_date)
    meal_assignments_query.where(assigned_on: assignment_date).to_a
  end

  def meals_assigned_within_range(date_range)
    meals.joins(:meal_assignments).
      select("meals.*, meal_assignments.id AS assignment_id").
      select("meal_assignments.assigned_on, meal_assignments.position").
      where(meal_assignments: { assigned_on: date_range }).
      order("meal_assignments.assigned_on, meal_assignments.created_at").
      to_a
  end

  def meal_assignments_query(meal_assignment: MealAssignment)
    meal_assignment.joins(:meal).where(meals: { mealbook_id: self.id })
  end
end
