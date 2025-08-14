/*
  # Add last_login column to users table

  1. Changes
    - Add `last_login` column to `users` table
    - Column type: timestamptz (timestamp with timezone)
    - Nullable: true (users who haven't logged in yet will have null)
    - No default value initially

  2. Notes
    - This column will track when users last accessed the platform
    - Can be updated via application logic on successful authentication
    - Useful for analytics and user activity tracking
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'last_login'
  ) THEN
    ALTER TABLE users ADD COLUMN last_login timestamptz;
  END IF;
END $$;