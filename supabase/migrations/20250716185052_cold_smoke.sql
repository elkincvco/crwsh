/*
  # Fix RLS policies for public booking access

  This migration ensures that the booking system works without admin authentication
  by properly configuring RLS policies for anonymous users.

  ## Changes Made:
  1. Enable public read access to workspaces (active only)
  2. Enable public read access to workspace services (active only)  
  3. Enable public read access to workspace wash points (active only)
  4. Enable public read access to business hours
  5. Enable public read access to wash point services relationships
  6. Enable public insert access to appointments
  7. Enable public read access to appointments (for availability checking)
*/

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "Public can read active workspaces" ON workspaces;
DROP POLICY IF EXISTS "Public can read active services" ON workspace_services;
DROP POLICY IF EXISTS "Public can read active wash points" ON workspace_wash_points;
DROP POLICY IF EXISTS "Public can read business hours" ON workspace_business_hours;
DROP POLICY IF EXISTS "Public can read wash point services" ON wash_point_services;
DROP POLICY IF EXISTS "Public can create appointments" ON appointments;
DROP POLICY IF EXISTS "Public can read appointments for availability" ON appointments;

-- Workspaces: Allow public read access to active workspaces
CREATE POLICY "Public can read active workspaces"
  ON workspaces
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Workspace Services: Allow public read access to active services
CREATE POLICY "Public can read active services"
  ON workspace_services
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Workspace Wash Points: Allow public read access to active wash points
CREATE POLICY "Public can read active wash points"
  ON workspace_wash_points
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Business Hours: Allow public read access
CREATE POLICY "Public can read business hours"
  ON workspace_business_hours
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Wash Point Services: Allow public read access
CREATE POLICY "Public can read wash point services"
  ON wash_point_services
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Appointments: Allow public insert (create appointments)
CREATE POLICY "Public can create appointments"
  ON appointments
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Appointments: Allow public read (for availability checking)
CREATE POLICY "Public can read appointments for availability"
  ON appointments
  FOR SELECT
  TO anon, authenticated
  USING (true);