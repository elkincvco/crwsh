/*
  # Create notifications system

  1. New Tables
    - `notifications`
      - `id` (uuid, primary key)
      - `workspace_id` (uuid, foreign key)
      - `user_id` (uuid, foreign key) 
      - `type` (text) - 'new_appointment' | 'service_completed'
      - `title` (text)
      - `message` (text)
      - `metadata` (jsonb) - additional data
      - `read` (boolean, default false)
      - `created_at` (timestamp)

  2. Functions
    - `create_appointment_notification()` - trigger function for new appointments
    - `create_completion_notification()` - trigger function for completed services

  3. Triggers
    - Trigger on appointments INSERT for new appointments
    - Trigger on appointments UPDATE for completed services

  4. Security
    - Enable RLS on notifications table
    - Add policies for workspace admins to read their notifications
    - Add policy for system to insert notifications
*/

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('new_appointment', 'service_completed')),
  title text NOT NULL,
  message text NOT NULL,
  metadata jsonb DEFAULT '{}',
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_workspace_user ON notifications(workspace_id, user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(workspace_id, user_id, read) WHERE read = false;

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy for workspace admins to read their notifications
CREATE POLICY "Workspace admins can read their notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() AND
    workspace_id IN (
      SELECT u.workspace_id
      FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() 
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  );

-- Policy for workspace admins to update their notifications (mark as read)
CREATE POLICY "Workspace admins can update their notifications"
  ON notifications
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid() AND
    workspace_id IN (
      SELECT u.workspace_id
      FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() 
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  )
  WITH CHECK (
    user_id = auth.uid() AND
    workspace_id IN (
      SELECT u.workspace_id
      FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() 
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  );

-- Policy for system to insert notifications
CREATE POLICY "System can insert notifications"
  ON notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Function to create notification for new appointments
CREATE OR REPLACE FUNCTION create_appointment_notification()
RETURNS TRIGGER AS $$
DECLARE
  admin_record RECORD;
  service_name text;
BEGIN
  -- Only create notification for new appointments
  IF NEW.status = 'request_received' THEN
    -- Get service name
    SELECT name INTO service_name
    FROM workspace_services
    WHERE id = NEW.service_id;

    -- Create notification for all workspace admins
    FOR admin_record IN
      SELECT u.id as user_id
      FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.workspace_id = NEW.workspace_id
      AND r.name IN ('workspace_admin', 'super_admin')
      AND u.is_active = true
    LOOP
      INSERT INTO notifications (
        workspace_id,
        user_id,
        type,
        title,
        message,
        metadata
      ) VALUES (
        NEW.workspace_id,
        admin_record.user_id,
        'new_appointment',
        'Nueva cita agendada',
        'Nueva cita agendada por ' || NEW.customer_name || ' para ' || COALESCE(service_name, 'servicio'),
        jsonb_build_object(
          'appointment_id', NEW.id,
          'customer_name', NEW.customer_name,
          'service_name', COALESCE(service_name, 'servicio'),
          'appointment_date', NEW.appointment_date,
          'appointment_time', NEW.appointment_time,
          'vehicle_plate', NEW.vehicle_plate
        )
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create notification for completed services
CREATE OR REPLACE FUNCTION create_completion_notification()
RETURNS TRIGGER AS $$
DECLARE
  admin_record RECORD;
  service_name text;
BEGIN
  -- Only create notification when status changes to completed
  IF OLD.status != 'completed' AND NEW.status = 'completed' THEN
    -- Get service name
    SELECT name INTO service_name
    FROM workspace_services
    WHERE id = NEW.service_id;

    -- Create notification for all workspace admins
    FOR admin_record IN
      SELECT u.id as user_id
      FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.workspace_id = NEW.workspace_id
      AND r.name IN ('workspace_admin', 'super_admin')
      AND u.is_active = true
    LOOP
      INSERT INTO notifications (
        workspace_id,
        user_id,
        type,
        title,
        message,
        metadata
      ) VALUES (
        NEW.workspace_id,
        admin_record.user_id,
        'service_completed',
        'Servicio completado',
        'Servicio ' || COALESCE(service_name, 'servicio') || ' completado para ' || NEW.customer_name,
        jsonb_build_object(
          'appointment_id', NEW.id,
          'customer_name', NEW.customer_name,
          'service_name', COALESCE(service_name, 'servicio'),
          'appointment_date', NEW.appointment_date,
          'appointment_time', NEW.appointment_time,
          'vehicle_plate', NEW.vehicle_plate
        )
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_new_appointment_notification ON appointments;
CREATE TRIGGER trigger_new_appointment_notification
  AFTER INSERT ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION create_appointment_notification();

DROP TRIGGER IF EXISTS trigger_completion_notification ON appointments;
CREATE TRIGGER trigger_completion_notification
  AFTER UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION create_completion_notification();

-- Enable realtime for notifications
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;