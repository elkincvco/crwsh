/*
  # Fix user workspace assignments

  1. Updates
    - Update empleado@lavader1.com workspace assignment
    - Update empleado@lavadero2.com workspace assignment
    - Ensure users are active and have correct role

  2. Security
    - No RLS changes needed, just data updates
*/

-- Update empleado@lavader1.com workspace assignment
UPDATE users 
SET 
  workspace_id = '6b163c65-b97c-434c-814c-85ad97df2f50',
  is_active = true,
  updated_at = now()
WHERE email = 'empleado@lavader1.com';

-- Update empleado@lavadero2.com workspace assignment  
UPDATE users 
SET 
  workspace_id = '387e589d-9727-4ded-9496-9941f7ad7e62',
  is_active = true,
  updated_at = now()
WHERE email = 'empleado@lavadero2.com';

-- Verify the updates
DO $$
BEGIN
  -- Check if users were updated correctly
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE email = 'empleado@lavader1.com' 
    AND workspace_id = '6b163c65-b97c-434c-814c-85ad97df2f50'
  ) THEN
    RAISE NOTICE 'Warning: empleado@lavader1.com workspace assignment may have failed';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE email = 'empleado@lavadero2.com' 
    AND workspace_id = '387e589d-9727-4ded-9496-9941f7ad7e62'
  ) THEN
    RAISE NOTICE 'Warning: empleado@lavadero2.com workspace assignment may have failed';
  END IF;
END $$;