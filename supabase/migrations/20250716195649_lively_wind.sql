/*
  # Add foreign key relationship for assigned employee

  1. Changes
    - Add foreign key constraint between appointments.assigned_employee_id and users.id
    - This enables Supabase to join appointments with users for assigned employee data

  2. Security
    - No changes to existing RLS policies
    - Maintains current access controls
*/

-- Add the assigned_employee_id column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'appointments' AND column_name = 'assigned_employee_id'
  ) THEN
    ALTER TABLE appointments ADD COLUMN assigned_employee_id uuid;
  END IF;
END $$;

-- Add foreign key constraint to enable relationship queries
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'appointments_assigned_employee_id_fkey'
  ) THEN
    ALTER TABLE appointments 
    ADD CONSTRAINT appointments_assigned_employee_id_fkey 
    FOREIGN KEY (assigned_employee_id) REFERENCES users(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_appointments_assigned_employee 
ON appointments(assigned_employee_id);