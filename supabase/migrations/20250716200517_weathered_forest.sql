/*
  # Add missing appointment statuses to enum

  1. Database Changes
    - Add 'request_received' status (initial status for new appointments)
    - Add 'assigned' status (when employee is assigned to appointment)
    - Add 'paid' status (when service has been paid for)

  2. Status Flow
    - pending → request_received → confirmed → assigned → in_progress → completed → paid
    - Any status can transition to cancelled

  3. Notes
    - Uses IF NOT EXISTS logic to prevent errors if values already exist
    - Maintains proper order in enum for logical status progression
*/

-- Add missing enum values to appointment_status
DO $$
BEGIN
    -- Add 'request_received' if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'request_received' 
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'appointment_status')
    ) THEN
        ALTER TYPE appointment_status ADD VALUE 'request_received' AFTER 'pending';
    END IF;

    -- Add 'assigned' if it doesn't exist  
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'assigned' 
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'appointment_status')
    ) THEN
        ALTER TYPE appointment_status ADD VALUE 'assigned' AFTER 'confirmed';
    END IF;

    -- Add 'paid' if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'paid' 
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'appointment_status')
    ) THEN
        ALTER TYPE appointment_status ADD VALUE 'paid' AFTER 'completed';
    END IF;
END $$;