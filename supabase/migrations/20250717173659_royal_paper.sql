/*
  # Add RLS policy for employees to update their assigned appointments

  1. Security Changes
    - Add policy allowing employees to update status of appointments assigned to them
    - This enables the "Mark as In Progress" and "Mark as Completed" functionality
    - Policy ensures employees can only update appointments where they are the assigned employee

  2. Policy Details
    - Allows UPDATE operations on appointments table
    - Only for authenticated users
    - Only when the user's ID matches the assigned_employee_id
    - Allows updating status and updated_at fields for workflow progression
*/

-- Add policy for employees to update appointments assigned to them
CREATE POLICY "employees_can_update_assigned_appointments"
  ON appointments
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = assigned_employee_id)
  WITH CHECK (auth.uid() = assigned_employee_id);