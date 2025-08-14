/*
  # Employee notifications system

  1. New Tables
    - `employee_notifications`
      - `id` (uuid, primary key)
      - `employee_id` (uuid, foreign key to users)
      - `workspace_id` (uuid, foreign key to workspaces)
      - `type` (text, notification type)
      - `title` (text, notification title)
      - `message` (text, notification message)
      - `metadata` (jsonb, additional data)
      - `read` (boolean, read status)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `employee_notifications` table
    - Add policies for employees to read their own notifications

  3. Triggers
    - Create trigger for service assignment notifications
*/

-- Create employee_notifications table
CREATE TABLE IF NOT EXISTS employee_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('service_assigned')),
  title text NOT NULL,
  message text NOT NULL,
  metadata jsonb DEFAULT '{}',
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE employee_notifications ENABLE ROW LEVEL SECURITY;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_employee_notifications_employee_read 
  ON employee_notifications(employee_id, read) WHERE read = false;
CREATE INDEX IF NOT EXISTS idx_employee_notifications_created_at 
  ON employee_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_employee_notifications_workspace 
  ON employee_notifications(workspace_id);

-- RLS Policies
CREATE POLICY "Employees can read their own notifications"
  ON employee_notifications
  FOR SELECT
  TO authenticated
  USING (employee_id = auth.uid());

CREATE POLICY "Employees can update their own notifications"
  ON employee_notifications
  FOR UPDATE
  TO authenticated
  USING (employee_id = auth.uid())
  WITH CHECK (employee_id = auth.uid());

-- Function to create service assignment notification
CREATE OR REPLACE FUNCTION create_service_assignment_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create notification when assigned_employee_id changes from null to a value
  -- or when it changes from one employee to another
  IF (OLD.assigned_employee_id IS DISTINCT FROM NEW.assigned_employee_id) 
     AND NEW.assigned_employee_id IS NOT NULL THEN
    
    INSERT INTO employee_notifications (
      employee_id,
      workspace_id,
      type,
      title,
      message,
      metadata
    )
    SELECT 
      NEW.assigned_employee_id,
      NEW.workspace_id,
      'service_assigned',
      'Nuevo servicio asignado',
      'Se te ha asignado el servicio ' || ws.name || ' para ' || NEW.customer_name || ' el ' || 
      TO_CHAR(NEW.appointment_date, 'DD/MM/YYYY') || ' a las ' || 
      TO_CHAR(NEW.appointment_time, 'HH12:MI AM'),
      jsonb_build_object(
        'appointment_id', NEW.id,
        'customer_name', NEW.customer_name,
        'service_name', ws.name,
        'appointment_date', NEW.appointment_date,
        'appointment_time', NEW.appointment_time,
        'vehicle_plate', NEW.vehicle_plate,
        'wash_point_name', wp.name
      )
    FROM workspace_services ws, workspace_wash_points wp
    WHERE ws.id = NEW.service_id 
      AND wp.id = NEW.wash_point_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for service assignment notifications
DROP TRIGGER IF EXISTS trigger_service_assignment_notification ON appointments;
CREATE TRIGGER trigger_service_assignment_notification
  AFTER UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION create_service_assignment_notification();