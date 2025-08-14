/*
  # Employee Appointments RLS Policy

  1. Security
    - Employees can update appointments to assign themselves
    - Only unassigned appointments can be taken
    - Employees can only assign appointments to themselves
    - Must be from the same workspace

  2. Changes
    - Add policy for employees to update appointments (take appointments)
    - Ensure employees can only take unassigned appointments from their workspace
*/

-- Allow employees to update appointments to assign themselves
CREATE POLICY "employees_can_take_unassigned_appointments" ON appointments
FOR UPDATE TO authenticated
USING (
  -- Must be unassigned appointment
  assigned_employee_id IS NULL
  AND
  -- Must be from employee's workspace
  workspace_id IN (
    SELECT users.workspace_id 
    FROM users 
    WHERE users.id = auth.uid()
  )
  AND
  -- Must be in valid status for taking
  status IN ('request_received', 'confirmed')
)
WITH CHECK (
  -- Can only assign to themselves
  assigned_employee_id = auth.uid()
  AND
  -- Must set status to assigned
  status = 'assigned'
  AND
  -- Must be from employee's workspace
  workspace_id IN (
    SELECT users.workspace_id 
    FROM users 
    WHERE users.id = auth.uid()
  )
);

-- Verify the policy was created
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'appointments' 
    AND policyname = 'employees_can_take_unassigned_appointments'
  ) THEN
    RAISE EXCEPTION 'Employee appointments policy was not created successfully';
  END IF;
  
  RAISE NOTICE 'Employee appointments RLS policy created successfully';
END $$;