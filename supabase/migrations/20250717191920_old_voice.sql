/*
  # Add public appointment tracking policy

  1. Security
    - Add policy for public read access to appointments by ID
    - Allow anonymous users to read appointment details for tracking
*/

-- Allow public read access to appointments for tracking purposes
CREATE POLICY "Public can read appointments for tracking"
  ON appointments
  FOR SELECT
  TO anon, authenticated
  USING (true);