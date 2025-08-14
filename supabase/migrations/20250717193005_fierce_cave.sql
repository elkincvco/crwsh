/*
  # Enable real-time updates for appointments table
  
  This migration enables real-time functionality for the appointments table
  so that public tracking views can receive automatic updates when appointment
  status changes without requiring page refresh.
*/

-- Enable real-time for appointments table
ALTER PUBLICATION supabase_realtime ADD TABLE appointments;

-- Ensure the appointments table has replica identity for real-time updates
ALTER TABLE appointments REPLICA IDENTITY FULL;